----------
--ESTRAL--
----------

require "LD_Arcana"

-- XIX - The Sun. Power / Tempo.
-- stats from the design: Min Damage, Max Damage, Attack Speed.
-- no effects yet. see LD_Major_00_Fool.lua for the format, then uncomment the slots.

LDArcana.define("SUN", {
    area = "Power / Tempo",
    theme = "Vitality, confidence, strength",
    stats = { "minDamage", "maxDamage", "baseSpeed" },

    -- past    = { title = "", text = "", mods = { minDamage = 1 } },
    -- present = { title = "", text = "", mods = { minDamage = 2 } },
    -- future  = { title = "", text = "", mods = { minDamage = 1 } },
})
