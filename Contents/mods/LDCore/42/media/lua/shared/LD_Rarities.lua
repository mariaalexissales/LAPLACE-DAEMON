----------
--ESTRAL--
----------

require "LD_Core"

-- lowest to highest. rolls and menus walk this list, so nothing depends on pairs() order.
LDCore.RARITY_ORDER = { "COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY" }

-- pct is the damage roll: a percent of the vanilla weapon's MinDamage and MaxDamage, both
-- ends inclusive. placeholder numbers.
LDCore.Rarities = {
    COMMON = {
        id = "COMMON",
        name = "Common",
        tier = 1,
        color = { 200, 200, 200 },
        pct = { 90, 110 },
    },
    UNCOMMON = {
        id = "UNCOMMON",
        name = "Uncommon",
        tier = 2,
        color = { 90, 200, 90 },
        pct = { 110, 125 },
    },
    RARE = {
        id = "RARE",
        name = "Rare",
        tier = 3,
        color = { 80, 140, 240 },
        pct = { 125, 145 },
    },
    EPIC = {
        id = "EPIC",
        name = "Epic",
        tier = 4,
        color = { 170, 90, 220 },
        pct = { 145, 170 },
    },
    LEGENDARY = {
        id = "LEGENDARY",
        name = "Legendary",
        tier = 5,
        color = { 240, 160, 40 },
        pct = { 170, 200 },
    },
}

-- blacksmith level -> weight per rarity. a missing rarity weighs 0, and a row doesn't have to
-- add up to 100. placeholder curve; check it with LDItem.simulate(level, 1000).
LDCore.RarityWeights = {
    [0]  = { COMMON = 95, UNCOMMON = 5 },
    [1]  = { COMMON = 90, UNCOMMON = 10 },
    [2]  = { COMMON = 80, UNCOMMON = 18, RARE = 2 },
    [3]  = { COMMON = 70, UNCOMMON = 25, RARE = 5 },
    [4]  = { COMMON = 60, UNCOMMON = 30, RARE = 9, EPIC = 1 },
    [5]  = { COMMON = 50, UNCOMMON = 32, RARE = 15, EPIC = 3 },
    [6]  = { COMMON = 40, UNCOMMON = 33, RARE = 20, EPIC = 6, LEGENDARY = 1 },
    [7]  = { COMMON = 30, UNCOMMON = 32, RARE = 26, EPIC = 10, LEGENDARY = 2 },
    [8]  = { COMMON = 22, UNCOMMON = 30, RARE = 30, EPIC = 14, LEGENDARY = 4 },
    [9]  = { COMMON = 15, UNCOMMON = 27, RARE = 33, EPIC = 19, LEGENDARY = 6 },
    [10] = { COMMON = 10, UNCOMMON = 22, RARE = 35, EPIC = 24, LEGENDARY = 9 },
}

function LDCore.rarity(id)
    return id and LDCore.Rarities[id] or nil
end

function LDCore.rarityName(id)
    local rarity = LDCore.rarity(id)
    return LDCore.text("IGUI_LD_Rarity_" .. tostring(id), rarity and rarity.name or tostring(id))
end
