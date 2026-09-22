----------
--ESTRAL--
----------

require "LD_Arcana"

-- XVIII - The Moon. Reach / Precision.
-- stats from the design: Min Range, Max Range, Crit Chance.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("MOON", {
    area = "Reach / Precision",
    theme = "Uncertainty, instinct, deception",
    stats = { "minRange", "maxRange", "criticalChance" },

    -- past    = { title = "", text = "", mods = { minRange = 1 } },
    -- present = { title = "", text = "", mods = { minRange = 2 } },
    -- future  = { title = "", text = "", mods = { minRange = 1 } },
})
