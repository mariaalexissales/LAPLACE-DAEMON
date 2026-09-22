----------
--ESTRAL--
----------

require "LD_Arcana"

-- IV - The Emperor. Power.
-- stats from the design: Min Damage, Max Damage, Knockback.

LDArcana.define("EMPEROR", {
    area = "Power",
    theme = "Authority, force, dominance",
    stats = { "minDamage", "maxDamage", "knockback" },

    past = {
        title = "Accumulated power",
        text = "The weapon has become powerful through what came before.",
        mods = { minDamage = 1, maxDamage = 1, conditionMax = 1 },
    },

    present = {
        title = "Force",
        text = "You're putting everything into the strike right now.",
        mods = { maxDamage = 2, knockback = 1, baseSpeed = -1 },
    },

    future = {
        title = "Impending dominance",
        text = "The coming attack is the important one.",
        mods = { maxDamage = 1, knockback = 1, critMultiplier = 1 },
    },
})
