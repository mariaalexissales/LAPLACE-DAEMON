----------
--ESTRAL--
----------

require "LD_Arcana"

-- XXI - The World. Mastery.
-- stats from the design: Min Damage, Max Damage, Crit Chance, Attack Speed, Max Range, Max Condition.
-- the design asks for all five areas at once: damage, precision, tempo, reach and
-- durability. a little of each reads better here than a lot of any one.
-- no effects yet.

LDArcana.define("WORLD", {
    area = "Mastery",
    theme = "Completion, mastery, integration",
    stats = { "minDamage", "maxDamage", "criticalChance", "baseSpeed", "maxRange", "conditionMax" },

    -- past    = { title = "", text = "", mods = { minDamage = 1 } },
    -- present = { title = "", text = "", mods = { minDamage = 2 } },
    -- future  = { title = "", text = "", mods = { minDamage = 1 } },
})
