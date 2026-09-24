----------
--ESTRAL--
----------

require "TimedActions/ISBaseTimedAction"
require "LD_Core"
require "LD_Net"
require "LD_Item"
require "LD_Arcana"
require "LD_Spread"

-- puts a card from the inventory into one of a weapon's slots, or takes the one that's in
-- there back out. cardItem nil means take it out. a card that gets replaced or removed goes
-- back to the player, so nothing is ever destroyed by socketing.
--
-- the checks below are what stops the menu offering something silly. the server makes them
-- again on its own copy of the inventory, because this side can be lied to.
LD_SocketCardAction = ISBaseTimedAction:derive("LD_SocketCardAction")

function LD_SocketCardAction:isValid()
    local inventory = self.character:getInventory()
    if not inventory:containsRecursive(self.weapon) then return false end
    if not LDSpread.canSocket(self.weapon) then return false end

    if not self.cardItem then
        return LDSpread.cardAt(self.weapon, self.position) ~= nil
    end

    if not inventory:containsRecursive(self.cardItem) then return false end

    local card = LDArcana.cardOfItem(self.cardItem)
    if not card then return false end

    -- a card reads as one card wherever it sits, so it can't go on the same weapon twice.
    local already = LDSpread.positionOf(self.weapon, card.id)
    return already == nil or already == self.position
end

function LD_SocketCardAction:update()
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function LD_SocketCardAction:start()
    self:setActionAnim("Loot")
end

function LD_SocketCardAction:stop()
    ISBaseTimedAction.stop(self)
end

-- perform() is the client's half of a timed action: the server only ever gets complete(). so
-- the ask goes out from here, and in singleplayer the send is a direct call into the same
-- handler. ids only -- which card that is and whether it is held is the server's to work out.
function LD_SocketCardAction:perform()
    LD_Net.toServer("socket", {
        weapon = self.weapon:getID(),
        position = self.position,
        card = self.cardItem and self.cardItem:getID() or nil,
    })

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

-- nothing here: the server did the work, and the window is refreshed by its reply.
function LD_SocketCardAction:complete()
    return true
end

function LD_SocketCardAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 50
end

function LD_SocketCardAction:new(character, weapon, position, cardItem)
    local o = ISBaseTimedAction.new(self, character)
    o.weapon = weapon
    o.position = position
    o.cardItem = cardItem
    o.maxTime = o:getDuration()
    return o
end
