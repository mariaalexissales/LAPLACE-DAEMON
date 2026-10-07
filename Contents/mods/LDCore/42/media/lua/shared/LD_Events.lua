----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Item"
require "TimedActions/ISClothingExtraAction"

-- stats are re-applied whenever a rolled weapon is picked up in hand, so it doesn't matter
-- whether the game saved the changed damage or reset it to the script's on load.
local function LD_equipped(player, item, loading)
    local data = LDItem.get(item)
    if not data then return end

    LDItem.refresh(item)
    LDCore.Hooks.run(LDCore.HOOK.WEAPON_EQUIP, {
        player = player,
        item = item,
        data = data,
        loading = loading == true,
    })
end

-- both events also fire on unequip, with no item.
local function LD_onEquipPrimary(player, item)
    if item then LD_equipped(player, item, false) end
end

-- a two-handed weapon lands in both hands. the primary event already covered it.
local function LD_onEquipSecondary(player, item)
    if item and player:getPrimaryHandItem() ~= item then LD_equipped(player, item, false) end
end

-- armor gets the same treatment when it's worn. the flag is there because a refresh can
-- lower a condition, and nothing promises that doesn't come back round as this event.
local LD_refreshingWorn = false

local function LD_refreshWorn(character)
    if LD_refreshingWorn or not character then return end
    LD_refreshingWorn = true

    local ok, err = pcall(function()
        local worn = character:getWornItems()
        for i = 0, worn:size() - 1 do
            local item = worn:getItemByIndex(i)
            if item and LDItem.get(item) then LDItem.refresh(item) end
        end
    end)

    LD_refreshingWorn = false
    if not ok then LDCore.warn("couldn't refresh worn armor: " .. tostring(err)) end
end

local function LD_onGameStart()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player then
            local primary = player:getPrimaryHandItem()
            local secondary = player:getSecondaryHandItem()

            if primary then LD_equipped(player, primary, true) end
            if secondary and secondary ~= primary then LD_equipped(player, secondary, true) end

            LD_refreshWorn(player)
        end
    end
end

-- wearing a vambrace on the other arm swaps it for a different item. vanilla copies the mod
-- data across, but sets the condition first, against the script's max, so a rolled piece
-- would come back at 5 out of 10.
--
-- kept on LDCore so reloading this file in debug doesn't wrap the wrap.
LDCore.originalCreateItemNew = LDCore.originalCreateItemNew or ISClothingExtraAction.createItemNew

function ISClothingExtraAction:createItemNew(item, newItem)
    local created = LDCore.originalCreateItemNew(self, item, newItem)

    if LDItem.get(newItem) then
        LDItem.refresh(newItem)
        newItem:setCondition(item:getCondition())
    end

    return created
end

local function LD_onWeaponHitCharacter(attacker, target, weapon, damage)
    local data = LDItem.get(weapon)
    if not data then return end

    LDCore.Hooks.run(LDCore.HOOK.WEAPON_HIT, {
        attacker = attacker,
        target = target,
        item = weapon,
        data = data,
        damage = damage,
    })
end

Events.OnEquipPrimary.Add(LD_onEquipPrimary)
Events.OnEquipSecondary.Add(LD_onEquipSecondary)
Events.OnGameStart.Add(LD_onGameStart)
Events.OnClothingUpdated.Add(LD_refreshWorn)
Events.OnWeaponHitCharacter.Add(LD_onWeaponHitCharacter)
