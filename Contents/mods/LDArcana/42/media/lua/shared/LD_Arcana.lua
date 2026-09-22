----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Item"

LDArcana = LDArcana or {}

-- slot order is also effect order: past runs before present, present before future.
LDArcana.POSITIONS = { "past", "present", "future" }
LDArcana.IS_POSITION = { past = 1, present = 2, future = 3 }

LDArcana.POSITION_NAMES = { past = "Past", present = "Present", future = "Future" }

-- effect name a card uses -> the LDCore hook that runs it. a new kind of effect is one line
-- here plus the Hooks.run call on the core side. the ctx each one gets is listed on
-- LDCore.HOOK in LD_Core.lua and in the template card.
LDArcana.EFFECT_HOOKS = {
    stats = LDCore.HOOK.ITEM_STATS,
    equip = LDCore.HOOK.WEAPON_EQUIP,
    hit   = LDCore.HOOK.WEAPON_HIT,
}

-- fields a card carries outside its three slots.
LDArcana.CARD_FIELDS = { area = true, theme = true, stats = true }

-- what one arrow is worth. pct is a share of the weapon's rolled value, so a card is worth
-- more on a legendary than on a common; add is a flat amount. spread is a stat that isn't
-- real: it hands its step to the stats it stands for.
-- placeholder numbers. this table is the one place to tune how loud every card is.
LDArcana.STEPS = {
    minDamage            = { pct = 0.10 },
    maxDamage            = { pct = 0.10 },
    criticalChance       = { add = 5 },
    critMultiplier       = { add = 0.5 },
    baseSpeed            = { pct = 0.05 },
    minRange             = { add = 0.05 },
    maxRange             = { add = 0.10 },
    knockback            = { add = 0.10 },
    weight               = { pct = 0.10 },
    conditionMax         = { pct = 0.15 },
    conditionLowerChance = { pct = 0.20 },

    -- average condition is max condition x condition lower chance, so it leans on both.
    averageCondition     = { spread = { conditionMax = 0.5, conditionLowerChance = 0.5 } },
}

-- the card items live in this script module, as Tarot_<id>, with icon Item_LD_Tarot_<id>.
-- tools/build_tarot.ps1 writes the items, names and icons off the same ids, so a card added
-- here needs adding there too.
LDArcana.ITEM_MODULE = "LDArcana"

-- id -> { id, name, number, arcana, itemType, texture, past = {}, present = {}, future = {} }
LDArcana.Cards = LDArcana.Cards or {}

-- item full type -> card id.
LDArcana.CardByItem = LDArcana.CardByItem or {}

-- registration order, for menus.
LDArcana.CARD_ORDER = LDArcana.CARD_ORDER or {}

-- identity only. effects are attached afterwards with LDArcana.define. minor arcana can come
-- through here later with arcana = "minor".
function LDArcana.register(id, name, number, arcana)
    if LDArcana.Cards[id] then return LDArcana.Cards[id] end

    local card = {
        id = id,
        name = name,
        number = number,
        arcana = arcana or "major",
        itemType = LDArcana.ITEM_MODULE .. ".Tarot_" .. id,
        texture = "Item_LD_Tarot_" .. id,
        panel = "media/ui/LDArcana/Tarot_" .. id .. ".png",
    }
    for _, position in ipairs(LDArcana.POSITIONS) do card[position] = {} end

    LDArcana.Cards[id] = card
    LDArcana.CardByItem[card.itemType] = id
    LDArcana.CARD_ORDER[#LDArcana.CARD_ORDER + 1] = id
    return card
end

local LD_MAJORS = {
    { "FOOL", "The Fool" },
    { "MAGICIAN", "The Magician" },
    { "HIGH_PRIESTESS", "The High Priestess" },
    { "EMPRESS", "The Empress" },
    { "EMPEROR", "The Emperor" },
    { "HIEROPHANT", "The Hierophant" },
    { "LOVERS", "The Lovers" },
    { "CHARIOT", "The Chariot" },
    { "STRENGTH", "Strength" },
    { "HERMIT", "The Hermit" },
    { "WHEEL_OF_FORTUNE", "Wheel of Fortune" },
    { "JUSTICE", "Justice" },
    { "HANGED_MAN", "The Hanged Man" },
    { "DEATH", "Death" },
    { "TEMPERANCE", "Temperance" },
    { "DEVIL", "The Devil" },
    { "TOWER", "The Tower" },
    { "STAR", "The Star" },
    { "MOON", "The Moon" },
    { "SUN", "The Sun" },
    { "JUDGEMENT", "Judgement" },
    { "WORLD", "The World" },
}

-- numbered 0 to 21, the Fool first.
for i, entry in ipairs(LD_MAJORS) do
    LDArcana.register(entry[1], entry[2], i - 1, "major")
end

-- the cards in play. the rest stay registered and keep their files, but have no item, never
-- come out of a deck and never show in a menu. tools/build_tarot.ps1 reads this list to
-- decide which items to write, so switching a card on means adding it here and re-running
-- the tool.
LDArcana.ACTIVE = { "EMPEROR", "CHARIOT", "DEATH", "TEMPERANCE" }

LDArcana.IS_ACTIVE = {}
for _, id in ipairs(LDArcana.ACTIVE) do LDArcana.IS_ACTIVE[id] = true end

function LDArcana.card(id)
    return id and LDArcana.Cards[id] or nil
end

function LDArcana.isActive(id)
    return id ~= nil and LDArcana.IS_ACTIVE[id] == true
end

-- the active cards in card order, for menus and draws.
function LDArcana.activeCards()
    local out = {}
    for _, id in ipairs(LDArcana.CARD_ORDER) do
        if LDArcana.IS_ACTIVE[id] then out[#out + 1] = id end
    end
    return out
end

-- the card a tarot item is, or nil for any other item and for a card that's switched off.
function LDArcana.cardOfItem(item)
    if not item then return nil end

    local id = LDArcana.CardByItem[item:getFullType()]
    if not LDArcana.isActive(id) then return nil end

    return LDArcana.card(id)
end

-- the item's translated name, so ItemName.json is the one place card names are written.
-- the registry name is the fallback if the item script didn't load.
function LDArcana.cardName(id)
    local card = LDArcana.card(id)
    if not card then return tostring(id) end

    local ok, name = pcall(getItemNameFromFullType, card.itemType)
    if ok and name and name ~= "" and name ~= card.itemType then return name end

    return card.name
end

-- the icon, for menus and UI. nil if the texture is missing.
function LDArcana.cardTexture(id)
    local card = LDArcana.card(id)
    return card and getTexture(card.texture) or nil
end

-- the card at its own size, for the spread window.
LDArcana.BACK_PANEL = "media/ui/LDArcana/Tarot_Back.png"

function LDArcana.cardPanel(id)
    local card = LDArcana.card(id)
    return card and getTexture(card.panel) or nil
end

function LDArcana.backPanel()
    return getTexture(LDArcana.BACK_PANEL)
end

function LDArcana.positionName(position)
    return LDCore.text("IGUI_LD_Position_" .. tostring(position), LDArcana.POSITION_NAMES[position] or tostring(position))
end

-- attaches a card's design to the registered card:
--
--   LDArcana.define("EMPEROR", {
--       area = "Power", theme = "Authority, force, dominance",
--       stats = { "minDamage", "maxDamage", "knockback" },
--       present = { title = "Force", text = "Everything goes into this strike.",
--                   mods = { maxDamage = 2, knockback = 1, baseSpeed = -1 } },
--   })
--
-- mods are arrow counts from the design: 1 is an up arrow, 2 a double, -1 a down. they read
-- in the stat's own direction, so weight = -1 is lighter. a slot can also hold a function
-- named after an EFFECT_HOOKS entry for anything mods can't say. calling define twice for a
-- card adds to what's there.
function LDArcana.define(id, effects)
    local card = LDArcana.card(id)
    if not card then
        LDCore.warn("arcana define: no card " .. tostring(id))
        return nil
    end

    for key, value in pairs(effects) do
        if LDArcana.CARD_FIELDS[key] then
            card[key] = value
        elseif not LDArcana.IS_POSITION[key] then
            LDCore.warn("arcana define " .. id .. ": no position " .. tostring(key))
        else
            local slot = card[key]

            for entry, detail in pairs(value) do
                if entry == "mods" then
                    slot.mods = slot.mods or {}
                    for stat, arrows in pairs(detail) do
                        if not LDArcana.STEPS[stat] then
                            LDCore.warn("arcana define " .. id .. " " .. key .. ": no stat " .. tostring(stat))
                        else
                            slot.mods[stat] = arrows
                        end
                    end
                elseif type(detail) ~= "function" or LDArcana.EFFECT_HOOKS[entry] then
                    slot[entry] = detail
                else
                    LDCore.warn("arcana define " .. id .. " " .. key .. ": no effect " .. tostring(entry))
                end
            end
        end
    end

    return card
end

-- does this slot do anything at all? the stub cards are registered but empty.
function LDArcana.slotIsEmpty(card, position)
    local slot = card and card[position]
    if not slot then return true end

    if slot.mods then
        for _ in pairs(slot.mods) do return false end
    end
    for effect in pairs(LDArcana.EFFECT_HOOKS) do
        if slot[effect] then return false end
    end

    return true
end

-- ---------------------------------------------------------------------------------------
-- mods
-- ---------------------------------------------------------------------------------------

-- one arrow's worth of a stat, added onto stats. from is what a pct step is a share of:
-- the weapon after its rarity roll but before any card, so the slots don't stack on
-- each other and their order can't change the total.
function LDArcana.addStep(stats, from, stat, arrows)
    local step = LDArcana.STEPS[stat]
    if not step or not arrows or arrows == 0 then return end

    if step.spread then
        for other, share in pairs(step.spread) do
            LDArcana.addStep(stats, from, other, arrows * share)
        end
        return
    end

    if stats[stat] == nil then return end

    local amount = step.add or 0
    if step.pct then
        local base = from and from[stat]
        if not base then return end
        amount = base * step.pct
    end

    stats[stat] = stats[stat] + amount * arrows
end

function LDArcana.applyMods(ctx, mods)
    if not mods then return end

    for stat, arrows in pairs(mods) do
        LDArcana.addStep(ctx.stats, ctx.rolled or ctx.base, stat, arrows)
    end
end

-- "Max Damage ++" per line, green when the card is doing the weapon a favour. PZ's fonts
-- have no arrow glyphs, so the design's arrows read as + and -.
function LDArcana.modText(mods)
    local lines = {}
    if not mods then return lines end

    local order = {}
    for _, stat in ipairs(LDItem.STAT_ORDER) do order[#order + 1] = stat end
    order[#order + 1] = "averageCondition"

    for _, stat in ipairs(order) do
        local arrows = mods[stat]
        if arrows and arrows ~= 0 then
            local marks = string.rep(arrows > 0 and "+" or "-", math.max(1, math.floor(math.abs(arrows) + 0.5)))
            local good = (arrows > 0) ~= (LDItem.LOWER_IS_BETTER[stat] == true)
            lines[#lines + 1] = {
                text = LDCore.statName(stat) .. " " .. marks,
                good = good,
            }
        end
    end

    return lines
end

-- what the weapon would look like with cardId in that slot, against what it looks like now.
-- cardId nil previews emptying the slot. returns nil for a weapon with no LD data.
function LDArcana.preview(item, position, cardId)
    local data = LDItem.get(item)
    if not data then return nil end

    local before = LDItem.computeStats(item, data)
    if not before then return nil end

    local hypothetical = LDItem.copyTable(data)
    hypothetical.arcana = hypothetical.arcana or {}
    hypothetical.arcana[position] = cardId

    local after = LDItem.computeStats(item, hypothetical)
    if not after then return nil end

    local rows = {}
    for _, stat in ipairs(LDItem.STAT_ORDER) do
        if before[stat] ~= after[stat] then
            rows[#rows + 1] = {
                stat = stat,
                from = before[stat],
                to = after[stat],
                good = (after[stat] > before[stat]) ~= (LDItem.LOWER_IS_BETTER[stat] == true),
            }
        end
    end

    local averageBefore, averageAfter = LDItem.averageCondition(before), LDItem.averageCondition(after)
    if averageBefore and averageAfter and averageBefore ~= averageAfter then
        rows[#rows + 1] = {
            stat = "averageCondition",
            from = averageBefore,
            to = averageAfter,
            good = averageAfter > averageBefore,
        }
    end

    return { card = LDArcana.card(cardId), position = position, rows = rows, before = before, after = after }
end
