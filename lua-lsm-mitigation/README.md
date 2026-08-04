# OVSwrap Lua-LSM temporary mitigation

[简体中文](README.zh-CN.md)

[`ovswrap_cap_net_admin_guard.lua`](ovswrap_cap_net_admin_guard.lua) blocks the
unprivileged user-namespace attack path used by the public OVSwrap
(CVE-2026-64531) PoC.

## How it works

The PoC uses `unshare -Urn` to obtain `CAP_NET_ADMIN` in a child user namespace,
then sends OVS Generic Netlink requests. The policy denies `CAP_NET_ADMIN` to
credentials outside the initial user namespace, returning `EPERM` before the
request reaches the vulnerable OVS code.

## Load

Lua-LSM must be enabled, and the loader needs `CAP_MAC_ADMIN`:

```sh
cat lua-lsm-mitigation/ovswrap_cap_net_admin_guard.lua \
  > /sys/kernel/security/lua/register
cat /sys/kernel/security/lua/modules
```

Unload:

```sh
echo ovswrap_cap_net_admin_guard \
  > /sys/kernel/security/lua/unregister
```

## Verify

After loading the policy, run as an unprivileged user:

```sh
unshare -Urn ip link set lo up
```

The command should fail with `Operation not permitted`. This test does not run
the destructive PoC.

## Limitations

- The policy blocks every `CAP_NET_ADMIN` operation in child user namespaces,
  which may affect rootless containers and container network configuration.
- A root container without user-namespace isolation is not blocked if it has
  `CAP_NET_ADMIN`.
- Host processes with initial-userns `CAP_NET_ADMIN` can still reach the
  vulnerable path.
- This is an entry-point mitigation, not an OVS bug fix. Prefer a kernel with
  the upstream fix.
