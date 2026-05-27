# tailscale-proxy

Runs a Tailscale node in Docker that forwards all incoming traffic to the host machine. Lets you register a named Tailscale node (e.g. `voltus-computer`) without replacing the host's own Tailscale daemon.

## Usage

1. Copy `.env.example` to `.env` and set your `TS_AUTHKEY` from the Tailscale admin console.
2. `docker compose up -d`

The node will appear on your Tailscale network under the configured hostname. SSH traffic is forwarded to the host's sshd.
