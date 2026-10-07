----------
--ESTRAL--
----------

require "LD_Arcana"

-- XIV - Temperance. Tempo / Durability. goes on a weapon or on armor.
-- stats from the design: Attack Speed, Encumbrance, Condition Lower Chance.
-- the efficient, sustainable weapon: light, quick, and slow to wear out. the design's
-- "condition efficiency" and "condition loss down" are both the condition lower chance roll,
-- and its plain "Condition" is read as max condition.
-- on armor it is the piece you forget you're wearing: lighter every way round. the design's
-- armor "Movement Speed" and "Attack Speed" are the two speed modifiers.

LDArcana.define("TEMPERANCE", {
    area = "Tempo / Durability",
    theme = "Balance, moderation, efficiency",
    stats = { "baseSpeed", "weight", "conditionLowerChance" },

    past = {
        title = "Tempered by the forge",
        mods = { conditionMax = 1, weight = -1 },
        armorMods = { weight = -1, insulation = 1 },
    },

    present = {
        title = "Economy of motion",
        mods = { baseSpeed = 1, weight = -1, conditionLowerChance = 1 },
        armorMods = { weight = -1, runSpeedModifier = 1, combatSpeedModifier = 1 },
    },

    future = {
        title = "Built to outlast",
        mods = { conditionLowerChance = 1, weight = -1, averageCondition = 1 },
        armorMods = { weight = -1, biteDefense = 1, scratchDefense = 1 },
    },
})
