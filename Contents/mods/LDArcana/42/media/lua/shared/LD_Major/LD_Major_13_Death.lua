----------
--ESTRAL--
----------

require "LD_Arcana"

-- XIII - Death. Power / Precision.
-- stats from the design: Max Damage, Crit Chance, Crit Multiplier.
-- the design's plain "Condition" is read as max condition.

LDArcana.define("DEATH", {
    area = "Power / Precision",
    theme = "Endings, transformation, execution",
    stats = { "maxDamage", "criticalChance", "critMultiplier" },

    past = {
        title = "What has already been destroyed",
        mods = { maxDamage = 1, conditionMax = 1, criticalChance = 1 },
    },

    present = {
        title = "The killing blow",
        mods = { criticalChance = 2, critMultiplier = 1, maxDamage = 1 },
    },

    future = {
        title = "What is about to end",
        mods = { critMultiplier = 2, maxDamage = 1, knockback = 1 },
    },
})
