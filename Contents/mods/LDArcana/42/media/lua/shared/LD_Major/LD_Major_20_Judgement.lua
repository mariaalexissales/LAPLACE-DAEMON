----------
--ESTRAL--
----------

require "LD_Arcana"

-- XX - Judgement. Precision / Power.
-- stats from the design: Crit Chance, Crit Multiplier, Max Damage.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("JUDGEMENT", {
    area = "Precision / Power",
    theme = "Reckoning, decisive action, culmination",
    stats = { "criticalChance", "critMultiplier", "maxDamage" },

    -- past    = { title = "", text = "", mods = { criticalChance = 1 } },
    -- present = { title = "", text = "", mods = { criticalChance = 2 } },
    -- future  = { title = "", text = "", mods = { criticalChance = 1 } },
})
