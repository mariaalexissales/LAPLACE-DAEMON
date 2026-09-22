----------
--ESTRAL--
----------

require "LD_Arcana"

-- IX - The Hermit. Tempo / Durability.
-- stats from the design: Encumbrance, Attack Speed, Average Condition.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("HERMIT", {
    area = "Tempo / Durability",
    theme = "Patience, conservation, deliberate action",
    stats = { "weight", "baseSpeed", "averageCondition" },

    -- past    = { title = "", text = "", mods = { weight = 1 } },
    -- present = { title = "", text = "", mods = { weight = 2 } },
    -- future  = { title = "", text = "", mods = { weight = 1 } },
})
