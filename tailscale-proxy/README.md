# tailscale-proxy

Runs a Tailscale node in Docker that forwards all incoming traffic to the host machine. Lets you register a named Tailscale node without replacing the host's own Tailscale daemon.

## Usage

1. Copy `.env.example` to `.env` and fill in `TS_AUTHKEY` and `TS_HOSTNAME`.
2. `docker compose up -d`

The node will appear on your Tailscale network under the configured hostname. SSH traffic is forwarded to the host's sshd.

## Reaching another tailnet over SSH (SOCKS5 proxy)

This Mac is joined to one tailnet, while the container joins a *different* one (via
`TS_AUTHKEY`). A host can only route through one tailnet at a time, so the container
acts as a bridge: it's the member of the "other" tailnet and exposes a SOCKS5 + HTTP
CONNECT proxy on `127.0.0.1:1055` (see `TS_TAILSCALED_EXTRA_ARGS` in
`docker-compose.yml`). Your Mac stays on its own tailnet and tunnels select
connections through the container.

To route SSH to the other tailnet's devices through the proxy, add to `~/.ssh/config`:

```sshconfig
# Any Tailscale CGNAT address (100.x) goes through the container's SOCKS5 proxy.
Host 100.*
    ProxyCommand nc -X 5 -x 127.0.0.1:1055 %h %p
    ServerAliveInterval 60
    ServerAliveCountMax 10

# Optional: a named shortcut for a specific device on the other tailnet.
Host claw
    HostName 100.107.105.99
    User claw
    ProxyCommand nc -X 5 -x 127.0.0.1:1055 %h %p
    ControlMaster auto
    ControlPath ~/.ssh/cm_%r@%h:%p
    ControlPersist 10m
```

- `nc -X 5 -x 127.0.0.1:1055` dials the target through the SOCKS5 (`-X 5`) proxy.
- **Requires the container to be up** — if it's down, every `100.*` SSH fails with a
  connection-refused on port 1055.
- **Only covers SSH.** For HTTP/other traffic, point the app at the same proxy on
  `127.0.0.1:1055` (SOCKS5 or HTTP CONNECT).
- The `Host 100.*` wildcard is broad: it tunnels *every* `100.x` SSH through the
  container. If you also have devices on your Mac's own tailnet in that range that you
  want to reach directly, scope this to explicit IPs instead of the wildcard.
