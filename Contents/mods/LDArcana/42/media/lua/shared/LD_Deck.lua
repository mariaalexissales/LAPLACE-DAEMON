----------
--ESTRAL--
----------

require "LD_Core"
require "LD_Arcana"

LDDeck = LDDeck or {}

-- the vanilla deck is where cards come from. you pull from the top, and the rest of it goes,
-- as if the universe took it back.
LDDeck.TYPE = "Base.TarotCardDeck"

-- placeholder numbers, all in one place.
LDDeck.LOOT = {
    -- vanilla already puts the deck in occult and new age bookstores, comic store counters,
    -- kids' rooms and hobby shelves. these are on top of that. vanilla's own weights for it
    -- run from 0.1 to 8.
    tables = {
        -- the forge the blades come out of
        BlacksmithTools                = 1,
        CrateBlacksmithing             = 1,
        WildWestBlacksmith             = 2,
        CrateMetalwork                 = 0.5,

        -- the occult and the old
        LibraryOccult                  = 2,
        LibraryNewAge                  = 2,
        UniversityDesk_Occult          = 3,
        UniversityFilingCabinet_Occult = 2,
        Antiques                       = 2,
        PawnShopCases                  = 1,
        GiftStoreFancy                 = 1,
        CarnivalPrizes                 = 2,
        ChurchStorageMisc              = 0.5,

        -- anyone's house
        BedroomDresser                 = 0.3,
        BedroomSidetable               = 0.3,
        LivingRoomShelf                = 0.2,
        DeskGeneric                    = 0.2,
        CrateRandomJunk                = 0.2,
    },

    -- percent chance that a zombie is carrying one.
    zombieDropChance = 0.5,
}

function LDDeck.isDeck(item)
    return item ~= nil and item:getFullType() == LDDeck.TYPE
end

-- one of the active cards, each as likely as the next.
function LDDeck.drawId()
    local active = LDArcana.activeCards()
    if #active == 0 then return nil end

    return active[ZombRand(#active) + 1]
end

-- the card's name over the player's head, then the deck going.
function LDDeck.announce(player, cardId)
    if not HaloTextHelper or not player then return end

    HaloTextHelper.addText(player, LDArcana.cardName(cardId), "[br/]", 250, 210, 115)
    HaloTextHelper.addText(player, LDCore.text("IGUI_LD_DeckGone", "The rest of the deck is gone."))
end
