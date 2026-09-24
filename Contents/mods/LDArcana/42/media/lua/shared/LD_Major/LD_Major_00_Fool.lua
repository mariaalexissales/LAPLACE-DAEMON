----------
--ESTRAL--
----------

require "LD_Arcana"

-- 0 - The Fool. Tempo / Reach.
-- stats from the design: Encumbrance, Attack Speed, Max Range.
-- no effects yet. writing a card is documented in design.md.

LDArcana.define("FOOL", {
    area = "Tempo / Reach",
    theme = "Improvisation, freedom, taking risks",
    stats = { "weight", "baseSpeed", "maxRange" },

    -- past    = { title = "", text = "", mods = { weight = -1 } },
    -- present = { title = "", text = "", mods = { baseSpeed = 2, maxRange = -1 } },
    -- future  = { title = "", text = "", mods = { maxRange = 1 } },
})
