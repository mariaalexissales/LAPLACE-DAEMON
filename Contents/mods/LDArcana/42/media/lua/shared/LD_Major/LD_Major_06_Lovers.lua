----------
--ESTRAL--
----------

require "LD_Arcana"

-- VI - The Lovers. Tempo / Precision.
-- stats from the design: Attack Speed, Crit Chance, Encumbrance.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("LOVERS", {
    area = "Tempo / Precision",
    theme = "Harmony, synchronization, connection",
    stats = { "baseSpeed", "criticalChance", "weight" },

    -- past    = { title = "", text = "", mods = { baseSpeed = 1 } },
    -- present = { title = "", text = "", mods = { baseSpeed = 2 } },
    -- future  = { title = "", text = "", mods = { baseSpeed = 1 } },
})
