----------
--ESTRAL--
----------

require "LD_Arcana"

-- V - The Hierophant. Durability.
-- stats from the design: Max Condition, Condition Lower Chance.
-- the design also lists Head Condition. there's no setter for a head's maximum, and no
-- blade has a head, so it isn't a stat this mod can move.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("HIEROPHANT", {
    area = "Durability",
    theme = "Discipline, tradition, maintenance",
    stats = { "conditionMax", "conditionLowerChance" },

    -- past    = { title = "", text = "", mods = { conditionMax = 1 } },
    -- present = { title = "", text = "", mods = { conditionMax = 2 } },
    -- future  = { title = "", text = "", mods = { conditionMax = 1 } },
})
