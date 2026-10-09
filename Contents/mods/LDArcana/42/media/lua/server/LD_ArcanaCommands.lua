----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Net"
require "LD_Item"
require "LD_Commands"
require "LD_Arcana"
require "LD_Spread"
require "LD_Deck"

if not LDCore.isAuthority() then return end

local SOCKET_COOLDOWN_MS = 250
local DRAW_COOLDOWN_MS = 500

-- the client names a weapon, a slot and a card by id. which card that is, whether the player
-- is carrying it and whether it may go there are all decided here.
function LD_Commands.handlers.socket(player, args)
    if not player or not args then return end
    if not LDArcana.IS_POSITION[args.position] then return end
    if not LD_Commands.cooledDown("socket", player, SOCKET_COOLDOWN_MS) then return end

    local weapon = LD_Commands.heldItem(player, args.weapon)
    if not weapon or not LDSpread.canSocket(weapon) then
        LD_Net.toClient(player, "refused", { reason = "NoWeapon" })
        return
    end

    local giveBack = nil

    if args.card then
        local cardItem = LD_Commands.heldItem(player, args.card)
        local card = cardItem and LDArcana.cardOfItem(cardItem)
        if not card then
            LD_Net.toClient(player, "refused", { reason = "NoCard" })
            return
        end

        if not LDArcana.fits(card, weapon) then
            LD_Net.toClient(player, "refused", { reason = "WrongKind" })
            return
        end

        -- a card reads as one card wherever it sits, so it can't go on the same weapon twice.
        local already = LDSpread.positionOf(weapon, card.id)
        if already and already ~= args.position then
            LD_Net.toClient(player, "refused", { reason = "Duplicate" })
            return
        end

        -- the card is taken only once the slot has accepted it, so a refusal never costs it.
        local socketed, replaced = LDSpread.socket(weapon, args.position, card.id, player)
        if not socketed then
            LD_Net.toClient(player, "refused", { reason = "NoCard" })
            return
        end

        LD_Commands.remove(player, cardItem)
        giveBack = replaced
    else
        giveBack = LDSpread.unsocket(weapon, args.position, player)
        if not giveBack then
            LD_Net.toClient(player, "refused", { reason = "EmptySlot" })
            return
        end
    end

    -- a switched-off card has no item to hand back; it only leaves the slot.
    local card = LDArcana.isActive(giveBack) and LDArcana.card(giveBack)
    if card then LD_Commands.add(player:getInventory(), card.itemType) end

    LD_Net.toClient(player, "socketed", { position = args.position })
end

-- the free socket behind the debug menu: no card item changes hands, so it is admin-only.
function LD_Commands.handlers.spread(player, args)
    if not LDCore.isAdmin(player) then
        LDCore.warn(tostring(player and player:getUsername()) .. " asked for a debug spread without permission")
        return
    end
    if not args or not LDArcana.IS_POSITION[args.position] then return end

    local weapon = LD_Commands.heldItem(player, args.weapon)
    if not weapon or not LDSpread.canSocket(weapon) then return end

    if args.card then
        LDSpread.socket(weapon, args.position, args.card, player)
    else
        LDSpread.unsocket(weapon, args.position, player)
    end

    LD_Net.toClient(player, "socketed", { position = args.position })
end

-- the client says which deck it is pulling from. which card comes off the top is the
-- server's to decide, or the client picks its own fortune.
function LD_Commands.handlers.draw(player, args)
    if not player or not args then return end
    if not LD_Commands.cooledDown("draw", player, DRAW_COOLDOWN_MS) then return end

    local deck = LD_Commands.heldItem(player, args.deck)
    if not deck or not LDDeck.isDeck(deck) then
        LD_Net.toClient(player, "refused", { reason = "NoDeck" })
        return
    end

    local cardId = LDDeck.drawId()
    local card = LDArcana.card(cardId)
    if not card then return end

    LD_Commands.remove(player, deck)
    LD_Commands.add(player:getInventory(), card.itemType)

    LDCore.log(tostring(player:getUsername()) .. " drew " .. tostring(cardId))
    LD_Net.toClient(player, "drawn", { card = cardId })
end
