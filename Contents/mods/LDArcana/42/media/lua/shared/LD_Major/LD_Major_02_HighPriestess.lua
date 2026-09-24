----------
--ESTRAL--
----------

require "LD_Arcana"

-- II - The High Priestess. Precision.
-- stats from the design: Crit Chance, Crit Multiplier, Min Range.
-- no effects yet.

LDArcana.define("HIGH_PRIESTESS", {
    area = "Precision",
    theme = "Patience, intuition, knowing when to strike",
    stats = { "criticalChance", "critMultiplier", "minRange" },

    -- past    = { title = "", text = "", mods = { criticalChance = 1 } },
    -- present = { title = "", text = "", mods = { criticalChance = 2 } },
    -- future  = { title = "", text = "", mods = { criticalChance = 1 } },
})
