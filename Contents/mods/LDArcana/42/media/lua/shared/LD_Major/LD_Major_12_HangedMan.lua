----------
--ESTRAL--
----------

require "LD_Arcana"

-- XII - The Hanged Man. Tempo / Power.
-- stats from the design: Encumbrance, Attack Speed, Max Damage.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("HANGED_MAN", {
    area = "Tempo / Power",
    theme = "Sacrifice, surrender, changing perspective",
    stats = { "weight", "baseSpeed", "maxDamage" },

    -- past    = { title = "", text = "", mods = { weight = 1 } },
    -- present = { title = "", text = "", mods = { weight = 2 } },
    -- future  = { title = "", text = "", mods = { weight = 1 } },
})
