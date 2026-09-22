----------
--ESTRAL--
----------

require "LD_Arcana"

-- XIV - Temperance. Tempo / Durability.
-- stats from the design: Attack Speed, Encumbrance, Condition Lower Chance.
-- the efficient, sustainable weapon: light, quick, and slow to wear out. the design's
-- "condition efficiency" and "condition loss down" are both the condition lower chance roll,
-- and its plain "Condition" is read as max condition.

LDArcana.define("TEMPERANCE", {
    area = "Tempo / Durability",
    theme = "Balance, moderation, efficiency",
    stats = { "baseSpeed", "weight", "conditionLowerChance" },

    past = {
        mods = { conditionMax = 1, weight = -1 },
    },

    present = {
        mods = { baseSpeed = 1, weight = -1, conditionLowerChance = 1 },
    },

    future = {
        mods = { conditionLowerChance = 1, weight = -1, averageCondition = 1 },
    },
})
