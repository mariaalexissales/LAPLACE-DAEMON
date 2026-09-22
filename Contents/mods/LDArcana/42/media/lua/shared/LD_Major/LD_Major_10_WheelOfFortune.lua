----------
--ESTRAL--
----------

require "LD_Arcana"

-- X - Wheel of Fortune. Precision.
-- stats from the design: Crit Chance, Crit Multiplier.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("WHEEL_OF_FORTUNE", {
    area = "Precision",
    theme = "Chance, fate, unpredictable outcomes",
    stats = { "criticalChance", "critMultiplier" },

    -- past    = { title = "", text = "", mods = { criticalChance = 1 } },
    -- present = { title = "", text = "", mods = { criticalChance = 2 } },
    -- future  = { title = "", text = "", mods = { criticalChance = 1 } },
})
