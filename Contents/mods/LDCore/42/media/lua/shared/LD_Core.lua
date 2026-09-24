----------
--ESTRAL--
----------

LDCore = LDCore or {}

LDCore.MOD_ID = "LDCore"

-- the module string on every packet between the two sides.
LDCore.MODULE = "LD"

-- everything the mod keeps on an item lives under this one modData key.
LDCore.DATA_KEY = "LD"
LDCore.DATA_VERSION = 1

-- server/ lua loads on multiplayer clients too, and isServer() is false in singleplayer.
function LDCore.isAuthority()
    return not (isClient() and not isServer())
end

function LDCore.hasRemoteServer()
    return isClient() and not isServer()
end

-- the engine ships both spellings -- Role.class has Admin/GM/Moderator, Roles.class has
-- lowercase, and vanilla compares the lowercase one. normalising stops a case-sensitive test
-- being a coin flip.
function LDCore.accessLevel(player)
    if not player then return "none" end

    local level = player:getAccessLevel()
    if not level or level == "" then return "none" end

    return string.lower(level)
end

-- the question is "is there no multiplayer at all", which is both flags off. asking for a
-- remote server instead is false in the server process too, so on a dedicated server that
-- hands admin to everybody.
function LDCore.isAdmin(player)
    if not isClient() and not isServer() then return true end
    if not player then return false end

    local level = LDCore.accessLevel(player)
    return level == "admin" or level == "gm" or level == "moderator"
end

function LDCore.log(message)
    print("[LD] " .. tostring(message))
end

function LDCore.warn(message)
    print("[LD] WARN: " .. tostring(message))
end

-- only for the fallback string. the game stores a loaded translation with java's %1$s
-- placeholders, so both spellings are filled here.
local function LD_fill(text, ...)
    local args = { ... }

    for i = 1, select("#", ...) do
        local arg = tostring(args[i]):gsub("%%", "%%%%")
        text = text:gsub("%%" .. i .. "%$s", arg)
        text = text:gsub("%%" .. i, arg)
    end

    return text
end

-- getText does the substitution itself, and hands back the key when there is no such key.
-- pcall because a translation whose placeholder count does not match the arguments throws
-- out of java rather than returning anything.
function LDCore.text(key, fallback, ...)
    local ok, value = pcall(getText, key, ...)
    if ok and value and value ~= "" and value ~= key then return value end

    return LD_fill(fallback or key, ...)
end

-- ---------------------------------------------------------------------------------------
-- hooks. core fires these with a ctx table; listeners change the ctx fields they're allowed
-- to and core reads them back. core never knows who is listening, which is how LDArcana
-- plugs in without core depending on it.
-- ---------------------------------------------------------------------------------------

LDCore.HOOK = {
    -- player, level, recipe, item, weights (change)
    FORGE_WEIGHTS = "forge.weights",
    -- player, level, recipe, item, data (change rarity and pct together)
    FORGE_ROLLED  = "forge.rolled",
    -- item, data, base (read only copy), stats (change)
    ITEM_STATS    = "item.stats",
    -- player, item, data, loading (true when re-run for what's already held on load)
    WEAPON_EQUIP  = "weapon.equip",
    -- attacker, target, item, data, damage (read only, the hit already landed)
    WEAPON_HIT    = "weapon.hit",
}

LDCore.Hooks = LDCore.Hooks or {}
LDCore.Hooks.listeners = LDCore.Hooks.listeners or {}

function LDCore.Hooks.add(name, fn)
    local list = LDCore.Hooks.listeners[name]
    if not list then
        list = {}
        LDCore.Hooks.listeners[name] = list
    end
    list[#list + 1] = fn
end

-- listeners run in the order they were added. one that throws is logged and skipped so it
-- can't take the craft or the swing down with it.
function LDCore.Hooks.run(name, ctx)
    local list = LDCore.Hooks.listeners[name]
    if not list then return ctx end

    for i = 1, #list do
        local ok, err = pcall(list[i], ctx)
        if not ok then LDCore.warn("hook " .. name .. " listener " .. i .. " failed: " .. tostring(err)) end
    end

    return ctx
end
