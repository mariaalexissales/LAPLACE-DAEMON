----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Net"
require "LD_DebugMenu"
require "LD_Item"
require "LD_Craft"
require "LD_Arcana"
require "LD_Spread"
require "LD_Deck"
require "TimedActions/LD_SocketCardAction"
require "TimedActions/LD_DrawCardAction"

-- a self-test of the whole loop, run in the real game against the real code: draw from a
-- deck, forge a blade, put it on a handle and take it off, socket cards. every check prints
-- one "[LD TEST]" line to console.txt, and every item it makes is cleaned up at the end.
--
-- debug mode: right-click the ground -> LD: Run Playtest. or LDPlaytest.run() in the console.
--
-- what it can't cover: the crafting window itself (the craft handlers are handed the same
-- items a finished craft would give them), anything visual, and save/reload.

LDPlaytest = LDPlaytest or {}

local TAG = "[LD TEST] "
local EPSILON = 0.01
local SMITH_LEVEL = 9

local results = nil

-- the actions only ask now, and the work is the server's. with no remote server LD_Net
-- runs the handler on the spot, so these drive the same path a client's click does.
local function LD_socket(weapon, position, cardItem)
    LD_Net.toServer("socket", {
        weapon = weapon:getID(),
        position = position,
        card = cardItem and cardItem:getID() or nil,
    })
end

local function LD_draw(deck)
    LD_Net.toServer("draw", { deck = deck:getID() })
end

local function LD_check(name, ok, detail)
    if ok then
        results.pass = results.pass + 1
    else
        results.fail = results.fail + 1
    end

    local suffix = detail ~= nil and ("  (" .. tostring(detail) .. ")") or ""
    print(TAG .. (ok and "PASS  " or "FAIL  ") .. name .. suffix)
end

-- a section that throws counts as one failure rather than ending the run.
local function LD_section(name, fn)
    print(TAG .. "-- " .. name)
    local ok, err = pcall(fn)
    if not ok then LD_check(name .. " ran to the end", false, err) end
end

local function LD_near(a, b)
    return type(a) == "number" and type(b) == "number" and math.abs(a - b) < EPSILON
end

local function LD_n(value)
    return LDItem.formatNumber(value)
end

local function LD_arrayList(items)
    local list = ArrayList.new()
    for _, item in ipairs(items) do list:add(item) end
    return list
end

-- what a finished craft hands its handler. the handlers only ever ask for these two lists.
local function LD_craft(created, consumed)
    local createdList = LD_arrayList(created)
    local consumedList = LD_arrayList(consumed or {})

    return {
        getAllCreatedItems = function() return createdList end,
        getAllConsumedItems = function() return consumedList end,
    }
end

-- a crafter at a chosen blacksmith level, so the player's real skills are left alone.
local function LD_smith(level)
    return { getPerkLevel = function() return level end }
end

local function LD_count(inventory, fullType)
    return inventory:getAllEvalRecurse(function(item)
        return item:getFullType() == fullType
    end, ArrayList.new()):size()
end

local function LD_tally(level, rolls)
    local weights = LDItem.weightsFor(level)
    local counts = {}

    for _ = 1, rolls do
        local id = LDItem.rollRarity(weights)
        counts[id] = (counts[id] or 0) + 1
    end

    local parts = {}
    for _, id in ipairs(LDCore.RARITY_ORDER) do
        if counts[id] then parts[#parts + 1] = id .. " " .. counts[id] end
    end

    return counts, table.concat(parts, ", ")
end

function LDPlaytest.run(player)
    player = player or getSpecificPlayer(0)
    if not player then
        print(TAG .. "no player to test with")
        return nil
    end

    results = { pass = 0, fail = 0 }
    local inventory = player:getInventory()

    -- whatever the player already carries, so the cleanup only takes what the test made.
    local kept = {}
    local carried = inventory:getItems()
    for i = 0, carried:size() - 1 do kept[carried:get(i):getID()] = true end

    print(TAG .. "start. forging at blacksmith " .. SMITH_LEVEL .. ", active cards: "
        .. table.concat(LDArcana.activeCards(), ", "))

    local blade, sword = nil, nil

    LD_section("blades only", function()
        local probeSword = inventory:AddItem("Base.Sword")
        local probeCleaver = inventory:AddItem("Base.MeatCleaverForged")
        local probeBlade = inventory:AddItem("Base.SwordBlade")
        local probeBar = inventory:AddItem("Base.IronBarQuarter")

        LD_check("a sword counts as bladed", LDItem.isBladed(probeSword))
        LD_check("a meat cleaver doesn't, the game files it as an axe", not LDItem.isBladed(probeCleaver))
        LD_check("a sword blade can roll", LDItem.isRollable(probeBlade))
        LD_check("a leftover iron bar can't", not LDItem.isRollable(probeBar))
        LD_check("meat cleaver blade forging is off", LDCore.Recipes.Forge_Meat_Cleaver_Blade == nil)
        LD_check("crude knives carry the roll onto their handle", LDCore.Recipes.MakeCrudeKnife == "carry")
    end)

    LD_section("rarity odds", function()
        local low, lowText = LD_tally(0, 2000)
        LD_check("blacksmith 0 only rolls common and uncommon",
            not low.RARE and not low.EPIC and not low.LEGENDARY, lowText)

        local high, highText = LD_tally(10, 2000)
        local every = true
        for _, id in ipairs(LDCore.RARITY_ORDER) do
            if not high[id] then every = false end
        end
        LD_check("blacksmith 10 rolls all five rarities", every, highText)
    end)

    LD_section("forge", function()
        blade = inventory:AddItem("Base.SwordBlade")
        local leftover = inventory:AddItem("Base.IronBarQuarter")

        LDCore.CraftHandlers.forge(LD_craft({ blade, leftover }), LD_smith(SMITH_LEVEL))

        local data = LDItem.get(blade)
        LD_check("the forged blade has a rarity", data ~= nil and LDCore.rarity(data.rarity) ~= nil,
            data and (tostring(data.rarity) .. " " .. tostring(data.pct) .. "%"))
        if not data then return end

        local range = LDCore.rarity(data.rarity).pct
        LD_check("its damage roll is inside that rarity's range",
            data.pct >= range[1] and data.pct <= range[2], data.pct .. " in " .. range[1] .. "-" .. range[2])
        LD_check("it remembers the blacksmith level", data.level == SMITH_LEVEL, data.level)
        LD_check("the leftover bar wasn't stamped", LDItem.get(leftover) == nil)
        LD_check("the name carries the rarity",
            string.find(blade:getName(), LDCore.rarityName(data.rarity), 1, true) ~= nil, blade:getName())
    end)

    LD_section("handle on, handle off", function()
        local from = blade and LDItem.get(blade)
        if not from then
            LD_check("there's a forged blade to put on a handle", false)
            return
        end

        local handle = inventory:AddItem("Base.SmallHandle")
        sword = inventory:AddItem("Base.Sword")
        LDCore.CraftHandlers.carry(LD_craft({ sword }, { blade, handle }))

        local to = LDItem.get(sword)
        LD_check("the sword kept the blade's rarity", to ~= nil and to.rarity == from.rarity,
            to and to.rarity)
        if not to then return end

        LD_check("and the same damage roll, no reroll", to.pct == from.pct, to.pct .. "%")
        LD_check("the handle wasn't stamped", LDItem.get(handle) == nil)
        LD_check("the name carries the rarity",
            string.find(sword:getName(), LDCore.rarityName(to.rarity), 1, true) ~= nil, sword:getName())

        local base = LDItem.baseStats(sword:getFullType())
        local expected = base.maxDamage * to.pct / 100
        LD_check("max damage is vanilla x the roll", LD_near(sword:getMaxDamage(), expected),
            LD_n(sword:getMaxDamage()) .. " = " .. LD_n(base.maxDamage) .. " x " .. to.pct .. "%")

        local offAgain = inventory:AddItem("Base.SwordBlade")
        LDCore.CraftHandlers.carry(LD_craft({ offAgain }, { sword }))
        local back = LDItem.get(offAgain)
        LD_check("taking it off the handle keeps the same roll", back ~= nil and back.pct == to.pct)

        local cleaver = inventory:AddItem("Base.MeatCleaverForged")
        LDCore.CraftHandlers.carry(LD_craft({ cleaver }, { blade }))
        LD_check("a meat cleaver never picks up a rarity", LDItem.get(cleaver) == nil)
    end)

    LD_section("the deck", function()
        local list = ProceduralDistributions and ProceduralDistributions.list
        local smithy = list and list.BlacksmithTools and list.BlacksmithTools.items
        local inLoot = false
        if smithy then
            for _, entry in ipairs(smithy) do
                if entry == LDDeck.TYPE then inLoot = true end
            end
        end
        LD_check("decks are in the blacksmith loot table", inLoot)
        LD_check("zombies have a chance to carry one", (LDDeck.LOOT.zombieDropChance or 0) > 0,
            LDDeck.LOOT.zombieDropChance .. "%")

        local before = {}
        for _, id in ipairs(LDArcana.activeCards()) do
            before[id] = LD_count(inventory, LDArcana.card(id).itemType)
        end

        local deck = inventory:AddItem(LDDeck.TYPE)
        local draw = LD_DrawCardAction:new(player, deck)
        LD_check("a carried deck can be drawn from", draw:isValid())
        LD_draw(deck)

        LD_check("the deck is gone after the draw", not inventory:containsRecursive(deck))

        local gained, drawn = 0, nil
        for _, id in ipairs(LDArcana.activeCards()) do
            local difference = LD_count(inventory, LDArcana.card(id).itemType) - before[id]
            gained = gained + difference
            if difference > 0 then drawn = id end
        end
        LD_check("exactly one active card came out of it", gained == 1, drawn)
    end)

    LD_section("sockets", function()
        if not sword or not LDItem.get(sword) then
            LD_check("there's a forged sword to socket into", false)
            return
        end

        local function give(id) return inventory:AddItem(LDArcana.card(id).itemType) end
        local emperor, emperor2 = give("EMPEROR"), give("EMPEROR")
        local chariot, death, temperance = give("CHARIOT"), give("DEATH"), give("TEMPERANCE")

        local rolled = LDItem.computeStats(sword)
        local preview = LDArcana.preview(sword, "present", "EMPEROR")
        local promised = preview and preview.after

        LD_check("the Emperor in Present previews more max damage",
            promised ~= nil and promised.maxDamage > rolled.maxDamage,
            promised and (LD_n(rolled.maxDamage) .. " -> " .. LD_n(promised.maxDamage)))
        if not promised then return end

        LD_check("more knockback", promised.knockback > rolled.knockback,
            LD_n(rolled.knockback) .. " -> " .. LD_n(promised.knockback))
        LD_check("and slower swings", promised.baseSpeed < rolled.baseSpeed,
            LD_n(rolled.baseSpeed) .. " -> " .. LD_n(promised.baseSpeed))

        local socket = LD_SocketCardAction:new(player, sword, "present", emperor)
        LD_check("socketing it is allowed", socket:isValid())
        LD_socket(sword, "present", emperor)

        LD_check("the card left the inventory", not inventory:containsRecursive(emperor))
        LD_check("the Emperor sits in Present", (LDSpread.get(sword) or {}).present == "EMPEROR")
        LD_check("the sword got what the preview promised", LD_near(sword:getMaxDamage(), promised.maxDamage),
            LD_n(sword:getMaxDamage()) .. " vs " .. LD_n(promised.maxDamage))

        LD_check("a second Emperor can't go in Past",
            not LD_SocketCardAction:new(player, sword, "past", emperor2):isValid())

        print(TAG .. "(the WARN on the next line is expected)")
        LD_check("a switched-off card can't be socketed", not LDSpread.socket(sword, "past", "FOOL"))

        local emperors = LD_count(inventory, LDArcana.card("EMPEROR").itemType)
        LD_socket(sword, "present", chariot)
        LD_check("the Chariot replaced it", LDSpread.get(sword).present == "CHARIOT")
        LD_check("and the Emperor came back", LD_count(inventory, LDArcana.card("EMPEROR").itemType) == emperors + 1)

        LD_socket(sword, "past", death)
        LD_socket(sword, "future", temperance)
        local spread = LDSpread.get(sword)
        LD_check("all three slots are filled",
            spread.past == "DEATH" and spread.present == "CHARIOT" and spread.future == "TEMPERANCE")

        local full = LDItem.computeStats(sword)
        LD_check("Temperance made it lighter", full.weight < rolled.weight,
            LD_n(rolled.weight) .. " -> " .. LD_n(full.weight))
        LD_check("and slower to wear out", full.conditionLowerChance > rolled.conditionLowerChance,
            "1 in " .. LD_n(rolled.conditionLowerChance) .. " -> 1 in " .. LD_n(full.conditionLowerChance))

        local once = LDItem.applyStats(sword)
        local twice = LDItem.applyStats(sword)
        local same = true
        for stat in pairs(LDItem.STATS) do
            if once[stat] ~= twice[stat] and not LD_near(once[stat], twice[stat]) then same = false end
        end
        LD_check("refreshing twice changes nothing", same)

        local temperances = LD_count(inventory, LDArcana.card("TEMPERANCE").itemType)
        LD_socket(sword, "future", nil)
        LD_check("Temperance came back out",
            LDSpread.get(sword).future == nil
                and LD_count(inventory, LDArcana.card("TEMPERANCE").itemType) == temperances + 1)

        -- Death in Past raised max condition. fill it to the top, then take Death out.
        sword:setCondition(sword:getConditionMax())
        LD_socket(sword, "past", nil)
        LD_check("condition never sits above the max", sword:getCondition() <= sword:getConditionMax(),
            sword:getCondition() .. " / " .. sword:getConditionMax())
    end)

    -- clean up everything the test made, in one pass after it's done using them.
    local made = {}
    carried = inventory:getItems()
    for i = 0, carried:size() - 1 do
        local item = carried:get(i)
        if not kept[item:getID()] then made[#made + 1] = item end
    end
    for _, item in ipairs(made) do inventory:Remove(item) end

    local summary = results.pass .. " passed, " .. results.fail .. " failed"
    print(TAG .. "done. " .. summary .. ". cleaned up " .. #made .. " test items.")

    if HaloTextHelper then
        local good = results.fail == 0
        HaloTextHelper.addText(player, "LD playtest: " .. summary, "[br/]",
            good and 120 or 230, good and 220 or 90, good and 120 or 90)
    end

    return results
end

local function LD_onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test then return end

    local player = getSpecificPlayer(playerNum)
    if not player or not LD_DebugMenu.allowed(player) then return end

    context:addOption("LD: Run Playtest", player, LDPlaytest.run)
end

Events.OnFillWorldObjectContextMenu.Add(LD_onFillWorldObjectContextMenu)
