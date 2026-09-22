----------
--ESTRAL--
----------

require "LD_Arcana"

-- VIII - Strength. Power.
-- stats from the design: Max Damage, Knockback, Min Damage.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("STRENGTH", {
    area = "Power",
    theme = "Physical strength, restraint, controlled force",
    stats = { "maxDamage", "knockback", "minDamage" },

    -- past    = { title = "", text = "", mods = { maxDamage = 1 } },
    -- present = { title = "", text = "", mods = { maxDamage = 2 } },
    -- future  = { title = "", text = "", mods = { maxDamage = 1 } },
})
