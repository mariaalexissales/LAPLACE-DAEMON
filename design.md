LAPLACE//DAEMON
│
├── LDCore/42/media/lua/
│ ├── shared/
│ │ ├── LD_Core.lua        namespace, text helper, hook bus (LDCore.HOOK, LDCore.Hooks)
│ │ ├── LD_Rarities.lua    rarity table, damage pct ranges, weights per Blacksmith level
│ │ ├── LD_Item.lua        item data, rolls, stats and name (the RPG item layer)
│ │ ├── LD_Craft.lua       recipe roles (forge / carry), handcraft wrap
│ │ └── LD_Events.lua      equip, load and hit events -> hooks
│ └── client/
│   └── LD_DebugMenu.lua   debug: inspect, stamp as rarity
│
├── LDArcana/42/media/                requires LDCore
│ ├── scripts/LDA_items.txt   GENERATED: LDArcana.Tarot_<ID>, one item per card
│ ├── textures/               GENERATED: 64x64 icons, Item_LD_Tarot_<ID>.png
│ ├── ui/LDArcana/            GENERATED: 102x158 window art, Tarot_<ID>.png
│ ├── lua/shared/Translate/EN/ItemName.json  GENERATED: card names
│ └── lua/
│ ├── shared/
│ │ ├── LD_Arcana.lua      card registry, STEPS, define(), mods, preview
│ │ ├── LD_Spread.lua      socket / unsocket / each, one card per weapon
│ │ ├── LD_ArcanaHooks.lua one dispatcher per effect, past -> present -> future
│ │ ├── LD_Deck.lua        the vanilla deck as the card source, loot + drop numbers
│ │ ├── LD_Major/          one file per card (LD_Major_00_Fool.lua holds the format)
│ │ └── TimedActions/      LD_SocketCardAction (card in / out), LD_DrawCardAction
│ ├── server/
│ │ ├── LD_DeckLoot.lua    the deck in the extra loot tables
│ │ └── LD_DeckDrops.lua   the deck on zombies
│ └── client/
│   ├── LD_SpreadWindow.lua     the three slots, previews, socket menu
│   ├── LD_SpreadMenu.lua       inventory right-click -> Tarot Spread
│   ├── LD_DeckMenu.lua         inventory right-click on a deck -> Draw a Card
│   ├── LD_Playtest.lua         debug: right-click the ground -> LD: Run Playtest
│   └── LD_ArcanaDebugMenu.lua  debug: socket any card without owning it
│
├── tools/
│ └── build_tarot.ps1   bakes the Tarot Cards [Free] zip into icons, writes items + names
│
├── UI/
│ └── NeatUI integration

# Core

## Rarity
Forging rolls a rarity from `LDCore.RarityWeights[blacksmith level]`, then a damage pct inside
that rarity's `pct` range. Min and max damage are the vanilla weapon's times the pct.

The roll happens once, at the forge. Putting the blade on a handle (`AssembleBlade`) and
taking it off (`DismantleBlade`) copy the item's LD data and never roll again.

Item data, in modData under `LD`:

    { v = 1, rarity = "RARE", pct = 137, level = 6, arcana = { past = "TOWER" } }

## Hooks
Core fires these with a ctx table and never knows who listens.

| hook            | when                               | change          |
|-----------------|------------------------------------|-----------------|
| `forge.weights` | before the rarity roll             | `ctx.weights`   |
| `forge.rolled`  | after the roll, before it's saved  | `ctx.data`      |
| `item.stats`    | every stat rebuild                 | `ctx.stats`     |
| `weapon.equip`  | equip in either hand, and on load  |                 |
| `weapon.hit`    | the weapon hits a character        |                 |

# Arcana

A weapon has three slots: Past, Present, Future. A card is one card in three readings: its
stats come from its Arcana, and the slot decides how they manifest.

    LDArcana.define("EMPEROR", {
        area = "Power", theme = "Authority, force, dominance",
        stats = { "minDamage", "maxDamage", "knockback" },
        present = { title = "Force", text = "Everything goes into this strike.",
                    mods = { maxDamage = 2, knockback = 1, baseSpeed = -1 } },
    })

`mods` are the design's arrows: 1 up, 2 double up, -1 down, read in the stat's own direction.
One arrow is worth what `LDArcana.STEPS` says, as a share of the weapon after its rarity roll,
so a card is worth more on a legendary. Stat keys are the ones in `LDItem.STATS`, plus
`averageCondition`, which leans on max condition and condition lower chance together.

A slot can also hold a function named after an `LDArcana.EFFECT_HOOKS` entry (`stats`,
`equip`, `hit`) for anything the arrows can't say. A `stats` function must be pure: the socket
menu runs it to preview a card it hasn't socketed.

Cards are items (`LDArcana.Tarot_<ID>`). Socketing takes one out of the inventory; removing or
replacing one hands it back. The same card can only be on a weapon once.

Only the cards in `LDArcana.ACTIVE` exist in play: Emperor, Chariot, Death, Temperance. The
rest keep their files and art but have no item. `tools/build_tarot.ps1` reads the list, so a
card goes live by adding it there and re-running the tool.

## Where cards come from
The vanilla Tarot Card Deck. Right-click it, Draw a Card: you pull from the top of the deck,
and the rest of it goes, as if the universe took it back. One random active card, and the deck
is gone. The deck spawns where vanilla puts it, plus the extra tables and the zombie drop
chance in `LDDeck.LOOT` (`LD_Deck.lua`).

# Scope
Blades only: weapons the game files as long blade or small blade, and the blades that go on
their handles. The meat cleaver and the hand scythe are axes to the game, and spear heads lose
the roll on a shaft, so all three stay vanilla for now.
