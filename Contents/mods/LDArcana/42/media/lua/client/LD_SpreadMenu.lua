----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Item"
require "LD_Arcana"
require "LD_Spread"
require "LD_SpreadWindow"
require "LD_DebugMenu"

LD_SpreadMenu = LD_SpreadMenu or {}

function LD_SpreadMenu.onOpen(player, weapon)
    LD_SpreadWindow.open(player, weapon)
end

-- every rolled weapon the player is carrying, for the menu on a card.
local function LD_carriedWeapons(player)
    local found = player:getInventory():getAllEvalRecurse(function(item)
        return instanceof(item, "HandWeapon") and LDItem.get(item) ~= nil
    end, ArrayList.new())

    local weapons = {}
    for i = 0, found:size() - 1 do weapons[#weapons + 1] = found:get(i) end
    return weapons
end

local function LD_onFillInventoryObjectContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() then return end

    local selected = LD_DebugMenu.flatten(items)
    local weapon, card = nil, nil

    for _, item in ipairs(selected) do
        if not weapon and instanceof(item, "HandWeapon") and LDSpread.canSocket(item) then
            weapon = item
        end
        if not card and LDArcana.cardOfItem(item) then
            card = item
        end
    end

    local label = LDCore.text("ContextMenu_LD_Spread", "Tarot Spread")

    if weapon then
        context:addOption(label, player, LD_SpreadMenu.onOpen, weapon)
        return
    end

    -- on a card, the spread to open is whichever weapon it would go into.
    if card then
        local weapons = LD_carriedWeapons(player)

        if #weapons == 0 then
            local option = context:addOption(label)
            option.notAvailable = true
            option.toolTip = ISInventoryPaneContextMenu.addToolTip()
            option.toolTip.description = LDCore.text("ContextMenu_LD_NoWeapon",
                "No forged weapon to put it in.")
            return
        end

        if #weapons == 1 then
            context:addOption(label, player, LD_SpreadMenu.onOpen, weapons[1])
            return
        end

        local option = context:addOption(label)
        local sub = context:getNew(context)
        context:addSubMenu(option, sub)

        for _, item in ipairs(weapons) do
            local entry = sub:addOption(item:getName(), player, LD_SpreadMenu.onOpen, item)
            entry.itemForTexture = item
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(LD_onFillInventoryObjectContextMenu)
