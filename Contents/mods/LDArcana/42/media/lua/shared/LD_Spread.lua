----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Item"
require "LD_Arcana"

LDSpread = LDSpread or {}

function LDSpread.get(item)
    local data = LDItem.get(item)
    return data and data.arcana or nil
end

-- only rolled items have LD data to keep a spread in.
function LDSpread.canSocket(item)
    return LDItem.get(item) ~= nil
end

function LDSpread.cardAt(item, position)
    local spread = LDSpread.get(item)
    return spread and LDArcana.card(spread[position]) or nil
end

-- a card reads as one card, wherever it sits: the same one twice on a weapon is refused.
-- returns the position it's already in.
function LDSpread.positionOf(item, cardId)
    local spread = LDSpread.get(item)
    if not spread or not cardId then return nil end

    for _, position in ipairs(LDArcana.POSITIONS) do
        if spread[position] == cardId then return position end
    end

    return nil
end

function LDSpread.hasCard(item, cardId)
    return LDSpread.positionOf(item, cardId) ~= nil
end

-- puts a card in a slot and hands back the id of the one it replaced, so the caller can
-- give that card back. false means it didn't go in.
function LDSpread.socket(item, position, cardId, player)
    if not LDArcana.IS_POSITION[position] then
        LDCore.warn("socket: no position " .. tostring(position))
        return false
    end
    if not LDArcana.isActive(cardId) then
        LDCore.warn("socket: no active card " .. tostring(cardId))
        return false
    end

    local data = LDItem.get(item)
    if not data then return false end

    -- a weapon card has nothing to say to a cuirass, and the other way round.
    if not LDArcana.fits(LDArcana.card(cardId), item) then return false end

    local already = LDSpread.positionOf(item, cardId)
    if already and already ~= position then return false end

    data.arcana = data.arcana or {}
    local replaced = data.arcana[position]
    data.arcana[position] = cardId
    LDItem.changed(item, player)

    return true, replaced
end

-- returns the id that was in the slot, so a physical card can be handed back.
function LDSpread.unsocket(item, position, player)
    local spread = LDSpread.get(item)
    local cardId = spread and spread[position]
    if not cardId then return nil end

    spread[position] = nil
    LDItem.changed(item, player)
    return cardId
end

-- fn(position, card) for each filled slot, past -> present -> future. takes the spread table
-- itself, so it works on a hypothetical spread as well as the one on an item.
function LDSpread.each(spread, fn)
    if not spread then return end

    for _, position in ipairs(LDArcana.POSITIONS) do
        local card = LDArcana.card(spread[position])
        if card then fn(position, card) end
    end
end
