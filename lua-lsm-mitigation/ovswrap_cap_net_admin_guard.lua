-- SPDX-License-Identifier: GPL-2.0

local capability = require("capability")
local errno = require("errno")
local CAP_NET_ADMIN = capability.CAP_NET_ADMIN

local function credential_is_in_initial_userns(cred)
    return cred:userns():is_initial()
end

local function capable(cred, target_userns, cap, opts)
    if cap ~= CAP_NET_ADMIN then
        return true
    end

    -- OVS administrative Generic Netlink commands require CAP_NET_ADMIN in
    -- the user namespace that owns the target network namespace.  The public
    -- PoC obtains that capability in a private user+network namespace.  Deny
    -- that delegated capability while preserving host administrators' ability
    -- to manage both the initial and descendant namespaces.
    --
    -- Use the credential passed by the hook rather than current:cred().
    -- Netlink may check both the socket opener's saved credential and the
    -- sender's current credential.
    local ok, is_initial = pcall(credential_is_in_initial_userns, cred)
    if not ok or is_initial ~= true then
        return false, errno.EPERM
    end

    return true
end

return {
    name = "ovswrap_cap_net_admin_guard",
    author = "OVSwrap contributors",
    description = "Deny CAP_NET_ADMIN to credentials outside the initial user namespace",
    license = "GPL-2.0",
    version = 1,
    capable = capable,
}
