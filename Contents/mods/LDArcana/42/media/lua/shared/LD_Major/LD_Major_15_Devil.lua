----------
--ESTRAL--
----------

require "LD_Arcana"

-- XV - The Devil. Power / Tempo.
-- stats from the design: Max Damage, Attack Speed, Crit Multiplier.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("DEVIL", {
    area = "Power / Tempo",
    theme = "Excess, temptation, aggression",
    stats = { "maxDamage", "baseSpeed", "critMultiplier" },

    -- past    = { title = "", text = "", mods = { maxDamage = 1 } },
    -- present = { title = "", text = "", mods = { maxDamage = 2 } },
    -- future  = { title = "", text = "", mods = { maxDamage = 1 } },
})
