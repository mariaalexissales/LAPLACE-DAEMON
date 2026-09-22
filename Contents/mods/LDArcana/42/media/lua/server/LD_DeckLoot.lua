----------
--ESTRAL--
----------

require "Items/ProceduralDistributions"
require "LD_Core"
require "LD_Deck"

local ProceduralDistributions_list = ProceduralDistributions.list
local table_insert = table.insert

-- the vanilla deck, in the extra places listed on LDDeck.LOOT. vanilla's own spots are left
-- as they are.
for tableName, weight in pairs(LDDeck.LOOT.tables) do
    local distribution = ProceduralDistributions_list[tableName]
    local items = distribution and distribution.items

    if items then
        table_insert(items, LDDeck.TYPE)
        table_insert(items, weight)
    else
        LDCore.warn("loot table " .. tableName .. " not found, skipped")
    end
end
