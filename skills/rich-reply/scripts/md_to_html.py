#!/usr/bin/env python3
"""Render markdown to a fully STATIC, self-contained HTML file and print its path.

No JavaScript, no CDN, no network requests — the markdown is converted to real
HTML tags here in Python, so it renders in any viewer (Telegram in-app browser,
a downloaded file opened offline, email previews, etc.). Modern styling, small
text, dark-mode aware.

Usage:
  md_to_html.py [--title "…"] [FILE]      # FILE, or stdin if omitted
  echo "# hi" | md_to_html.py --title "Answer"

Output: $RICH_REPLY_CACHE_DIR/<ts>-<rand>.html (the single tailnet-served dir),
falling back to $HERMES_HOME/cache/html/<ts>-<rand>.html when that is unset.

Supported markdown: headings, bold, italic, inline code, links, ordered/unordered
lists, fenced code blocks, pipe tables, blockquotes, horizontal rules. ```mermaid
fences render as a labelled source block (diagram images need a renderer, which
would mean JS or an external API — deliberately avoided here).
"""
from __future__ import annotations

import argparse
import datetime as _dt
import html
import os
import re
import secrets
import sys
from pathlib import Path

# ── inline markdown ────────────────────────────────────────────────────────────

def _inline(text: str) -> str:
    codes: list[str] = []

    def _grab(m: re.Match) -> str:
        codes.append(m.group(1))
        return f"\x00{len(codes) - 1}\x00"

    # protect inline code first (its content stays literal)
    tmp = re.sub(r"`([^`]+)`", _grab, text)
    tmp = html.escape(tmp, quote=False)
    # links [text](url)
    tmp = re.sub(
        r"\[([^\]]+)\]\(([^)\s]+)\)",
        lambda m: f'<a href="{html.escape(m.group(2), quote=True)}">{m.group(1)}</a>',
        tmp,
    )
    # bold, then italic (underscores left alone so snake_case survives)
    tmp = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", tmp)
    tmp = re.sub(r"(?<!\*)\*(?!\*)([^*]+?)\*(?!\*)", r"<em>\1</em>", tmp)
    # restore code spans
    tmp = re.sub(
        r"\x00(\d+)\x00",
        lambda m: f"<code>{html.escape(codes[int(m.group(1))], quote=False)}</code>",
        tmp,
    )
    return tmp


def _split_row(line: str) -> list[str]:
    return [c.strip() for c in line.strip().strip("|").split("|")]


# ── block markdown ─────────────────────────────────────────────────────────────

def render(md: str) -> str:
    lines = md.replace("\r\n", "\n").split("\n")
    out: list[str] = []
    para: list[str] = []
    i, n = 0, len(lines)

    def flush() -> None:
        if para:
            out.append("<p>" + _inline(" ".join(para).strip()) + "</p>")
            para.clear()

    while i < n:
        line = lines[i]

        m = re.match(r"^```(\w*)\s*$", line)
        if m:
            flush()
            lang, i = m.group(1), i + 1
            code = []
            while i < n and not re.match(r"^```\s*$", lines[i]):
                code.append(lines[i]); i += 1
            i += 1
            body = html.escape("\n".join(code))
            if lang == "mermaid":
                out.append(f'<figure class="diagram"><figcaption>diagram · mermaid</figcaption><pre>{body}</pre></figure>')
            else:
                out.append(f"<pre><code>{body}</code></pre>")
            continue

        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if m:
            flush(); lvl = len(m.group(1))
            out.append(f"<h{lvl}>{_inline(m.group(2).strip())}</h{lvl}>"); i += 1; continue

        if re.match(r"^(-{3,}|\*{3,}|_{3,})\s*$", line):
            flush(); out.append("<hr>"); i += 1; continue

        if "|" in line and i + 1 < n and "-" in lines[i + 1] and re.match(r"^\s*\|?[\s:|-]*-[\s:|-]*$", lines[i + 1]):
            flush()
            header = _split_row(line); i += 2
            t = ["<table><thead><tr>"] + [f"<th>{_inline(c)}</th>" for c in header] + ["</tr></thead><tbody>"]
            while i < n and "|" in lines[i] and lines[i].strip():
                t.append("<tr>" + "".join(f"<td>{_inline(c)}</td>" for c in _split_row(lines[i])) + "</tr>"); i += 1
            t.append("</tbody></table>"); out.append("".join(t)); continue

        if re.match(r"^>\s?", line):
            flush(); q = []
            while i < n and re.match(r"^>\s?", lines[i]):
                q.append(re.sub(r"^>\s?", "", lines[i])); i += 1
            out.append("<blockquote>" + _inline(" ".join(q).strip()) + "</blockquote>"); continue

        if re.match(r"^\s*[-*+]\s+", line) or re.match(r"^\s*\d+\.\s+", line):
            flush()
            ordered = bool(re.match(r"^\s*\d+\.\s+", line))
            tag = "ol" if ordered else "ul"
            items = []
            while i < n and (re.match(r"^\s*[-*+]\s+", lines[i]) or re.match(r"^\s*\d+\.\s+", lines[i])):
                items.append("<li>" + _inline(re.sub(r"^\s*(?:[-*+]|\d+\.)\s+", "", lines[i])) + "</li>"); i += 1
            out.append(f"<{tag}>" + "".join(items) + f"</{tag}>"); continue

        if not line.strip():
            flush(); i += 1; continue

        para.append(line); i += 1

    flush()
    return "\n".join(out)


# ── page ────────────────────────────────────────────────────────────────────────

STYLE = """
  :root{ --bg:#fff; --fg:#1f2328; --muted:#656d76; --accent:#6366f1;
    --border:rgba(0,0,0,.10); --code-bg:#f5f6f8; }
  @media (prefers-color-scheme: dark){
    :root{ --bg:#0d1117; --fg:#e6edf3; --muted:#8b949e; --accent:#818cf8;
      --border:rgba(255,255,255,.12); --code-bg:#161b22; } }
  *{ box-sizing:border-box } html{ color-scheme:light dark }
  body{ margin:0; background:var(--bg); color:var(--fg); -webkit-font-smoothing:antialiased;
    font:13.5px/1.65 system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif; }
  main{ max-width:720px; margin:0 auto; padding:2rem 1.15rem 4rem; }
  h1,h2,h3,h4{ line-height:1.25; letter-spacing:-.01em; font-weight:650; margin:1.6em 0 .5em; }
  h1{ font-size:1.5rem; margin-top:0; } h2{ font-size:1.16rem; padding-bottom:.3rem; border-bottom:1px solid var(--border); }
  h3{ font-size:1.02rem; } p,li{ font-size:13.5px; }
  a{ color:var(--accent); text-decoration:none } a:hover{ text-decoration:underline }
  code{ font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace; font-size:.86em;
    background:var(--code-bg); padding:.12em .38em; border-radius:5px; }
  pre{ background:var(--code-bg); border:1px solid var(--border); border-radius:10px;
    padding:.9rem 1rem; overflow-x:auto; font-size:12.5px; line-height:1.5; }
  pre code{ background:none; padding:0 }
  figure.diagram{ margin:1.2rem 0; }
  figure.diagram figcaption{ font-size:11px; text-transform:uppercase; letter-spacing:.06em; color:var(--muted); margin-bottom:.35rem; }
  figure.diagram pre{ border-style:dashed; }
  blockquote{ margin:1rem 0; padding:.3rem 0 .3rem 1rem; border-left:3px solid var(--accent); color:var(--muted) }
  table{ border-collapse:collapse; width:100%; font-size:12.8px; margin:1rem 0 }
  th,td{ border:1px solid var(--border); padding:.42rem .6rem; text-align:left }
  th{ background:var(--code-bg); font-weight:600 }
  tr:nth-child(even) td{ background:color-mix(in srgb,var(--code-bg) 45%, transparent) }
  hr{ border:none; border-top:1px solid var(--border); margin:1.8rem 0 }
  ::selection{ background:color-mix(in srgb,var(--accent) 30%, transparent) }
"""

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>{style}</style>
</head>
<body><main>{body}</main></body>
</html>
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("file", nargs="?", help="markdown file; stdin if omitted")
    ap.add_argument("--title", default="Hermes response")
    args = ap.parse_args()

    md = Path(args.file).read_text(encoding="utf-8") if args.file else sys.stdin.read()
    title = html.escape((args.title or "Hermes response"))
    page = PAGE.format(title=title, style=STYLE, body=render(md))

    # The served cache dir is a single fixed location tied to RICH_REPLY_URL_BASE
    # (one static server, one directory). Profiles override HERMES_HOME to their
    # own home, so honor RICH_REPLY_CACHE_DIR when set — otherwise a profile's
    # page lands in <profile>/cache/html/, which the tailnet server never serves
    # (the URL 404s). Fall back to HERMES_HOME only when the override is unset.
    cache_dir = os.environ.get("RICH_REPLY_CACHE_DIR")
    out_dir = Path(cache_dir) if cache_dir else (
        Path(os.environ.get("HERMES_HOME", Path.home() / "hermes")) / "cache" / "html"
    )
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = _dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    fname = f"{stamp}-{secrets.token_hex(3)}.html"
    out = out_dir / fname
    out.write_text(page, encoding="utf-8")

    # If a served base URL is configured (Tailscale serve), print the link the
    # agent should send. Otherwise fall back to the local file path.
    base = os.environ.get("RICH_REPLY_URL_BASE", "").rstrip("/")
    print(f"{base}/{fname}" if base else str(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
