----------
--ESTRAL--
----------

require "LD_Arcana"

-- III - The Empress. Protection. an armor card: it has no reading for a weapon.
-- stats from the design: Insulation, Bite Defense, Scratch Defense, Bullet Defense.

LDArcana.define("EMPRESS", {
    area = "Protection",
    theme = "Preservation, growth, sustaining what you possess",
    stats = { "insulation", "biteDefense", "scratchDefense", "bulletDefense" },

    past = {
        title = "Nurture",
        armorMods = { insulation = 1, scratchDefense = 1 },
    },

    present = {
        title = "Protection",
        armorMods = { biteDefense = 1, scratchDefense = 1, insulation = 1 },
    },

    future = {
        title = "Preservation",
        armorMods = { biteDefense = 1, bulletDefense = 1, insulation = 1 },
    },
})
