----------
--ESTRAL--
----------

require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISContextMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "LD_Core"
require "LD_Item"
require "LD_Arcana"
require "LD_Spread"
require "TimedActions/LD_SocketCardAction"

-- the three slots of one weapon, with the card art in them. right-click a slot for the
-- cards you are carrying and what each would do there.

local PAD = 10
local GAP = 10
local CARD_W = 102
local CARD_H = 158
-- a slot is wider than its card, so a title has room under the art to wrap into.
local SLOT_W = 136
local TITLE_LINES = 2
local ROW_H = 16

local function LD_fontHeight()
    return getTextManager():getFontHeight(UIFont.Small)
end

-- the position, then the title. read off the font, which the player can make bigger.
local function LD_labelHeight()
    return 3 + LD_fontHeight() * (1 + TITLE_LINES)
end

-- cuts text down to width with "...", for a stat name or a word too long for its slot.
local function LD_fit(text, width)
    local manager = getTextManager()
    if manager:MeasureStringX(UIFont.Small, text) <= width then return text end

    while #text > 1 and manager:MeasureStringX(UIFont.Small, text .. "...") > width do
        text = text:sub(1, #text - 1)
    end

    return text .. "..."
end

-- breaks a title on spaces into lines no wider than width. past maxLines, the rest goes
-- onto the last line and gives way there, so "What has already been destroyed" wraps
-- rather than running into the card beside it.
local function LD_wrap(text, width, maxLines)
    local manager = getTextManager()
    local lines = {}

    for word in text:gmatch("%S+") do
        local last = lines[#lines]
        if last and manager:MeasureStringX(UIFont.Small, last .. " " .. word) <= width then
            lines[#lines] = last .. " " .. word
        else
            lines[#lines + 1] = word
        end
    end

    while #lines > maxLines do
        lines[#lines - 1] = lines[#lines - 1] .. " " .. lines[#lines]
        lines[#lines] = nil
    end

    for i, line in ipairs(lines) do lines[i] = LD_fit(line, width) end
    return lines
end

LD_SpreadSlot = ISButton:derive("LD_SpreadSlot")

function LD_SpreadSlot:new(x, y, width, height, window, position)
    local o = ISButton:new(x, y, width, height, "", window, LD_SpreadSlot.onSlotClick)
    setmetatable(o, self)
    self.__index = self

    o.window = window
    o.position = position
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.15 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.35 }

    return o
end

function LD_SpreadSlot.onSlotClick(window, slot)
    window:openSlotMenu(slot.position)
end

function LD_SpreadSlot:onRightMouseUp(x, y)
    self.window:openSlotMenu(self.position)
end

function LD_SpreadSlot:prerender()
    -- ISButton draws its own chrome in prerender, and this slot is all card art, so none of
    -- it is called. the tooltip is, because that is where ISButton keeps it.
    self:updateTooltip()

    local card = LDSpread.cardAt(self.window.weapon, self.position)
    local texture = card and LDArcana.cardPanel(card.id) or LDArcana.backPanel()
    local hover = self:isMouseOver()
    local cardX = math.floor((self.width - CARD_W) / 2)

    self:drawRect(cardX, 0, CARD_W, CARD_H, hover and 0.5 or 0.35, 0, 0, 0)

    if texture then
        -- an empty slot shows the back of a card, dimmed, so the eye goes to the filled ones.
        local alpha = card and 1 or 0.45
        self:drawTextureScaledAspect(texture, cardX + 1, 1, CARD_W - 2, CARD_H - 2, alpha, 1, 1, 1)
    end

    local frame = LD_SpreadWindow.frameTexture()
    if frame then
        self:drawTextureScaled(frame, cardX, 0, CARD_W, CARD_H, hover and 1 or 0.7, 1, 1, 1)
    else
        self:drawRectBorder(cardX, 0, CARD_W, CARD_H, hover and 0.6 or 0.25, 1, 1, 1)
    end

    local y = CARD_H + 3
    local name = LDArcana.positionName(self.position)
    self:drawTextCentre(name, self.width / 2, y, 0.85, 0.82, 0.62, 1, UIFont.Small)

    y = y + LD_fontHeight()
    local subtitle = LDCore.text("IGUI_LD_SlotEmpty", "Empty")
    if card then
        subtitle = card[self.position].title or LDArcana.cardName(card.id)
    end

    -- wrapped once per title rather than measured word by word every frame.
    if subtitle ~= self.wrappedFrom then
        self.wrappedFrom = subtitle
        self.wrapped = LD_wrap(subtitle, self.width - 4, TITLE_LINES)
    end

    for _, line in ipairs(self.wrapped) do
        self:drawTextCentre(line, self.width / 2, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + LD_fontHeight()
    end
end

function LD_SpreadSlot:render()
end

-- ---------------------------------------------------------------------------------------
-- window
-- ---------------------------------------------------------------------------------------

LD_SpreadWindow = ISCollapsableWindow:derive("LD_SpreadWindow")
LD_SpreadWindow.instances = LD_SpreadWindow.instances or {}

-- NeatUI if it happens to be installed, a plain border if not. nothing here depends on it.
function LD_SpreadWindow.frameTexture()
    if LD_SpreadWindow.frame == nil then
        LD_SpreadWindow.frame = getTexture("media/ui/NeatUI/Button/Boarder.png") or false
    end
    return LD_SpreadWindow.frame or nil
end

function LD_SpreadWindow.open(player, weapon)
    if not player or not weapon or not LDSpread.canSocket(weapon) then return nil end

    local playerNum = player:getPlayerNum()
    local existing = LD_SpreadWindow.instances[playerNum]
    if existing then existing:close() end

    local width = PAD * 2 + SLOT_W * 3 + GAP * 2
    local height = 400
    local x = getCore():getScreenWidth() / 2 - width / 2
    local y = getCore():getScreenHeight() / 2 - height / 2

    local window = LD_SpreadWindow:new(x, y, width, height, player, weapon)
    window:initialise()
    window:addToUIManager()
    window:setVisible(true)

    LD_SpreadWindow.instances[playerNum] = window
    return window
end

function LD_SpreadWindow.refreshAll()
    for _, window in pairs(LD_SpreadWindow.instances) do
        window:refresh()
    end
end

function LD_SpreadWindow:new(x, y, width, height, player, weapon)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.playerNum = player:getPlayerNum()
    o.weapon = weapon
    o.title = weapon:getName()
    o.resizable = false
    o.slots = {}

    return o
end

function LD_SpreadWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local y = self:titleBarHeight() + PAD

    for i, position in ipairs(LDArcana.POSITIONS) do
        local x = PAD + (i - 1) * (SLOT_W + GAP)
        local slot = LD_SpreadSlot:new(x, y, SLOT_W, CARD_H + LD_labelHeight(), self, position)
        slot:initialise()
        slot:instantiate()
        self:addChild(slot)
        self.slots[position] = slot
    end

    self.statsY = y + CARD_H + LD_labelHeight() + PAD
    self:refresh()

    -- the stats list is drawn, not built from children, so the window is sized to it here.
    local rows = math.ceil((#LDItem.STAT_ORDER + 1) / 2)
    self:setHeight(self.statsY + LD_fontHeight() + 4 + rows * ROW_H + PAD)
end

-- caches what the tooltips and the readout show, so neither is rebuilt every frame.
function LD_SpreadWindow:refresh()
    self.stats = LDItem.computeStats(self.weapon)
    self.title = self.weapon:getName()

    for position, slot in pairs(self.slots) do
        local card = LDSpread.cardAt(self.weapon, position)
        slot.tooltip = self:slotTooltipText(position, card)
    end
end

function LD_SpreadWindow:update()
    ISCollapsableWindow.update(self)

    if self.player:isDead() or not self.player:getInventory():containsRecursive(self.weapon) then
        self:close()
        return
    end

    -- a slow poll, so a change from anywhere else (the debug menu, a card carried over from
    -- a dismantle) shows up without every source having to know about this window.
    self.ticks = (self.ticks or 0) + 1
    if self.ticks >= 15 then
        self.ticks = 0
        self:refresh()
    end
end

function LD_SpreadWindow:close()
    LD_SpreadWindow.instances[self.playerNum] = nil
    self:removeFromUIManager()
    ISCollapsableWindow.close(self)
end

function LD_SpreadWindow:prerender()
    ISCollapsableWindow.prerender(self)

    local data = LDItem.get(self.weapon)
    if not data or not self.stats then return end

    local y = self.statsY
    local rarity = LDCore.rarity(data.rarity)
    local colour = rarity and rarity.color or { 220, 220, 220 }

    self:drawText(LDCore.rarityName(data.rarity) .. "  " .. tostring(data.pct or 100) .. "%",
        PAD, y, colour[1] / 255, colour[2] / 255, colour[3] / 255, 1, UIFont.Small)

    y = y + LD_fontHeight() + 4

    local lines = {}
    for _, stat in ipairs(LDItem.STAT_ORDER) do
        if self.stats[stat] ~= nil then
            lines[#lines + 1] = { LDCore.statName(stat), LDItem.formatNumber(self.stats[stat]) }
        end
    end

    local average = LDItem.averageCondition(self.stats)
    if average then
        lines[#lines + 1] = { LDCore.statName("averageCondition"), LDItem.formatNumber(average) }
    end

    local rows = math.ceil(#lines / 2)
    local columnWidth = (self.width - PAD * 2) / 2

    for i, line in ipairs(lines) do
        local column = i > rows and 1 or 0
        local row = i > rows and i - rows - 1 or i - 1
        local x = PAD + column * columnWidth
        local lineY = y + row * ROW_H

        local valueWidth = getTextManager():MeasureStringX(UIFont.Small, line[2])
        self:drawText(LD_fit(line[1], columnWidth - GAP * 2 - valueWidth), x, lineY, 0.62, 0.62, 0.62, 1, UIFont.Small)
        self:drawTextRight(line[2], x + columnWidth - GAP, lineY, 0.88, 0.88, 0.88, 1, UIFont.Small)
    end
end

local function LD_colour(good)
    return good and " <RGB:0.55,0.85,0.55> " or " <RGB:0.9,0.5,0.5> "
end

-- what a card does in a slot: its own words, then the arrows from its design.
function LD_SpreadWindow:cardEffectText(card, position)
    local slot = card[position]
    local lines = {}

    if slot.title then lines[#lines + 1] = " <RGB:0.98,0.82,0.45> " .. slot.title end
    if slot.text then lines[#lines + 1] = " <RGB:0.7,0.7,0.7> " .. slot.text end

    if LDArcana.slotIsEmpty(card, position) then
        lines[#lines + 1] = " <RGB:0.6,0.6,0.6> " .. LDCore.text("IGUI_LD_NoEffect", "No effect yet.")
        return table.concat(lines, " <LINE> ")
    end

    for _, mod in ipairs(LDArcana.modText(slot.mods)) do
        lines[#lines + 1] = LD_colour(mod.good) .. mod.text
    end

    return table.concat(lines, " <LINE> ")
end

function LD_SpreadWindow:slotTooltipText(position, card)
    if not card then
        return LDCore.text("IGUI_LD_SlotHint", "Empty. Right-click to socket a card.")
    end

    return " <RGB:1,1,1> " .. LDArcana.cardName(card.id)
        .. " <LINE> " .. self:cardEffectText(card, position)
end

-- the tooltip on a menu entry: what the card would do here, and the numbers it would move.
function LD_SpreadWindow:previewTooltip(position, cardId)
    local tooltip = ISInventoryPaneContextMenu.addToolTip()
    tooltip.maxLineWidth = 340

    local preview = LDArcana.preview(self.weapon, position, cardId)
    local lines = {}

    if cardId then
        lines[#lines + 1] = " <RGB:1,1,1> " .. LDArcana.cardName(cardId)
        lines[#lines + 1] = self:cardEffectText(LDArcana.card(cardId), position)
    else
        lines[#lines + 1] = " <RGB:1,1,1> " .. LDCore.text("IGUI_LD_TakeOut", "Take the card back out.")
    end

    if preview and #preview.rows > 0 then
        lines[#lines + 1] = " <LINE> "
        for _, row in ipairs(preview.rows) do
            lines[#lines + 1] = LD_colour(row.good) .. LDCore.statName(row.stat)
                .. "  " .. LDItem.formatNumber(row.from) .. " -> " .. LDItem.formatNumber(row.to)
        end
    end

    tooltip.description = table.concat(lines, " <LINE> ")
    return tooltip
end

-- ---------------------------------------------------------------------------------------
-- socketing
-- ---------------------------------------------------------------------------------------

-- card id -> { count, item }, for every tarot card the player is carrying, bags included.
function LD_SpreadWindow:carriedCards()
    local held = {}

    local found = self.player:getInventory():getAllEvalRecurse(function(item)
        return LDArcana.cardOfItem(item) ~= nil
    end, ArrayList.new())

    for i = 0, found:size() - 1 do
        local item = found:get(i)
        local id = LDArcana.cardOfItem(item).id
        local entry = held[id]

        if entry then
            entry.count = entry.count + 1
        else
            held[id] = { count = 1, item = item }
        end
    end

    return held
end

function LD_SpreadWindow:openSlotMenu(position)
    local context = ISContextMenu.get(self.playerNum, getMouseX(), getMouseY())
    if not context then return end

    local current = LDSpread.cardAt(self.weapon, position)
    if current then
        local option = context:addOption(
            LDCore.text("ContextMenu_LD_RemoveCard", "Remove %1", LDArcana.cardName(current.id)),
            self, LD_SpreadWindow.onSocket, position, nil)
        option.iconTexture = LDArcana.cardTexture(current.id)
        option.toolTip = self:previewTooltip(position, nil)
    end

    local held = self:carriedCards()
    local offered = 0

    for _, id in ipairs(LDArcana.activeCards()) do
        local entry = held[id]

        -- a card already on this weapon isn't offered again, in this slot or any other.
        if entry and not LDSpread.hasCard(self.weapon, id) then
            local label = LDArcana.cardName(id)
            if entry.count > 1 then label = label .. " (x" .. entry.count .. ")" end

            local option = context:addOption(label, self, LD_SpreadWindow.onSocket, position, entry.item)
            option.iconTexture = LDArcana.cardTexture(id)
            option.toolTip = self:previewTooltip(position, id)
            offered = offered + 1
        end
    end

    if offered == 0 then
        local option = context:addOption(LDCore.text("ContextMenu_LD_NoCards", "No tarot cards"))
        option.notAvailable = true
    end
end

function LD_SpreadWindow:onSocket(position, cardItem)
    if cardItem then ISInventoryPaneContextMenu.transferIfNeeded(self.player, cardItem) end
    ISTimedActionQueue.add(LD_SocketCardAction:new(self.player, self.weapon, position, cardItem))
end
