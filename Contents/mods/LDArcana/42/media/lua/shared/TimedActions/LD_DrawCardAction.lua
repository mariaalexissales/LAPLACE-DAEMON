----------
--ESTRAL--
----------

require "TimedActions/ISBaseTimedAction"
require "LD_Core"
require "LD_Net"
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

-- perform() is the client's half of a timed action: the server only ever gets complete(). the
-- deck goes by id and the card that comes off it is picked server-side, so nobody deals
-- themselves a fortune.
function LD_DrawCardAction:perform()
    LD_Net.toServer("draw", { deck = self.deck:getID() })

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

-- nothing here: the server draws the card and sends back the name to put over your head.
function LD_DrawCardAction:complete()
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
