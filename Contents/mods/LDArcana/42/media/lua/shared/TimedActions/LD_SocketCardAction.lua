----------
--ESTRAL--
----------

require "TimedActions/ISBaseTimedAction"
require "LD_Core"
require "LD_Item"
require "LD_Arcana"
require "LD_Spread"

-- puts a card from the inventory into one of a weapon's slots, or takes the one that's in
-- there back out. cardItem nil means take it out. a card that gets replaced or removed goes
-- back to the player, so nothing is ever destroyed by socketing.
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

function LD_SocketCardAction:perform()
    -- complete() and perform() can run either way round depending on the build, so the
    -- window is told from both. refreshing twice costs nothing.
    if LD_SpreadWindow then LD_SpreadWindow.refreshAll() end

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function LD_SocketCardAction:complete()
    local inventory = self.character:getInventory()
    local giveBack = nil

    if self.cardItem then
        local socketed, replaced = LDSpread.socket(self.weapon, self.position, LDArcana.CardByItem[self.cardItem:getFullType()])
        if not socketed then return true end

        local container = self.cardItem:getContainer() or inventory
        container:Remove(self.cardItem)
        if isServer() then sendRemoveItemFromContainer(container, self.cardItem) end

        giveBack = replaced
    else
        giveBack = LDSpread.unsocket(self.weapon, self.position)
    end

    -- a switched-off card has no item to hand back; it only leaves the slot.
    local card = LDArcana.isActive(giveBack) and LDArcana.card(giveBack)
    if card then
        local returned = inventory:AddItem(card.itemType)
        if returned and isServer() then sendAddItemToContainer(inventory, returned) end
    end

    if isServer() then
        syncItemModData(self.character, self.weapon)
        syncItemFields(self.character, self.weapon)
    end

    if LD_SpreadWindow then LD_SpreadWindow.refreshAll() end

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
