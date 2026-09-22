----------
--ESTRAL--
----------

require "LD_Arcana"

-- XI - Justice. Balance.
-- stats from the design: Min Damage, Max Damage, Crit Chance.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("JUSTICE", {
    area = "Balance",
    theme = "Balance, consistency, proportionality",
    stats = { "minDamage", "maxDamage", "criticalChance" },

    -- past    = { title = "", text = "", mods = { minDamage = 1 } },
    -- present = { title = "", text = "", mods = { minDamage = 2 } },
    -- future  = { title = "", text = "", mods = { minDamage = 1 } },
})
