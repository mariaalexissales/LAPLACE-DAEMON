----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Item"
require "LD_Arcana"
require "LD_Spread"
require "LD_DebugMenu"

LD_ArcanaDebugMenu = LD_ArcanaDebugMenu or {}

function LD_ArcanaDebugMenu.socket(item, position, cardId)
    if LDSpread.socket(item, position, cardId) then LD_DebugMenu.inspect(item) end
end

function LD_ArcanaDebugMenu.unsocket(item, position)
    if LDSpread.unsocket(item, position) then LD_DebugMenu.inspect(item) end
end

local function LD_onFillInventoryObjectContextMenu(playerNum, context, items)
    if not isDebugEnabled() then return end

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

        for _, id in ipairs(LDArcana.activeCards()) do
            local cardOption = cardMenu:addOption(LDArcana.cardName(id), item, LD_ArcanaDebugMenu.socket, position, id)
            cardOption.iconTexture = LDArcana.cardTexture(id)
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(LD_onFillInventoryObjectContextMenu)
