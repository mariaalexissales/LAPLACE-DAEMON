----------
--ESTRAL--
----------

require "LD_Arcana"

-- VII - The Chariot. Tempo / Power.
-- stats from the design: Attack Speed, Max Range, Knockback.

LDArcana.define("CHARIOT", {
    area = "Tempo / Power",
    theme = "Momentum, determination, forward motion",
    stats = { "baseSpeed", "maxRange", "knockback" },

    past = {
        title = "Momentum already established",
        mods = { baseSpeed = 1, maxRange = 1 },
    },

    present = {
        title = "Charging forward",
        mods = { baseSpeed = 2, maxRange = 1, knockback = 1 },
    },

    -- condition lower chance is the "1 in N" roll, so up means the weapon holds together
    -- for longer.
    future = {
        title = "Continued momentum",
        mods = { baseSpeed = 1, conditionLowerChance = 1, maxRange = 1 },
    },
})
