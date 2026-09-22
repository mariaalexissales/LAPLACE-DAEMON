----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Arcana"
require "LD_Spread"

-- listeners added twice would run every card twice, so reloading this file is a no-op.
if LDArcana.hooked then return end
LDArcana.hooked = true

-- one dispatcher per effect name. it reads the spread off ctx.data rather than the item, so
-- a preview can ask what a card it hasn't socketed yet would do. each filled slot runs in
-- position order, all sharing one ctx, so the present card sees what the past card changed.
for effect, hookName in pairs(LDArcana.EFFECT_HOOKS) do
    LDCore.Hooks.add(hookName, function(ctx)
        local spread = ctx.data and ctx.data.arcana
        if not spread then return end

        LDSpread.each(spread, function(position, card)
            -- the arrows from the card's design, then anything its own function wants to do.
            if effect == "stats" then
                LDArcana.applyMods(ctx, card[position].mods)
            end

            local fn = card[position][effect]
            if not fn then return end

            local ok, err = pcall(fn, ctx, card, position)
            if not ok then
                LDCore.warn("arcana " .. card.id .. " " .. position .. " " .. effect .. " failed: " .. tostring(err))
            end
        end)
    end)
end
