# tailscale-proxy

Runs a Tailscale node in Docker that forwards all incoming traffic to the host machine. Lets you register a named Tailscale node without replacing the host's own Tailscale daemon.

## Config

Two variables drive `docker-compose.yml`:

- **`TS_AUTHKEY`** *(secret)* — a Tailscale auth key. Store it in the Keychain once so it's exported into every shell (see the `managing-secrets` skill):

  ```sh
  store-secret TS_AUTHKEY "tskey-auth-..."
  ```

- **`TS_HOSTNAME`** — the node's name on your tailnet (not secret, optional). Defaults to `TYLER WAS HERE` (Tailscale sanitizes it to `tyler-was-here`); override it inline at run time.

## Run

```sh
docker compose up -d                          # uses the default hostname
TS_HOSTNAME=my-machine docker compose up -d   # or set your own
```

`docker compose` reads `TS_AUTHKEY` from the environment (exported from the Keychain), so there's no `.env` file to manage. The node then appears on your tailnet under `TS_HOSTNAME`; SSH traffic is forwarded to the host's sshd.

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

## Serving host services on a path (`TS_SERVE_CONFIG`)

Instead of forwarding *everything* to one host (`TS_DEST_IP`), the node can reverse-proxy
individual paths to different host ports. Point `TS_SERVE_CONFIG` at a file under `./serve`
(mounted read-only at `/config`):

```sh
TS_SERVE_CONFIG=/config/explorer.json
```

`serve/explorer.json` is a worked example — `/x` and `/r` both to `host.docker.internal:8770`.
Write the node's own name as the `${TS_CERT_DOMAIN}` placeholder, which the image substitutes at
startup, so the file stays portable between machines.

**Use this rather than running `tailscale serve` by hand.** A hand-run config can be dropped when
the container restarts, silently reducing the routes to a bare `/` proxy; a file-backed config is
re-applied on every start.

> **`TS_DEST_IP` and `TS_SERVE_CONFIG` are mutually exclusive.** `TS_DEST_IP` installs a blanket
> DNAT on the node's tailnet address, which swallows traffic before `serve` ever sees it. Set one
> or the other, never both. Both are unset by default.

## Reaching the node from the Docker host (`TS_BRIDGE_PORTS`)

`tailscale serve` binds the node's **tailnet address only**. That is fine for other tailnet
devices, but the Docker host itself is often on a *different* tailnet and reaches the container by
its docker-bridge IP — typically via an `/etc/hosts` line:

```
192.168.155.2  my-node.tailXXXX.ts.net
```

Nothing listens on that address, so the request fails with a **connection error, not a 404**. Set
`TS_BRIDGE_PORTS` to forward the port from the bridge interface to the tailnet address:

```sh
TS_BRIDGE_PORTS=80        # or "80,443"
```

`entrypoint.sh` installs one idempotent DNAT rule per port once tailscaled has an address, and logs
each one (`docker logs tailscale | grep bridge-forward`). Leave it unset and the wrapper is a no-op
passthrough — the container behaves exactly like the stock image.

Diagnosing: a connection error means the bridge rule is missing; a `404` means the request reached
the node but no serve route matched.
