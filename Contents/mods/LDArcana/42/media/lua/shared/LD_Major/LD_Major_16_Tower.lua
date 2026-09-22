----------
--ESTRAL--
----------

require "LD_Arcana"

-- XVI - The Tower. Power.
-- stats from the design: Max Damage, Knockback, Crit Multiplier.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("TOWER", {
    area = "Power",
    theme = "Destruction, collapse, sudden upheaval",
    stats = { "maxDamage", "knockback", "critMultiplier" },

    -- past    = { title = "", text = "", mods = { maxDamage = 1 } },
    -- present = { title = "", text = "", mods = { maxDamage = 2 } },
    -- future  = { title = "", text = "", mods = { maxDamage = 1 } },
})
