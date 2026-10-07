----------
--ESTRAL--
----------

require "LD_Arcana"

-- V - The Hierophant. Protection. an armor card: it has no reading for a weapon.
-- stats from the design: Insulation, Bite Defense, Scratch Defense, Bullet Defense.

LDArcana.define("HIEROPHANT", {
    area = "Protection",
    theme = "Discipline, tradition, maintenance",
    stats = { "insulation", "biteDefense", "scratchDefense", "bulletDefense" },

    past = {
        title = "Tradition",
        armorMods = { insulation = 1, scratchDefense = 1 },
    },

    present = {
        title = "Discipline",
        armorMods = { biteDefense = 1, scratchDefense = 1, bulletDefense = 1 },
    },

    future = {
        title = "Preservation",
        armorMods = { insulation = 1, biteDefense = 1, bulletDefense = 1 },
    },
})
