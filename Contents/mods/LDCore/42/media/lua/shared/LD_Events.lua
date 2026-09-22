----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Item"

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

local function LD_onGameStart()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player then
            local primary = player:getPrimaryHandItem()
            local secondary = player:getSecondaryHandItem()

            if primary then LD_equipped(player, primary, true) end
            if secondary and secondary ~= primary then LD_equipped(player, secondary, true) end
        end
    end
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
Events.OnWeaponHitCharacter.Add(LD_onWeaponHitCharacter)
