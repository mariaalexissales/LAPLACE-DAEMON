----------
--ESTRAL--
----------

require "LD_Arcana"

-- XVII - The Star. Reach / Precision.
-- stats from the design: Max Range, Crit Chance, Min Range.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("STAR", {
    area = "Reach / Precision",
    theme = "Hope, guidance, precision, renewal",
    stats = { "maxRange", "criticalChance", "minRange" },

    -- past    = { title = "", text = "", mods = { maxRange = 1 } },
    -- present = { title = "", text = "", mods = { maxRange = 2 } },
    -- future  = { title = "", text = "", mods = { maxRange = 1 } },
})
