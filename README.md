# LAPLACE//DAEMON

An RPG item mod for Project Zomboid Build 42. Blades you forge roll a rarity off your
Blacksmith level, and that rarity decides a damage range rather than a flat number, so two
Rare swords don't hit the same. Then you give the weapon a fortune: three tarot cards in
Past, Present and Future, where the slot a card sits in decides what it does.

Two mods, because the rarities stand on their own. Needs **42.20+**.

| Mod | id | Needs |
| --- | --- | --- |
| LAPLACE//DAEMON Core | `LDCore` | nothing |
| LAPLACE//DAEMON Arcana | `LDArcana` | `LDCore` |

Works the same in singleplayer and on a dedicated server. The server decides every roll and
owns every item change; see [Multiplayer](#multiplayer).

## The art

Tarot Cards by SeeOne, [seeone.itch.io/tarot-cards](https://seeone.itch.io/tarot-cards). The
licence allows commercial use and modification and says credit "is not necessary, but
appreciated", so **no credit ships** — that is a choice, and within terms.

It also says the pack may not be redistributed or resold. What ships here is baked output —
64x64 icons downscaled from the 8X export, and the 2X panels copied for the spread window —
not the pack. Same judgement call as the card art in Dead Court Deck.

## How it fits together

Forging rolls a rarity from `LDCore.RarityWeights[blacksmith level]`, then a damage pct inside
that rarity's band. The roll happens **once**, at the forge: putting the blade on a handle and
taking it back off copy the data rather than rolling again, so a blade can't be reforged into a
better one by pulling it apart.

Core never knows Arcana exists. It fires five hooks with a ctx table — `forge.weights`,
`forge.rolled`, `item.stats`, `weapon.equip`, `weapon.hit` — and Arcana listens. That is why
Core runs on its own if you only want rarities.

Stats are always rebuilt from the vanilla base, never from the item's current numbers, so a
refresh on every equip and load can't stack. The same pure function computes them, which is how
the socket menu previews a card it hasn't socketed and cannot drift from what the setters write.

The rest is in [design.md](design.md), including the format for writing a card.

## Multiplayer

**Server-authoritative.** The client sends intent, never outcomes.

Crafting was already in the right place: vanilla runs `performRecipe` behind `if not
isClient()` in `perform()` and `if isServer()` in `complete()`, so the forge wrap only ever
runs on the server and a client cannot reach the rarity roll. What the mod adds is the push
afterwards, because the outputs reach the client before the stamp lands.

Socketing and drawing used to happen in the timed action, on the client, which meant a
modified client could deal itself any card. Now the action only animates and then asks. It
sends **item ids and nothing else**, and the server looks those ids up in its own copy of
that player's inventory, so a crafted packet cannot name a card you are not carrying. Which
card comes off a deck is the server's roll too.

**Stats can't travel, and don't need to.** `conditionMax` and `customWeight` appear in no
packet the game sends - only `moddata`, `condition`, `actualWeight`, the custom name and a
weapon's min/max damage do. So what crosses the wire is the one `LD` modData table, and every
machine rebuilds its own numbers off it. `LDItem.computeStats` was already written that way,
deriving everything from the vanilla base plus the roll, so nothing had to change to suit it.

`LD_Net` bridges both worlds. With no remote server the send is a direct call into the handler
that would have received it, so **singleplayer runs the same authoritative code a server
does** - which is also why the playtest can exercise it without a server.

Debug menus are admin-only once there is a server, and the commands behind them check again,
because the client is the one drawing the button.

## Generated files

These are baked, not hand-written. 48 files in all:

| Path | What |
| --- | --- |
| `LDArcana/42/media/scripts/LDA_items.txt` | one item per active card |
| `LDArcana/42/media/lua/shared/Translate/EN/ItemName.json` | their names |
| `LDArcana/42/media/textures/Item_LD_Tarot_*.png` | 23 icons at 64x64 |
| `LDArcana/42/media/ui/LDArcana/Tarot_*.png` | 23 panels at 102x158 |

`LDA_items.txt` says so in its header. The JSON can't carry a comment and the PNGs can't carry
one either, so `.gitattributes` marks all four as generated and this table is the rest of the
answer.

Art is baked for all 22 majors, but only the cards in `LDArcana.ACTIVE` get an item and a name
— Emperor, Chariot, Death and Temperance so far. Switching a card on means adding it there and
re-running the tool, which reads that list rather than keeping its own copy.

## Build

The generator is not in this repo. It lives in
[estral-tools](https://github.com/mariaalexissales/estral-tools), cloned next to this folder,
because it needs an art pack that is in no repo and so can't run for anyone who only has this.
That is also why the baked output is committed rather than built on demand.

```bash
powershell -ExecutionPolicy Bypass -File ../estral-tools/laplace-daemon/build_tarot.ps1
```

Run it from this folder — it reads the mod out of the working directory and stops if it isn't
there. Pass `-Source` if the pack isn't at `~/Downloads/Tarot Cards [Free].zip`. A card that is
switched on with no art stops the run rather than shipping an item with a missing icon.

## Testing

In singleplayer with `-debug`, right-click the ground and pick **LD: Run Playtest**. It draws
from a deck, forges a blade, puts it on a handle and takes it off, sockets cards, and checks
each step, printing one `[LD TEST]` line per check to `console.txt` and cleaning up every item
it made. It can't cover the crafting window itself, anything visual, or save and reload.

Because the net layer runs the same handlers with no remote server, that covers the multiplayer
code paths too — but not the wire. For that there is a local test server in
[estral-tools](https://github.com/mariaalexissales/estral-tools):

```powershell
.\servers\serve.ps1 -Server ldtest
.\servers\client.ps1           # and -Second for a second player
```
