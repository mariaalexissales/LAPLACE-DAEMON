----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Net"
require "LD_Rarities"
require "LD_Item"

if not LDCore.isAuthority() then return end

LD_Commands = LD_Commands or {}
LD_Commands.handlers = LD_Commands.handlers or {}

-- runtime only. a rate limit has no business surviving a restart or sitting in the save.
local ledgers = {}

function LD_Commands.cooledDown(name, player, window)
    -- the limit is there to stop a remote client flooding the server. with no wire there is
    -- nothing to flood, and throttling a singleplayer game would only ever be a bug.
    if not LDCore.hasRemoteServer() then return true end

    local ledger = ledgers[name]
    if not ledger then
        ledger = {}
        ledgers[name] = ledger
    end

    local who = tostring(player and player:getUsername())
    local now = getTimestampMs()
    if now - (ledger[who] or 0) < window then return false end

    ledger[who] = now
    return true
end

-- an id off the wire is only ever a key into the server's own copy of that player's
-- inventory, so a crafted packet can't name something the player isn't carrying.
function LD_Commands.heldItem(player, id)
    id = tonumber(id)
    if not id or not player then return nil end

    local found = player:getInventory():getAllEvalRecurse(function(item)
        return item:getID() == id
    end, ArrayList.new())

    return found:size() > 0 and found:get(0) or nil
end

-- the item's own container, not the main inventory: a card in a backpack lives in the backpack.
function LD_Commands.remove(player, item)
    local container = item:getContainer()
    if not container then return false end

    player:removeFromHands(item)

    sendRemoveItemFromContainer(container, item)
    container:Remove(item)

    return true
end

function LD_Commands.add(inventory, fullType)
    local item = inventory:AddItem(fullType)
    if not item then return nil end

    sendAddItemToContainer(inventory, item)
    return item
end

-- debug only, and the client is the one drawing the button, so it is checked again here.
function LD_Commands.handlers.stamp(player, args)
    if not LDCore.isAdmin(player) then
        LDCore.warn(tostring(player and player:getUsername()) .. " asked for a stamp without permission")
        return
    end

    if not args or not LDCore.rarity(args.rarity) then return end

    local item = LD_Commands.heldItem(player, args.item)
    if not item then return end

    LDItem.stamp(item, LDItem.newData(args.rarity, LDItem.rollPct(args.rarity), args.level or 0))
    LDItem.sync(player, item)
end

local function LD_onClientCommand(module, command, player, args)
    if module ~= LDCore.MODULE then return end

    local handler = LD_Commands.handlers[command]
    if not handler then return end

    local ok, err = pcall(handler, player, args)
    if not ok then LDCore.warn("command " .. tostring(command) .. " failed: " .. tostring(err)) end
end

Events.OnClientCommand.Add(LD_onClientCommand)
