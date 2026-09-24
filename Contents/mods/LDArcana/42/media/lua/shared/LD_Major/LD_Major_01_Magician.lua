----------
--ESTRAL--
----------

require "LD_Arcana"

-- I - The Magician. Precision.
-- stats from the design: Crit Chance, Crit Multiplier, Attack Speed.
-- no effects yet.

LDArcana.define("MAGICIAN", {
    area = "Precision",
    theme = "Skill, control, deliberate technique",
    stats = { "criticalChance", "critMultiplier", "baseSpeed" },

    -- past    = { title = "", text = "", mods = { criticalChance = 1 } },
    -- present = { title = "", text = "", mods = { criticalChance = 2 } },
    -- future  = { title = "", text = "", mods = { criticalChance = 1 } },
})
