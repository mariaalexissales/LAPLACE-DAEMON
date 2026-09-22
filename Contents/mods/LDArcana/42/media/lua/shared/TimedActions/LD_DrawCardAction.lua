----------
--ESTRAL--
----------

require "TimedActions/ISBaseTimedAction"
require "LD_Core"
require "LD_Arcana"
require "LD_Deck"

-- takes the top card of a tarot deck. the deck doesn't survive it: the card stays, the rest
-- is gone.
LD_DrawCardAction = ISBaseTimedAction:derive("LD_DrawCardAction")

function LD_DrawCardAction:isValid()
    return LDDeck.isDeck(self.deck) and self.character:getInventory():containsRecursive(self.deck)
end

function LD_DrawCardAction:update()
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function LD_DrawCardAction:start()
    self:setActionAnim("Loot")
end

function LD_DrawCardAction:stop()
    ISBaseTimedAction.stop(self)
end

function LD_DrawCardAction:perform()
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function LD_DrawCardAction:complete()
    local cardId = LDDeck.drawId()
    local card = LDArcana.card(cardId)
    if not card then return true end

    local inventory = self.character:getInventory()
    local container = self.deck:getContainer() or inventory
    container:Remove(self.deck)
    if isServer() then sendRemoveItemFromContainer(container, self.deck) end

    local drawn = inventory:AddItem(card.itemType)
    if drawn and isServer() then sendAddItemToContainer(inventory, drawn) end

    -- halo text is the client's to show, and in single player this is the client. a
    -- multiplayer server would need to send it over, which isn't done yet.
    if not isServer() then LDDeck.announce(self.character, cardId) end

    return true
end

function LD_DrawCardAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 60
end

function LD_DrawCardAction:new(character, deck)
    local o = ISBaseTimedAction.new(self, character)
    o.deck = deck
    o.maxTime = o:getDuration()
    return o
end
