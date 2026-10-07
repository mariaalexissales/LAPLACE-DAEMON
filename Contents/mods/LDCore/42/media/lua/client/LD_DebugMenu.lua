----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Net"
require "LD_Item"

LD_DebugMenu = LD_DebugMenu or {}

-- debug mode is a switch on the client, which is nobody's business but their own in
-- singleplayer and everybody's on a server. the commands behind these options check again,
-- because this side is the one drawing the button.
function LD_DebugMenu.allowed(player)
    if not isDebugEnabled() then return false end
    return not LDCore.hasRemoteServer() or LDCore.isAdmin(player)
end

-- the menu hands back bare items for singles and { items = {...} } for stacks, where the
-- first entry repeats the second.
function LD_DebugMenu.flatten(items)
    local out = {}

    for _, entry in ipairs(items) do
        if instanceof(entry, "InventoryItem") then
            out[#out + 1] = entry
        elseif type(entry) == "table" and entry.items then
            local first = #entry.items > 1 and 2 or 1
            for i = first, #entry.items do out[#out + 1] = entry.items[i] end
        end
    end

    return out
end

function LD_DebugMenu.inspect(item)
    LDCore.log("inspect " .. item:getFullType() .. " \"" .. item:getName() .. "\"")

    local data = LDItem.get(item)
    if data then
        for _, line in ipairs(LDItem.describe(data, "  ")) do LDCore.log(line) end
    else
        LDCore.log("  no LD data")
    end

    if instanceof(item, "HandWeapon") then
        local base = LDItem.baseStats(item:getFullType())
        LDCore.log("  damage " .. item:getMinDamage() .. " - " .. item:getMaxDamage()
            .. (base and (" (vanilla " .. base.minDamage .. " - " .. base.maxDamage .. ")") or ""))
    end

    if instanceof(item, "Clothing") then
        local base = LDItem.baseStats(item:getFullType())
        LDCore.log("  bite / scratch / bullet " .. item:getBiteDefense() .. " / "
            .. item:getScratchDefense() .. " / " .. item:getBulletDefense()
            .. (base and (" (vanilla " .. base.biteDefense .. " / " .. base.scratchDefense
                .. " / " .. base.bulletDefense .. ")") or ""))
        LDCore.log("  condition " .. item:getCondition() .. " / " .. item:getConditionMax())
    end
end

-- stamps a chosen rarity without going near a forge, for testing names, stats and cards. the
-- roll is the server's like any other, so Inspect afterwards rather than expecting this to
-- have landed by the time the menu closes.
function LD_DebugMenu.stamp(item, rarityId, player)
    local level = player and player:getPerkLevel(Perks.Blacksmith) or 0
    LD_Net.toServer("stamp", { item = item:getID(), rarity = rarityId, level = level })
end

local function LD_onFillInventoryObjectContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player or not LD_DebugMenu.allowed(player) then return end

    local item = nil
    for _, entry in ipairs(LD_DebugMenu.flatten(items)) do
        if LDItem.get(entry) or LDItem.isRollable(entry) then
            item = entry
            break
        end
    end
    if not item then return end

    context:addOption("LD: Inspect", item, LD_DebugMenu.inspect)

    local stampOption = context:addOption("LD: Stamp As")
    local stampMenu = context:getNew(context)
    context:addSubMenu(stampOption, stampMenu)

    for _, id in ipairs(LDCore.RARITY_ORDER) do
        stampMenu:addOption(LDCore.rarityName(id), item, LD_DebugMenu.stamp, id, player)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(LD_onFillInventoryObjectContextMenu)
