# OVSwrap Lua-LSM 临时缓解策略

[English](README.md)

[`ovswrap_cap_net_admin_guard.lua`](ovswrap_cap_net_admin_guard.lua) 用于阻断
OVSwrap（CVE-2026-64531）公开 PoC 使用的非特权 user namespace 攻击路径。

## 原理

PoC 通过 `unshare -Urn` 在子 user namespace 中取得 `CAP_NET_ADMIN`，再发送
OVS Generic Netlink 请求触发漏洞。该策略拒绝非初始 user namespace credential
的 `CAP_NET_ADMIN` 检查，使请求在进入 OVS 漏洞代码前返回 `EPERM`。

## 加载

要求内核启用 Lua-LSM，并且加载者具有 `CAP_MAC_ADMIN`：

```sh
cat lua-lsm-mitigation/ovswrap_cap_net_admin_guard.lua \
  > /sys/kernel/security/lua/register
cat /sys/kernel/security/lua/modules
```

卸载：

```sh
echo ovswrap_cap_net_admin_guard \
  > /sys/kernel/security/lua/unregister
```

## 验证

加载策略后，以非特权用户执行：

```sh
unshare -Urn ip link set lo up
```

命令应以 `Operation not permitted` 失败。该测试不会运行具有破坏性的 PoC。

## 限制

- 策略会阻止子 user namespace 中的所有 `CAP_NET_ADMIN` 操作，可能影响
  Rootless Docker、Podman 及容器内网络配置。
- 未启用 user namespace 隔离且拥有 `CAP_NET_ADMIN` 的 root 容器不受阻止。
- 已拥有初始 user namespace `CAP_NET_ADMIN` 的宿主进程仍可访问漏洞路径。
- 这是临时入口缓解措施，并未修复 OVS 漏洞；应优先更新到包含上游修复的内核。
