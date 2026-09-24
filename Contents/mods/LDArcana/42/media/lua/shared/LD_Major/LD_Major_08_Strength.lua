----------
--ESTRAL--
----------

require "LD_Arcana"

-- VIII - Strength. Power.
-- stats from the design: Max Damage, Knockback, Min Damage.
-- no effects yet.

LDArcana.define("STRENGTH", {
    area = "Power",
    theme = "Physical strength, restraint, controlled force",
    stats = { "maxDamage", "knockback", "minDamage" },

    -- past    = { title = "", text = "", mods = { maxDamage = 1 } },
    -- present = { title = "", text = "", mods = { maxDamage = 2 } },
    -- future  = { title = "", text = "", mods = { maxDamage = 1 } },
})
