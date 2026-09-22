----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Deck"

if not LDCore.isAuthority() then return end

-- the zombie's inventory becomes the corpse's, so a deck added here is found by searching
-- the body like any other loot.
local function LD_onZombieDead(zombie)
    if not zombie then return end
    if ZombRandFloat(0, 100) >= LDDeck.LOOT.zombieDropChance then return end

    local inventory = zombie:getInventory()
    if inventory then inventory:AddItem(LDDeck.TYPE) end
end

Events.OnZombieDead.Add(LD_onZombieDead)
