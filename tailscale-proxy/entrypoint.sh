#!/bin/sh
# Optional wrapper around the stock tailscale entrypoint (containerboot).
#
# TS_BRIDGE_PORTS — comma-separated TCP ports, e.g. "80" or "80,443".
#
# For each port, installs a DNAT rule forwarding traffic that arrives on the
# container's docker-bridge interface to the same port on this node's tailnet
# address.
#
# Why this is needed: `tailscale serve` binds the tailnet address ONLY. A host
# that reaches this container by its bridge IP — typically via an /etc/hosts
# entry, because the host is joined to a *different* tailnet and so can't
# resolve this node's MagicDNS name — otherwise finds a closed port. The rule
# does not survive a container restart on its own, which is why it lives here
# rather than being applied by hand.
#
# Unset (the default) makes this script a no-op passthrough: the container
# behaves exactly like the stock image.
set -e

if [ -n "${TS_BRIDGE_PORTS:-}" ]; then
    (
        # containerboot brings tailscaled up in parallel; the rule can't name an
        # address that doesn't exist yet, so wait for one.
        ip=""
        i=0
        while [ "$i" -lt 60 ]; do
            ip="$(tailscale ip -4 2>/dev/null || true)"
            [ -n "$ip" ] && break
            i=$((i + 1))
            sleep 1
        done

        if [ -z "$ip" ]; then
            echo "bridge-forward: no tailnet IPv4 after 60s — no rules installed" >&2
            exit 0
        fi

        iface="$(ip route show default 2>/dev/null | awk '{print $5; exit}')"
        [ -n "$iface" ] || iface="eth0"

        echo "$TS_BRIDGE_PORTS" | tr ',' '\n' | while read -r port; do
            port="$(echo "$port" | tr -d ' ')"
            [ -n "$port" ] || continue
            # -C tests for an identical existing rule, so re-running is idempotent.
            if iptables -t nat -C PREROUTING -i "$iface" -p tcp --dport "$port" \
                -j DNAT --to-destination "$ip:$port" 2>/dev/null; then
                echo "bridge-forward: $iface:$port -> $ip:$port (already present)" >&2
            else
                iptables -t nat -A PREROUTING -i "$iface" -p tcp --dport "$port" \
                    -j DNAT --to-destination "$ip:$port"
                echo "bridge-forward: $iface:$port -> $ip:$port" >&2
            fi
        done
    ) &
fi

exec /usr/local/bin/containerboot "$@"
