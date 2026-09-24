----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Arcana"
require "LD_Deck"

LD_ClientState = LD_ClientState or {}

local handlers = {}

-- splitscreen: the server said who this was for, and in singleplayer LD_Net fills it in.
local function LD_player(args)
    local player = args and args.playerNum and getSpecificPlayer(args.playerNum)
    return player or getPlayer()
end

function handlers.drawn(player, args)
    LDDeck.announce(player, args.card)
end

function handlers.socketed(player, args)
    if LD_SpreadWindow then LD_SpreadWindow.refreshAll() end
end

function handlers.refused(player, args)
    local key = "IGUI_LD_Refused_" .. tostring(args.reason)
    HaloTextHelper.addBadText(player, LDCore.text(key, "Can't do that right now"))

    -- the window offered it, so it is the thing that is out of date.
    if LD_SpreadWindow then LD_SpreadWindow.refreshAll() end
end

-- MP: OnServerCommand. SP: LD_Net.toClient calls this directly.
function LD_ClientState.onCommand(module, command, args)
    if module ~= LDCore.MODULE then return end

    local handler = handlers[command]
    if not handler then return end

    args = args or {}
    local player = LD_player(args)
    if not player then return end

    handler(player, args)
    pcall(function() ISInventoryPage.dirtyUI() end)
end

Events.OnServerCommand.Add(function(module, command, args)
    if module ~= LDCore.MODULE then return end

    local ok, err = pcall(LD_ClientState.onCommand, module, command, args)
    if not ok then LDCore.warn("client command " .. tostring(command) .. " failed: " .. tostring(err)) end
end)
