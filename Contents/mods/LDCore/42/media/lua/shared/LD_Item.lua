----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Rarities"

LDItem = LDItem or {}

local function LD_copyTable(source)
    local out = {}
    for key, value in pairs(source) do
        out[key] = type(value) == "table" and LD_copyTable(value) or value
    end
    return out
end

LDItem.copyTable = LD_copyTable

-- hasModData first so looking at a vanilla item doesn't hand it an empty table.
function LDItem.get(item)
    if not item or not item:hasModData() then return nil end
    return item:getModData()[LDCore.DATA_KEY]
end

function LDItem.set(item, data)
    item:getModData()[LDCore.DATA_KEY] = data
end

function LDItem.newData(rarityId, pct, level)
    return { v = LDCore.DATA_VERSION, rarity = rarityId, pct = pct, level = level }
end

-- deep copy, so the blade and the sword it became never share a table.
function LDItem.copy(from, to)
    local data = LDItem.get(from)
    if not data then return false end

    LDItem.set(to, LD_copyTable(data))
    return true
end

-- the mod's scope for now is blades, sorted the way the game sorts them. the meat cleaver
-- and the hand scythe are axes to the game, so they stay vanilla.
local LD_warnedCategory = false

function LDItem.isBladed(weapon)
    local ok, bladed = pcall(function()
        return weapon:isOfWeaponCategory(WeaponCategory.LONG_BLADE)
            or weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLADE)
    end)

    -- said once, loudly, because every blade quietly staying vanilla is hard to spot.
    if not ok then
        if not LD_warnedCategory then
            LD_warnedCategory = true
            LDCore.warn("can't read weapon categories, nothing will roll: " .. tostring(bladed))
        end
        return false
    end

    return bladed == true
end

-- the thing a recipe was actually for: a bladed weapon, or a blade that isn't on a handle
-- yet. skips the leftover bar from mapper outputs, the handle that comes off in a
-- dismantle, and any weapon that isn't a blade.
function LDItem.isRollable(item)
    if not item then return false end
    if instanceof(item, "HandWeapon") then return LDItem.isBladed(item) end
    return item:isSharpenable()
end

-- a copy, so hooks can change it freely. a level with no row uses the nearest row below.
function LDItem.weightsFor(level)
    local rows = LDCore.RarityWeights
    level = math.max(0, math.floor(level or 0))

    while level > 0 and not rows[level] do level = level - 1 end

    return LD_copyTable(rows[level] or { COMMON = 1 })
end

-- float roll, so a hook that scales a weight by 1.5 still works.
function LDItem.rollRarity(weights)
    local total = 0
    for _, id in ipairs(LDCore.RARITY_ORDER) do
        total = total + math.max(0, weights[id] or 0)
    end

    if total <= 0 then return LDCore.RARITY_ORDER[1] end

    local roll = ZombRandFloat(0, total)
    for _, id in ipairs(LDCore.RARITY_ORDER) do
        local weight = math.max(0, weights[id] or 0)
        if roll < weight then return id end
        roll = roll - weight
    end

    -- only reachable when the float lands exactly on total.
    for i = #LDCore.RARITY_ORDER, 1, -1 do
        local id = LDCore.RARITY_ORDER[i]
        if (weights[id] or 0) > 0 then return id end
    end
    return LDCore.RARITY_ORDER[1]
end

function LDItem.rollPct(rarityId)
    local rarity = LDCore.rarity(rarityId)
    if not rarity then return 100 end

    local low, high = rarity.pct[1], rarity.pct[2]
    return low + ZombRand(high - low + 1)
end

function LDItem.simulate(level, n)
    n = n or 1000
    local weights = LDItem.weightsFor(level)
    local counts = {}

    for _ = 1, n do
        local id = LDItem.rollRarity(weights)
        counts[id] = (counts[id] or 0) + 1
    end

    for _, id in ipairs(LDCore.RARITY_ORDER) do
        local count = counts[id] or 0
        LDCore.log("level " .. tostring(level) .. " " .. id .. ": " .. count
            .. " (" .. (math.floor(count * 1000 / n + 0.5) / 10) .. "%)")
    end

    return counts
end

-- stats. always rebuilt from the vanilla base, never from the item's current numbers, so
-- refresh can run on every equip and load without stacking.

-- a card coming out can lower the ceiling under the condition the weapon already has.
local function LD_writeConditionMax(item, value)
    item:setConditionMax(value)
    if item:getCondition() > value then item:setCondition(value) end
end

-- setCustomWeight, or the game reads the script weight back over this one.
local function LD_writeWeight(item, value)
    item:setActualWeight(value)
    item:setCustomWeight(true)
end

-- head condition is deliberately absent: there's no setter for its maximum, and no blade has
-- a head to begin with.
LDItem.STATS = {
    minDamage            = { get = "getMinDamage", set = "setMinDamage", scales = true, min = 0 },
    maxDamage            = { get = "getMaxDamage", set = "setMaxDamage", scales = true, min = 0 },
    criticalChance       = { get = "getCriticalChance", set = "setCriticalChance", min = 0, max = 100 },
    critMultiplier       = { get = "getCriticalDamageMultiplier", set = "setCriticalDamageMultiplier", min = 1 },
    baseSpeed            = { get = "getBaseSpeed", set = "setBaseSpeed", min = 0.1 },
    minRange             = { get = "getMinRange", set = "setMinRange", min = 0 },
    maxRange             = { get = "getMaxRange", set = "setMaxRange", min = 0.2 },
    knockback            = { get = "getPushBackMod", set = "setPushBackMod", min = 0 },
    conditionMax         = { get = "getConditionMax", write = LD_writeConditionMax, int = true, min = 1 },
    conditionLowerChance = { get = "getConditionLowerChance", set = "setConditionLowerChance", int = true, min = 1 },
    weight               = { get = "getActualWeight", write = LD_writeWeight, min = 0.01 },
    doorDamage           = { get = "getDoorDamage", set = "setDoorDamage", int = true, min = 0 },
    treeDamage           = { get = "getTreeDamage", set = "setTreeDamage", int = true, min = 0 },
}

-- reading order for the spread window and the debug inspect.
LDItem.STAT_ORDER = {
    "minDamage", "maxDamage", "criticalChance", "critMultiplier", "baseSpeed",
    "minRange", "maxRange", "knockback", "conditionMax", "conditionLowerChance",
    "weight", "doorDamage", "treeDamage",
}

-- stats a weapon is better off with less of. UI colouring reads this; nothing else does.
LDItem.LOWER_IS_BETTER = {
    weight = true,
    minRange = true,
}

function LDCore.statName(stat)
    return LDCore.text("IGUI_LD_Stat_" .. tostring(stat), tostring(stat))
end

-- how long a weapon lasts on average: every condition point takes about
-- conditionLowerChance hits to lose. derived, so nothing writes it.
function LDItem.averageCondition(stats)
    if not stats or not stats.conditionMax or not stats.conditionLowerChance then return nil end
    return stats.conditionMax * stats.conditionLowerChance
end

-- two decimals at most, and no trailing zeroes: 3 rather than 3.00, 3.6 rather than 3.60.
function LDItem.formatNumber(value)
    if type(value) ~= "number" then return tostring(value) end

    local rounded = math.floor(value * 100 + 0.5) / 100
    if rounded == math.floor(rounded) then return tostring(math.floor(rounded)) end

    local text = string.format("%.2f", rounded)
    if text:sub(-1) == "0" then text = text:sub(1, -2) end
    return text
end

-- the script Item only exposes min and max damage, so a fresh instance is read once per type.
local LD_baseCache = {}

function LDItem.baseStats(fullType)
    local cached = LD_baseCache[fullType]
    if cached then return cached end

    local ok, weapon = pcall(instanceItem, fullType)
    if not ok or not weapon or not instanceof(weapon, "HandWeapon") then return nil end

    cached = {}
    for stat, def in pairs(LDItem.STATS) do
        cached[stat] = weapon[def.get](weapon)
    end

    LD_baseCache[fullType] = cached
    return cached
end

-- rounds, clamps, and keeps the pairs the right way round. previews run this too, so what a
-- tooltip promises is what the setters write.
function LDItem.clampStats(stats)
    for stat, def in pairs(LDItem.STATS) do
        local value = stats[stat]
        if type(value) ~= "number" then
            stats[stat] = nil
        else
            if def.min and value < def.min then value = def.min end
            if def.max and value > def.max then value = def.max end
            if def.int then value = math.floor(value + 0.5) end
            stats[stat] = value
        end
    end

    if stats.minDamage and stats.maxDamage and stats.minDamage > stats.maxDamage then
        stats.minDamage = stats.maxDamage
    end
    if stats.minRange and stats.maxRange and stats.minRange >= stats.maxRange then
        stats.minRange = math.max(0, stats.maxRange - 0.05)
    end

    return stats
end

-- works out the numbers without touching the item. pass data to ask what the weapon would
-- look like with a different spread, which is how the socket menu previews a card.
-- returns stats, base, rolled: vanilla, and vanilla after the rarity roll but before cards.
function LDItem.computeStats(item, data)
    if not instanceof(item, "HandWeapon") then return nil end

    data = data or LDItem.get(item)
    if not data then return nil end

    local base = LDItem.baseStats(item:getFullType())
    if not base then return nil end

    local mult = (data.pct or 100) / 100
    local stats = {}
    for stat, def in pairs(LDItem.STATS) do
        stats[stat] = def.scales and base[stat] * mult or base[stat]
    end

    local rolled = LD_copyTable(stats)

    LDCore.Hooks.run(LDCore.HOOK.ITEM_STATS, {
        item = item,
        data = data,
        base = LD_copyTable(base),
        rolled = rolled,
        stats = stats,
    })

    return LDItem.clampStats(stats), base, rolled
end

function LDItem.applyStats(item)
    local stats = LDItem.computeStats(item)
    if not stats then return nil end

    for stat, def in pairs(LDItem.STATS) do
        local value = stats[stat]
        if type(value) == "number" then
            if def.write then
                def.write(item, value)
            else
                item[def.set](item, value)
            end
        end
    end

    return stats
end

-- "Sword Blade - Rare". the game adds "(Blunt)" itself. rebuilt from the script name every
-- time, so it can never become "Sword Blade - Rare - Rare".
function LDItem.applyName(item)
    local data = LDItem.get(item)
    if not data or not data.rarity then return end

    local script = item:getScriptItem()
    local baseName = script and script:getDisplayName() or item:getDisplayName()

    item:setName(LDCore.text("IGUI_LD_ItemName", "%1 - %2", baseName, LDCore.rarityName(data.rarity)))
    item:setCustomName(true)
end

function LDItem.refresh(item)
    if not LDItem.get(item) then return end

    LDItem.applyName(item)
    LDItem.applyStats(item)
end

-- conditionMax and customWeight are in no packet the game sends, so those numbers cannot
-- travel. what travels is the LD table, and every machine rebuilds its own stats off it.
function LDItem.sync(player, item)
    if not isServer() or not item then return end

    if player then syncItemModData(player, item) end
    item:syncItemFields()

    if player and instanceof(item, "HandWeapon") then syncHandWeaponFields(player, item) end
end

-- the one place that says an item's LD data moved. socketing writes into the table in place
-- rather than through LDItem.set, so it has to come back through here or it never leaves the
-- machine that did it.
function LDItem.changed(item, player)
    LDItem.refresh(item)
    LDItem.sync(player, item)
end

function LDItem.stamp(item, data)
    LDItem.set(item, data)
    LDItem.refresh(item)
end

function LDItem.describe(value, indent, out)
    indent = indent or ""
    out = out or {}

    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

    for _, key in ipairs(keys) do
        local entry = value[key]
        if type(entry) == "table" then
            out[#out + 1] = indent .. tostring(key) .. ":"
            LDItem.describe(entry, indent .. "  ", out)
        else
            out[#out + 1] = indent .. tostring(key) .. " = " .. tostring(entry)
        end
    end

    return out
end
