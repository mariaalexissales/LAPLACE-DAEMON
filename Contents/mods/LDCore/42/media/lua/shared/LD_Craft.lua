----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Item"
require "Entity/TimedActions/ISHandcraftAction"

-- recipe name -> role.
--   forge: roll a fresh rarity onto what it makes.
--   carry: copy the roll from what it uses up onto what it makes. never rolls again, so
--          dismantling and reassembling can't be used to reroll.
LDCore.Recipes = {
    Forge_Crude_Blade            = "forge",
    Forge_Small_Knife            = "forge",
    Forge_Long_Crude_Blade       = "forge",
    Forge_Scrap_Shortsword       = "forge",
    Forge_Scrap_Sword            = "forge",
    Forge_Crude_Shortsword_Blade = "forge",
    Forge_Large_Knife_Blade      = "forge",
    Forge_Crude_Sword_Blade      = "forge",
    Forge_Kitchen_Knife_Blade    = "forge",
    Forge_Hunting_Knife_Blade    = "forge",
    ForgeHandguardDagger         = "forge",
    Forge_ShortSwordBlade        = "forge",
    Forge_Sword_Blade            = "forge",
    Forge_Machete_Blade          = "forge",

    -- blades only for now. spear heads would lose the roll going on a shaft, and the meat
    -- cleaver is an axe to the game.
    -- ForgeSpearHead            = "forge",
    -- ForgeLongSpearHead        = "forge",
    -- Forge_Meat_Cleaver_Blade  = "forge",

    AssembleBlade                = "carry",
    DismantleBlade               = "carry",
    -- the crude blade and long crude blade go on their handle here, not in AssembleBlade.
    MakeCrudeKnife               = "carry",
}

-- same signature as a script OnCreate, (craftRecipeData, character). if the wrap below ever
-- stops working, these can be pointed at from the recipe scripts unchanged.
LDCore.CraftHandlers = LDCore.CraftHandlers or {}

local function LD_list(arrayList)
    local out = {}
    if not arrayList then return out end

    for i = 0, arrayList:size() - 1 do out[#out + 1] = arrayList:get(i) end
    return out
end

-- only for the hook ctx. pcall because the getter name on CraftRecipeData isn't confirmed,
-- and a missing recipe shouldn't cost the roll.
local function LD_recipeOf(craftRecipeData)
    local ok, recipe = pcall(function() return craftRecipeData:getRecipe() end)
    return ok and recipe or nil
end

-- recipe is passed by the wrap below; a script OnCreate wouldn't pass it.
function LDCore.CraftHandlers.forge(craftRecipeData, character, recipe)
    recipe = recipe or LD_recipeOf(craftRecipeData)
    local level = character and character:getPerkLevel(Perks.Blacksmith) or 0

    for _, item in ipairs(LD_list(craftRecipeData:getAllCreatedItems())) do
        if LDItem.isRollable(item) then
            local weighed = LDCore.Hooks.run(LDCore.HOOK.FORGE_WEIGHTS, {
                player = character,
                level = level,
                recipe = recipe,
                item = item,
                weights = LDItem.weightsFor(level),
            })

            local rarity = LDItem.rollRarity(weighed.weights)

            local rolled = LDCore.Hooks.run(LDCore.HOOK.FORGE_ROLLED, {
                player = character,
                level = level,
                recipe = recipe,
                item = item,
                data = LDItem.newData(rarity, LDItem.rollPct(rarity), level),
            })

            LDItem.stamp(item, rolled.data)
            LDCore.log("forged " .. item:getFullType() .. " at blacksmith " .. level
                .. ": " .. tostring(rolled.data.rarity) .. " " .. tostring(rolled.data.pct) .. "%")
        end
    end
end

function LDCore.CraftHandlers.carry(craftRecipeData, character)
    local source = nil
    for _, item in ipairs(LD_list(craftRecipeData:getAllConsumedItems())) do
        if LDItem.get(item) then
            source = item
            break
        end
    end

    -- a found vanilla blade or weapon. nothing to carry, and it stays vanilla.
    if not source then return end

    for _, item in ipairs(LD_list(craftRecipeData:getAllCreatedItems())) do
        if LDItem.isRollable(item) and LDItem.copy(source, item) then
            LDItem.refresh(item)
            LDCore.log("carried " .. source:getFullType() .. " -> " .. item:getFullType())
        end
    end
end

-- ---------------------------------------------------------------------------------------
-- there's no craft event, and every handcraft ends in ISHandcraftAction:performRecipe. the
-- original adds the outputs and processes the used inputs; getAllConsumedItems still lists
-- them afterwards (vanilla reads it there too), so the blade's data is still readable.
--
-- multiplayer: this runs on the server after the outputs were already handed to the client,
-- so the data will need syncing (syncItemModData / syncItemFields) before MP is supported.
-- ---------------------------------------------------------------------------------------

-- kept on LDCore so reloading this file in debug doesn't wrap the wrap.
LDCore.originalPerformRecipe = LDCore.originalPerformRecipe or ISHandcraftAction.performRecipe

function ISHandcraftAction:performRecipe()
    LDCore.originalPerformRecipe(self)

    local data = self.logic and self.logic:getRecipeData()
    if not data then return end

    local recipe = self.craftRecipe or self.logic:getRecipe()
    local name = recipe and recipe:getName()
    local handler = name and LDCore.CraftHandlers[LDCore.Recipes[name] or ""]

    if not handler then
        if isDebugEnabled() then LDCore.log("craft " .. tostring(name) .. " (no LD role)") end
        return
    end

    if data:getAllCreatedItems():size() == 0 then return end

    local ok, err = pcall(handler, data, self.character, recipe)
    if not ok then LDCore.warn("craft handler for " .. name .. " failed: " .. tostring(err)) end
end
