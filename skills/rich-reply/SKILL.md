---
name: rich-reply
description: >-
  Deliver a substantive reply as a short chat message PLUS a link to a styled HTML page (markdown,
  modern/dark-aware, small text) served over Tailscale. USE on a messaging channel (Telegram, etc.)
  whenever a reply would run long — more than ~15 lines / a couple of paragraphs — or when a diagram,
  table, chart, or sizable code block would aid comprehension. Do NOT use for short/trivial replies
  (acknowledgements, one-liners, quick yes/no) — those stay plain text.
---

# rich-reply

Two-part delivery for substantive messaging replies: a brief body in the chat, and a **link** to the
full response as a styled HTML page (served from this Mac over the tailnet, opened in a real browser).

## When to use
- The reply is **longer than ~15 lines** / more than a couple of short paragraphs, **or**
- a **diagram / table / chart / code block** would make it clearer (mermaid encouraged).

Skip it for short or trivial replies — send those as plain text. In the CLI/TUI, reply normally
(no link); this is for messaging channels.

**Linking vs rendering.** rich-reply renders a *fresh* page from markdown you write now. If the thing
you want to show the user is **already a file under `docs/`** (a vault note, spec/plan, hermes design),
don't re-render it — link into the **`besstie-explorer`** doc view instead (live, backlinked,
auto-reloading). See the besstie-explorer skill's `references/links.md` for the canonical doc / graph /
navigator / artifact URL scheme. Both surfaces share the same tailnet host.

## How to deliver
1. **Write the full answer as markdown** — headings, lists, tables, code, and ` ```mermaid ` fenced
   diagrams where a picture helps. Save it to a temp file (or pipe via stdin).
2. **Render + get the link:**
   ```bash
   python3 ~/.claude/skills/rich-reply/scripts/md_to_html.py --title "Overview of the day" /tmp/reply.md
   # prints: <RICH_REPLY_URL_BASE>/r/<ts>-<rand>.html   (URL base is operator-configured; see md_to_html.py)
   ```
   (Markdown can also be piped: `... | md_to_html.py --title "…"`.) The script writes the page to the
   served cache and prints the tailnet URL (`$RICH_REPLY_URL_BASE/<file>`); it falls back to a local
   file path only if that env var is unset.
3. **Reply with a brief body + the link** — 1–3 line summary, then the printed URL as a normal
   markdown link. No attachment:
   ```
   Here's your day at a glance — 3 meetings, 2 PRs need review, steward is unblocked.
   [Full overview](http://voltus-computer-1.taila95bd5.ts.net/r/20260810-142430-c46f38.html)
   ```

## Notes
- The page is **served over the tailnet** (tailnet-only, WireGuard-encrypted) via the `tailscale` Docker
  container, which proxies `/r` → the host's static server (`127.0.0.1:8765`, launchd
  `com.hermes.rich-reply-server`, reached from the container as `host.docker.internal`). The host's own
  Tailscale is logged out, so serving goes through the container. Opened in a real browser, so it renders
  fully. Requires the Mac up, the container running, and the device on the tailnet.
- The HTML itself is static markdown→tags (dark-aware, small text). Mermaid renders as a labelled
  source block in this script. For native mermaid diagram rendering, use the `artifact-publisher`
  skill's `md_to_html_mermaid.py` instead — same interface, same CSS, adds CDN mermaid.js.
- The **brief body** is the headline + any ask/next step — 1 to 3 lines. Don't restate the whole
  answer; that's what the link is for.
