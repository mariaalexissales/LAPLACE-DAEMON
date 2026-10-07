----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Net"
require "LD_Item"
require "LD_Arcana"
require "LD_Spread"
require "LD_DebugMenu"

LD_ArcanaDebugMenu = LD_ArcanaDebugMenu or {}

-- no card item changes hands here, which is the whole point of it and also why the command
-- behind it is admin-only.
function LD_ArcanaDebugMenu.socket(item, position, cardId)
    LD_Net.toServer("spread", { weapon = item:getID(), position = position, card = cardId })
end

function LD_ArcanaDebugMenu.unsocket(item, position)
    LD_Net.toServer("spread", { weapon = item:getID(), position = position })
end

local function LD_onFillInventoryObjectContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player or not LD_DebugMenu.allowed(player) then return end

    local item = nil
    for _, entry in ipairs(LD_DebugMenu.flatten(items)) do
        if LDSpread.canSocket(entry) then
            item = entry
            break
        end
    end
    if not item then return end

    local option = context:addOption("LD: Spread")
    local positionMenu = context:getNew(context)
    context:addSubMenu(option, positionMenu)

    for _, position in ipairs(LDArcana.POSITIONS) do
        local current = LDSpread.cardAt(item, position)
        local label = LDArcana.positionName(position)
        if current then label = label .. " (" .. LDArcana.cardName(current.id) .. ")" end

        local positionOption = positionMenu:addOption(label)
        positionOption.iconTexture = current and LDArcana.cardTexture(current.id) or getTexture("Item_LD_Tarot_Back")
        local cardMenu = positionMenu:getNew(positionMenu)
        positionMenu:addSubMenu(positionOption, cardMenu)

        if current then
            cardMenu:addOption("(Empty the slot)", item, LD_ArcanaDebugMenu.unsocket, position)
        end

        -- the server would refuse the rest, so they aren't offered.
        for _, id in ipairs(LDArcana.activeCards()) do
            if LDArcana.fits(LDArcana.card(id), item) then
                local cardOption = cardMenu:addOption(LDArcana.cardName(id), item, LD_ArcanaDebugMenu.socket, position, id)
                cardOption.iconTexture = LDArcana.cardTexture(id)
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(LD_onFillInventoryObjectContextMenu)
