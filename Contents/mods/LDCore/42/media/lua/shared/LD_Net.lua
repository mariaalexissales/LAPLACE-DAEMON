----------
--ESTRAL--
----------

require "LD_Core"

LD_Net = LD_Net or {}

-- looked up at call time: shared/ loads before client/ and server/, so neither dispatcher
-- exists yet when this file runs.
local function LD_serverHandler(command)
    return LD_Commands and LD_Commands.handlers and LD_Commands.handlers[command]
end

local function LD_clientHandler()
    return LD_ClientState and LD_ClientState.onCommand
end

-- the no-remote-server tail of both toClient and toAll: with nobody to send to, one client and
-- every client are the same client.
local function LD_dispatchLocal(player, command, args)
    local handler = LD_clientHandler()
    if not handler then return end

    -- splitscreen: the handler needs to know which of the local players this was for.
    args.playerNum = player and player:getPlayerNum() or 0

    local ok, err = pcall(handler, LDCore.MODULE, command, args)
    if not ok then LDCore.warn("client handler " .. tostring(command) .. " failed: " .. tostring(err)) end
end

-- with no remote server the send is a direct call into the handler that would have received
-- it, so singleplayer runs the same rolling, socketing and drawing code the server does.
function LD_Net.toServer(command, args)
    args = args or {}

    if LDCore.hasRemoteServer() then
        -- nil this early on a multiplayer client, and handing nil to sendClientCommand loses
        -- the packet without a word. say so, and let the caller retry.
        local player = getPlayer()
        if not player then
            LDCore.warn("no local player yet, dropped " .. tostring(command))
            return
        end

        sendClientCommand(player, LDCore.MODULE, command, args)
        return
    end

    local handler = LD_serverHandler(command)
    if not handler then
        LDCore.warn("no server handler for " .. tostring(command))
        return
    end

    local ok, err = pcall(handler, getPlayer(), args)
    if not ok then LDCore.warn("server handler " .. tostring(command) .. " failed: " .. tostring(err)) end
end

function LD_Net.toClient(player, command, args)
    args = args or {}

    if isServer() then
        sendServerCommand(player, LDCore.MODULE, command, args)
        return
    end

    LD_dispatchLocal(player, command, args)
end

function LD_Net.toAll(command, args)
    args = args or {}

    if isServer() then
        sendServerCommand(LDCore.MODULE, command, args)
        return
    end

    LD_dispatchLocal(getPlayer(), command, args)
end
