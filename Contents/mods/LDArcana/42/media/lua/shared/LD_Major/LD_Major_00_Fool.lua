----------
--ESTRAL--
----------

require "LD_Arcana"

-- 0 - The Fool. Tempo / Reach.
-- stats from the design: Encumbrance, Attack Speed, Max Range.
--
-- THE FORMAT, for every card in this folder.
--
-- a card has three slots. the slot decides how the card manifests, so one card covers all
-- three readings rather than being three cards.
--
--   mods    the design's arrows. 1 is up, 2 is a double up, -1 is down, always read in the
--           stat's own direction, so weight = -1 is a lighter weapon. one arrow is worth
--           whatever LDArcana.STEPS says, as a share of the weapon after its rarity roll,
--           so a card is worth more on a legendary than on a common.
--   title   the slot's name, e.g. "Impending dominance".
--   text    a line of flavour under it.
--
-- stat keys: minDamage, maxDamage, criticalChance, critMultiplier, baseSpeed, minRange,
-- maxRange, knockback, conditionMax, conditionLowerChance, averageCondition, weight.
-- averageCondition isn't a real stat; it leans on max condition and condition lower chance
-- together, the two things that decide how long a weapon lasts.
--
-- for anything the arrows can't say, a slot can hold a function instead. it gets
-- (ctx, card, position), and runs after the mods:
--
--   stats  every time the weapon's stats are rebuilt: forge, assemble, equip, load, socket,
--          and on every preview. keep it pure - no side effects - or the socket menu will
--          lie or worse.
--          ctx.item, ctx.data, ctx.base (vanilla), ctx.rolled (after rarity, before cards),
--          ctx.stats (what gets written; change this one).
--   equip  the weapon goes into a hand, and once on load for what's already held.
--          ctx.player, ctx.item, ctx.data, ctx.loading.
--   hit    the weapon hits a zombie or a player.
--          ctx.attacker, ctx.target, ctx.item, ctx.data, ctx.damage (read only).
--
-- no effects yet.

LDArcana.define("FOOL", {
    area = "Tempo / Reach",
    theme = "Improvisation, freedom, taking risks",
    stats = { "weight", "baseSpeed", "maxRange" },

    -- past    = { title = "", text = "", mods = { weight = -1 } },
    -- present = { title = "", text = "", mods = { baseSpeed = 2, maxRange = -1 } },
    -- future  = { title = "", text = "", mods = { maxRange = 1 } },
})
