----------
--ESTRAL--
----------

require "LD_Arcana"

-- III - The Empress. Durability.
-- stats from the design: Max Condition, Average Condition, Condition Lower Chance.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("EMPRESS", {
    area = "Durability",
    theme = "Preservation, growth, sustaining what you possess",
    stats = { "conditionMax", "averageCondition", "conditionLowerChance" },

    -- past    = { title = "", text = "", mods = { conditionMax = 1 } },
    -- present = { title = "", text = "", mods = { conditionMax = 2 } },
    -- future  = { title = "", text = "", mods = { conditionMax = 1 } },
})
