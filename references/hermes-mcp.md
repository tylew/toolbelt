# Hermes as an MCP server (`hermes mcp serve`)

Hermes ships a built-in MCP server that exposes your messaging conversations
**and** the Kanban board over the Model Context Protocol, so any MCP client
(Claude Code, Claude Desktop, Cursor, Codex…) can drive Hermes. Nothing to
build — it's the `hermes mcp serve` subcommand. These are the steps to stand it
up against your own Hermes install.

## What it exposes

Stdio MCP server, 14 tools:

- **Conversations / messages** — `conversations_list`, `conversation_get`,
  `messages_read`, `attachments_fetch`
- **Live events** — `events_poll`, `events_wait` (long-poll)
- **Sending** — `messages_send`, `channels_list`
- **Approvals** — `permissions_list_open`, `permissions_respond`
- **Kanban (agent-to-agent handoff)** — `kanban_dispatch`, `kanban_list`,
  `kanban_show`, `kanban_comment`

`messages_send` delivers to a human on a channel; `kanban_dispatch` queues a
task the dispatcher spawns another Hermes agent (an assignee profile) to
execute. That's the difference between "message a person" and "hand work to an
agent."

The server reads/writes the **local** Hermes data on whatever machine it runs
on (`~/.hermes/…` — session DB + `kanban.db`). Point a client at your own
`hermes mcp serve` and it operates on your own Hermes, not anyone else's.

## Prerequisites

- Hermes installed with `hermes` on your `PATH` (`hermes version` works).
- The MCP SDK present in Hermes' venv (bundled by default). If `serve` errors
  with a missing `mcp` package, install it into Hermes' environment.

## 1. Smoke-test the server

Run it in the foreground with verbose logging to confirm it starts and lists
tools. It speaks MCP over stdio, so it'll sit waiting for a client — Ctrl-C to
exit.

```bash
hermes mcp serve -v
```

## 2. Wire it into a client

It's a stdio server: command `hermes`, args `["mcp", "serve"]`.

**Claude Code (CLI):**

```bash
claude mcp add hermes -- hermes mcp serve
```

**Claude Desktop / Cursor / generic** (`claude_desktop_config.json` or the
client's `mcpServers` block):

```json
{
  "mcpServers": {
    "hermes": {
      "command": "hermes",
      "args": ["mcp", "serve"]
    }
  }
}
```

Add `"-v"` to `args` for verbose stderr logging while debugging. If `hermes`
isn't on the client's `PATH` (GUI apps often have a minimal `PATH`), use the
absolute path — `which hermes` — as `command`.

## 3. Verify

Restart / reconnect the client and confirm the 14 `hermes` tools appear. Quick
end-to-end check of the kanban path:

- `kanban_dispatch` with a `title` + `assignee` (a real profile name) → returns
  a `task_id`.
- `kanban_list` → the new task shows up.
- Clean up with `hermes kanban archive <task_id>` if it was just a test.

## Notes

- **Kanban dispatch needs a live dispatcher.** Creating a card is enough to
  queue it, but it only runs when Hermes' dispatcher is up (the gateway-embedded
  dispatcher, or `hermes kanban daemon`). `assignee` must be an installed
  profile.
- **`-v` logs go to stderr**, so they won't corrupt the stdio MCP stream on
  stdout.
- **`--accept-hooks`** auto-approves unseen shell hooks without a TTY prompt —
  handy when the server runs headless under a client.
- Sharing with someone who runs their own Hermes = send them this note. The
  server is part of Hermes; they run `hermes mcp serve` and it binds to *their*
  data. No code to copy.
