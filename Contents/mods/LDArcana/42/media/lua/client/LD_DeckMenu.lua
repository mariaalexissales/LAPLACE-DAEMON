----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Arcana"
require "LD_Deck"
require "LD_DebugMenu"
require "TimedActions/LD_DrawCardAction"

LD_DeckMenu = LD_DeckMenu or {}

function LD_DeckMenu.onDraw(player, deck)
    ISInventoryPaneContextMenu.transferIfNeeded(player, deck)
    ISTimedActionQueue.add(LD_DrawCardAction:new(player, deck))
end

local function LD_onFillInventoryObjectContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() then return end

    local deck = nil
    for _, item in ipairs(LD_DebugMenu.flatten(items)) do
        if LDDeck.isDeck(item) then
            deck = item
            break
        end
    end
    if not deck then return end

    local option = context:addOption(LDCore.text("ContextMenu_LD_DrawCard", "Draw a Card"),
        player, LD_DeckMenu.onDraw, deck)
    option.iconTexture = getTexture("Item_LD_Tarot_Back")

    local tooltip = ISInventoryPaneContextMenu.addToolTip()
    tooltip.description = LDCore.text("ContextMenu_LD_DrawCardLore",
        "You pull from the top of the deck, and the rest of it goes poof, as if the universe took it back.")
    option.toolTip = tooltip

    if #LDArcana.activeCards() == 0 then option.notAvailable = true end
end

Events.OnFillInventoryObjectContextMenu.Add(LD_onFillInventoryObjectContextMenu)
