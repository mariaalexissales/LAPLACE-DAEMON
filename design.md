LAPLACE//DAEMON
│
├── LDCore/42/media/
│ ├── actiongroups/, AnimSets/   placeholders so a dedicated server's media scan finds them
│ └── lua/
│   ├── shared/
│   │ ├── LD_Core.lua        namespace, text helper, hook bus (LDCore.HOOK, LDCore.Hooks)
│   │ ├── LD_Rarities.lua    rarity table, damage pct ranges, weights per Blacksmith level
│   │ ├── LD_Item.lua        item data, rolls, stats and name (the RPG item layer)
│   │ ├── LD_Craft.lua       recipe roles (forge / carry), handcraft wrap
│   │ ├── LD_Events.lua      equip, load and hit events -> hooks
│   │ └── Translate/EN/IG_UI.json   rarity and stat names
│   └── client/
│     └── LD_DebugMenu.lua   debug: inspect, stamp as rarity
│
├── LDArcana/42/media/                requires LDCore
│ ├── actiongroups/, AnimSets/   the same placeholders
│ ├── scripts/LDA_items.txt   GENERATED: LDArcana.Tarot_<ID>, one item per active card
│ ├── textures/               GENERATED: 64x64 icons, Item_LD_Tarot_<ID>.png
│ ├── ui/LDArcana/            GENERATED: 102x158 window art, Tarot_<ID>.png
│ └── lua/
│   ├── shared/
│   │ ├── LD_Arcana.lua      card registry, STEPS, define(), mods, preview
│   │ ├── LD_Spread.lua      socket / unsocket / each, one card per weapon
│   │ ├── LD_ArcanaHooks.lua one dispatcher per effect, past -> present -> future
│   │ ├── LD_Deck.lua        the vanilla deck as the card source, loot + drop numbers
│   │ ├── LD_Major/          one file per card, 22 of them
│   │ ├── TimedActions/      LD_SocketCardAction (card in / out), LD_DrawCardAction
│   │ └── Translate/EN/      ItemName.json GENERATED, plus IG_UI.json and ContextMenu.json
│   ├── server/
│   │ ├── LD_DeckLoot.lua    the deck in the extra loot tables
│   │ └── LD_DeckDrops.lua   the deck on zombies
│   └── client/
│     ├── LD_SpreadWindow.lua     the three slots, previews, socket menu
│     ├── LD_SpreadMenu.lua       inventory right-click -> Tarot Spread
│     ├── LD_DeckMenu.lua         inventory right-click on a deck -> Draw a Card
│     ├── LD_Playtest.lua         debug: right-click the ground -> LD: Run Playtest
│     └── LD_ArcanaDebugMenu.lua  debug: socket any card without owning it

The generated files are baked by `build_tarot.ps1`, which lives in estral-tools rather than
here, because it needs an art pack that is in no repo. See the README.

# Core

## Rarity
Forging rolls a rarity from `LDCore.RarityWeights[blacksmith level]`, then a damage pct inside
that rarity's `pct` range. Min and max damage are the vanilla weapon's times the pct.

The roll happens once, at the forge. Putting the blade on a handle (`AssembleBlade`) and
taking it off (`DismantleBlade`) copy the item's LD data and never roll again.

Item data, in modData under `LD`:

    { v = 1, rarity = "RARE", pct = 137, level = 6, arcana = { past = "TOWER" } }

Core only reads `v`, `rarity`, `pct` and `level`. Anything else in there (`arcana`) is carried
along untouched whenever core copies the table.

## Recipe roles
`LDCore.Recipes` maps a recipe name to a role.

- `forge` rolls a fresh rarity onto what the recipe makes.
- `carry` copies the roll from what it uses up onto what it makes, and never rolls again, so
  dismantling and reassembling can't be used to reroll.

## Stats
`LDItem.STATS` says where each stat is read and written, and what it may be set to.

- `scales` is multiplied by the rolled damage pct.
- `int` is whole numbers only; the setter takes an int.
- `min` / `max` are clamped after the hooks have had their say.
- `write` is a setter that needs more than one call.

Everything in that table is open to the `item.stats` hook, which is how arcana cards move a
weapon. Head condition is deliberately absent: there's no setter for its maximum, and no blade
has a head to begin with.

## Hooks
Core fires these with a ctx table and never knows who listens.

| hook            | when                               | change          |
|-----------------|------------------------------------|-----------------|
| `forge.weights` | before the rarity roll             | `ctx.weights`   |
| `forge.rolled`  | after the roll, before it's saved  | `ctx.data`      |
| `item.stats`    | every stat rebuild                 | `ctx.stats`     |
| `weapon.equip`  | equip in either hand, and on load  |                 |
| `weapon.hit`    | the weapon hits a character        |                 |

The ctx each one carries is listed on `LDCore.HOOK` in `LD_Core.lua`.

# Arcana

A weapon has three slots: Past, Present, Future. A card is one card in three readings: its
stats come from its Arcana, and the slot decides how they manifest.

The spread is stored inside the item's LD data as `{ past = id, present = id, future = id }`,
an empty slot being a missing key. Core copies the whole LD table when a blade goes on a handle
or comes off one, so the cards travel with it without core knowing they exist.

Cards are items (`LDArcana.Tarot_<ID>`). Socketing takes one out of the inventory; removing or
replacing one hands it back. The same card can only be on a weapon once.

Only the cards in `LDArcana.ACTIVE` exist in play: Emperor, Chariot, Death, Temperance. The
rest keep their files and art but have no item. `build_tarot.ps1` reads the list, so a card
goes live by adding it there and re-running the tool.

## Writing a card
One file per card in `LD_Major/`. A card has three slots, and the slot decides how the card
manifests, so one card covers all three readings rather than being three cards.

    LDArcana.define("EMPEROR", {
        area = "Power", theme = "Authority, force, dominance",
        stats = { "minDamage", "maxDamage", "knockback" },
        present = { title = "Force", text = "Everything goes into this strike.",
                    mods = { maxDamage = 2, knockback = 1, baseSpeed = -1 } },
    })

- `mods` are the design's arrows. 1 is up, 2 is a double up, -1 is down, always read in the
  stat's own direction, so `weight = -1` is a lighter weapon.
- `title` is the slot's name, e.g. "Impending dominance".
- `text` is a line of flavour under it.

One arrow is worth whatever `LDArcana.STEPS` says, as a share of the weapon after its rarity
roll, so a card is worth more on a legendary than on a common. Calling `define` twice for a
card adds to what's there.

Stat keys: `minDamage`, `maxDamage`, `criticalChance`, `critMultiplier`, `baseSpeed`,
`minRange`, `maxRange`, `knockback`, `conditionMax`, `conditionLowerChance`, `averageCondition`,
`weight`. `averageCondition` isn't a real stat; it leans on max condition and condition lower
chance together, the two things that decide how long a weapon lasts.

For anything the arrows can't say, a slot can hold a function instead, named after an
`LDArcana.EFFECT_HOOKS` entry. It gets `(ctx, card, position)` and runs after the mods.

- `stats` runs on every stat rebuild: forge, assemble, equip, load, socket, and every preview.
  ctx: `item`, `data`, `base` (vanilla), `rolled` (after rarity, before cards), `stats` (change
  this one).
- `equip` runs when the weapon goes into a hand, and once on load for what's already held.
  ctx: `player`, `item`, `data`, `loading`.
- `hit` runs when the weapon hits a zombie or a player. ctx: `attacker`, `target`, `item`,
  `data`, `damage` (read only).

A `stats` function must be pure. No side effects, or the socket menu, which runs it to preview
a card it hasn't socketed, will lie about what that card would do.

## Where cards come from
The vanilla Tarot Card Deck. Right-click it, Draw a Card: you pull from the top of the deck,
and the rest of it goes, as if the universe took it back. One random active card, and the deck
is gone. The deck spawns where vanilla puts it, plus the extra tables and the zombie drop
chance in `LDDeck.LOOT` (`LD_Deck.lua`).

# Scope
Blades only: weapons the game files as long blade or small blade, and the blades that go on
their handles. The meat cleaver and the hand scythe are axes to the game, and spear heads lose
the roll on a shaft, so all three stay vanilla for now.
