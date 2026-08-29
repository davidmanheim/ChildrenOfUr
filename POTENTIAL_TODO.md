# Potential follow-up work

This is a review-derived, **potential** work list.  It is not a commitment to
change every item, nor evidence that each path is currently user-visible.
Prioritize and verify items before implementation.

## Quest completability audit (2026-08-28)

Full trace of all 12 quests in `coUserver/lib/quests/json/*.json` against the
current codebase and `tools/seed-demo-world.mjs` world placement. Not a JSON
well-formedness check -- for every requirement, verified the referenced item/
entity/action/location is real and has a live acquisition or trigger route,
including the full recipe-input chain (an item with a "real" recipe whose own
inputs are unobtainable does not count as obtainable), and that every quest's
offer-to-player trigger is actually reachable.

**How quests reach a player at all** (`coUserver/lib/quests/quest_endpoint.dart`,
`coUserver/lib/quests/quest.dart`): the only *unconditional* grant is Q1,
auto-added to every new local player's log on WebSocket connect when
`LOCAL_SEED_QUESTS=true` (set in `docker-compose.yml` for the local game
server). Every other quest is offered (`UserQuestLog.offerQuest`) from a real
in-code trigger site, each grep-verified directly against the current source
(not assumed from a prior note):

| Quest | Offer trigger | Source |
| --- | --- | --- |
| Q1 | `LOCAL_SEED_QUESTS` auto-grant on connect; also offered on buying `knife_and_board` from any vendor | `quest_endpoint.dart:65`, `vendor.dart:309` |
| Q2 | Petting any placed tree-family entity | `tree.dart:223` |
| Q3 | Donating an item to a Shrine | `shrine.dart:80` |
| Q4 | Player's street becomes "Louise Pasture" | `player_update_handler.dart:66` |
| Q5 | Same shrine donation as Q3 (offered alongside it) | `shrine.dart:82` |
| Q6 | Buying `pick` or `fancy_pick` | `inventory_new.dart:1008` |
| Q7 | Automatically 1 minute after Q1 completes (hardcoded timer, no NPC) | `quest.dart:317-319` |
| Q8 | A player's very first inventory row is ever created (first item obtained, any source) | `inventory_new.dart:547` |
| Q9 | Petting a Piggy | `piggy.dart:195` |
| Q10 | Player's mood drops below `maxMood/10` (periodic `simulate()` check, no NPC) | `metabolics_endpoint.dart:148` |
| Q11 | Nibbling a Piggy | `piggy.dart:140` |
| Q12 | Buying `cocktail_shaker` | `inventory_new.dart:1011` |

All of these trigger sites are live, ordinary code paths (not dead code), so
reachability of each quest's *offer* reduces to whether its triggering
entity/item is itself placed/obtainable -- checked per-quest below.

### Summary

| Quest ID | Title | Verdict |
| --- | --- | --- |
| Q1 | Make Me a Sammich | FULLY COMPLETABLE |
| Q2 | Tree Petter | FULLY COMPLETABLE |
| Q3 | Communing with the Giants | FULLY COMPLETABLE |
| Q4 | Race to the Forest | FULLY COMPLETABLE |
| Q5 | Loyalty's Rich Reward | FULLY COMPLETABLE |
| Q6 | Dullite, Beryl and Sparkly | FULLY COMPLETABLE |
| Q7 | Snocone Joy | FULLY COMPLETABLE (fixed 2026-08-28) |
| Q8 | Enlarge Yer Slots | FULLY COMPLETABLE |
| Q9 | Doody Inspector | FULLY COMPLETABLE |
| Q10 | The Great Guzzler Challenge | FULLY COMPLETABLE |
| Q11 | Meat Galore | FULLY COMPLETABLE |
| Q12 | Make Me Some Drinks | FULLY COMPLETABLE |

All 12 quests are genuinely completable end-to-end today (Q7 fixed
2026-08-28, see below), several via
recipe chains 2-3 tiers deep that were traced input-by-input rather than
trusted from their top-level ingredient list. One notable finding while
tracing: the `skill`/`skill_level`/`achievement_req`/`quest_req` keys present
on many `knife_and_board.json` recipe entries (e.g. `deluxe_sammich`'s
`achievement_req: "nice_dicer"`) are **not** enforced anywhere -- `Recipe`
(`coUserver/lib/entities/items/actions/recipes/recipe.dart`) only declares an
`@Field() Map skills` (populated from a JSON `skills` *map* key, which none of
these entries use) and no achievement/quest field at all, so
`redstone_mapper`'s `decode()` silently drops those keys and
`RecipeBook.makeRecipe` never checks them. This isn't a completability bug
(it makes recipes *more* permissive, not less) but is worth knowing before
"fixing" a recipe gate that doesn't actually gate anything at runtime.

### Q1 -- Make Me a Sammich -- FULLY COMPLETABLE

Auto-granted (see table above). Requires making `cheezy_sammich`,
`deluxe_sammich`, `hearty_groddle_sammich` (all `knife_and_board.json`
recipes, tool `knife_and_board` = real `kitchen`-category `StreetSpirit`
stock, `vendor.dart:170`). Ingredient chains, traced fully:
- `cheezy_sammich`: `cheese`(1) + `bun`(2). `bun` = real `groceries`
  `StreetSpirit` stock (`vendor.dart:123`). `cheese` chain: Butterfly (placed,
  `RARITY.Butterfly` 30%) `milk` action (`butterfly.dart:265`) -> `butterfly_milk`
  -> item action `shakeBottle` -> `butterfly_butter` -> item action `compress`
  -> `cheese` (`milk-butter-cheese.dart`).
- `deluxe_sammich`: `bun`(2) + `cheese`(1) [as above] + `pickle`(1) + `meat`(1).
  `pickle` = `awesome_pot` recipe (tool = real `kitchen` stock) from
  `cucumber`(produce vendor stock) + `olive_oil`(groceries vendor stock) +
  `pinch_of_salt`(real `spice_mill` output from `allspice`/`SpicePlant`, placed,
  per this file's Item economy section below). `meat` = real `Piggy` (placed)
  `nibble` reward.
- `hearty_groddle_sammich`: `bun`(2) + `hot_n_fizzy_sauce`(1) + `meat`(1).
  `hot_n_fizzy_sauce` = `saucepan` recipe (real kitchen stock) from
  `bubble_tiny`(1)[`bubble_tuner` recipe from `plain_bubble`x3, `plain_bubble`
  = real `BubbleTree` harvest, placed] + `cumin`+`hot_pepper`(spices, real
  `spice_mill` outputs) + `mustard`(real groceries vendor stock).

### Q2 -- Tree Petter -- FULLY COMPLETABLE

Needs 5 unique tree-family pets (`treePet.*`, `type: counter_unique`). 8
placed tree-family types exist (`WoodTree`, `BeanTree`, `BubbleTree`,
`FruitTree`, `PaperTree`, plus `EggPlant`/`GasPlant`/`SpicePlant`, which share
the same `pet` action and per-type `Stat` tracking, confirmed in
`tree.dart:190-223`), well over the 5 required.

### Q3 -- Communing with the Giants -- FULLY COMPLETABLE

Requires 1 `emblemGet` event. All 11 Shrine types (`Alph`...`Zille`) are
placed (5% chance each, `seed-demo-world.mjs` `RARITY`). `Shrine.donate()`
(`shrine.dart:60`) accepts any owned item, adds favor, and once a giant's
favor bar fills, `metabolics.dart:113-131`'s `_setFavor` grants
`emblem_of_<giant>` and publishes `emblemGet` -- real, wired, reachable given
any placed shrine of any giant.

### Q4 -- Race to the Forest -- FULLY COMPLETABLE (time-limit feasibility not independently verified)

Offered on entering "Louise Pasture"; requires reaching "Blue Mountain Bore"
within 79s (`location_Blue Mountain Bore`, `type: timed`). Both street names
are confirmed real entries in `coUserver/lib/common/mapdata/json/streetdata.json`
(verified directly, not assumed). The location-change/timer mechanism itself
is real and unmodified from upstream. Not independently re-verified: whether
79 seconds is actually enough time to travel between these two specific
streets given current player movement speed and street adjacency/geometry --
this is unchanged original-game balance data, not something this recovery
project altered, so it is marked completable but flagged rather than silently
assumed.

### Q5 -- Loyalty's Rich Reward -- FULLY COMPLETABLE (deep grind)

Prerequisite Q3 (completable, see above) is itself required and satisfiable.
Requires collecting 11 emblems of one giant type and using the `iconize` item
action (`emblems-icons.dart:25`) on a stack of them, which is real, wired code
that consumes 11 matching emblems and grants `icon_of_<giant>`, publishing
`iconGet`. Reachable via repeated Q3-style shrine donation; slow, but every
step traces to a real route.

### Q6 -- Dullite, Beryl and Sparkly -- FULLY COMPLETABLE

Requires 17/13/11 `chunk_dullite`/`chunk_beryl`/`chunk_sparkly`. `BerylRock`/
`DulliteRock`/`SparklyRock` are all placed (`RARITY` 22%/16%/10%) and their
mining actions grant the exact matching chunk items
(`berylrock.dart`/`dulliterock.dart`/`sparklyrock.dart`), which
`InventoryV2.addItemToUser` turns into a matching `getItem_chunk_*` event
automatically. Offer trigger (buying `pick`/`fancy_pick`) is real vendor stock
across several placed vendor categories (`ToolVendor`, and `hardware`/
`mining`/`alchemical`-category `StreetSpirit`).

### Q7 -- Snocone Joy -- FULLY COMPLETABLE (fixed 2026-08-28)

Prerequisite Q1 is completable, and Q7 is auto-offered 1 minute after Q1
completes, so the *quest itself* is reachable. Its two requirements:
- `location_Wintry Place` (travel there): fine -- "Wintry Place" is a real
  street in `streetdata.json` (verified directly).
- `getItem_snocone_*` (buy any sno cone): **fixed**. The only source of any
  `snocone_blue`/`green`/`orange`/`red`/`purple` item anywhere in the codebase
  is `SnoConeVendingMachine` (`coUserver/lib/entities/npcs/vendors/
  snoconevendingmachine.dart`), which was not in `tools/seed-demo-world.mjs`'s
  `VENDOR_NPC_TYPES` at audit time -- never instantiated anywhere in the live
  world. This same gap was independently noted in this file's Item economy
  section (the `snocone_*` entry in the food-icon-conversion batch note
  above) and in `RECOVERY_TODO.md`.
  **Fixed**: `SnoConeVendingMachine` added to `seed-demo-world.mjs`'s
  `VENDOR_NPC_TYPES`/`RARITY` (10% chance/street, maxCount 1) after
  confirming its constructor signature matches `street.dart`'s reflective
  placement expectations (identical shape to the already-placed
  `ToolVendor`) -- see RECOVERY_TODO.md's "Placement pass:
  SnoConeVendingMachine (Q7 fix)" row for full verification detail
  (336 live instances seeded, WebSocket-probed clean construction, zero
  server errors). Unlike the Hooch/PurpleFlower/Still placement precedent,
  this NPC's own on-map sprite art was already real and converted (not
  dead-linked) at fix time, so no follow-up art-conversion gap remains here.

### Q8 -- Enlarge Yer Slots -- FULLY COMPLETABLE

Offered automatically the first time any player ever receives any item (first
`inventories` row INSERT, `inventory_new.dart:547`) -- not NPC-dependent.
Requires buying any `*_bag` item (`getItem_.*_bag`). `generic_bag`/
`bigger_bag`/color variants are all `category: "Storage"`
(`entities/items/json/storage.json`), sold via `pickItems(["Storage"])` by
both `ToolVendor` (placed) and `hardware`-category `StreetSpirit` (placed).

### Q9 -- Doody Inspector -- FULLY COMPLETABLE

Offered on petting a Piggy (placed, common). Requires 5 `examine_piggy_plop`
events. `Piggy.feedItem` (`piggy.dart:223`, real `feed` action, requires any
non-seed crop item -- produce vendor stock or `Garden` harvest, both real and
placed) drops a `piggy_plop` item on the ground; picking it up and using its
real `examine` item action (`piggy_plop.dart:25`, `examinePlop`) publishes the
exact matching event.

### Q10 -- The Great Guzzler Challenge -- FULLY COMPLETABLE

Offered automatically whenever a player's mood drops below `maxMood/10`
(`metabolics_endpoint.dart:148`, periodic `simulate()` check, no NPC needed).
Requires drinking 12 `beer`. `beer` has a real, confirmed-wired `Drink` item
action (`drinks.json`) that goes through `Consumable.drink()`
(`consume.dart:23-46`), which publishes `drink_<itemType>` -- for `beer`, this
is exactly `drink_beer`, matching the quest's `eventType`. `beer` is real
`groceries`-category `StreetSpirit` stock (placed, confirmed in this file's
prior Item economy note).

### Q11 -- Meat Galore -- FULLY COMPLETABLE

Offered on nibbling a Piggy. Requires 6 `piggyNibble` events; `Piggy.nibble()`
(`piggy.dart:129`) requires no tool/item, just energy, and publishes the event
directly. `Piggy` is common (50% chance, up to 2/street).

### Q12 -- Make Me Some Drinks -- FULLY COMPLETABLE (deep grind)

Offered on buying `cocktail_shaker` (real `kitchen`-category `StreetSpirit`
stock). Requires making `face_smelter`, `pungent_sunrise`, `flaming_humbaba`
(all `cocktail_shaker.json` recipes). All three recipes include `hooch`,
which is real and placed two ways (`HoochRespawningItem` world-entity harvest,
`RARITY` 25%, and the `Still` fermenting NPC, 6%). Remaining ingredients, all
traced to real chains:
- `face_smelter`: `onion_sauce`(1)[`saucepan` recipe: `butterfly_butter`
  (cheese-chain intermediate, see Q1) + `onion`(4, produce vendor stock) +
  `nutmeg`(1, real `spice_mill` output)] + `gas_crying`(1)[`gassifier` recipe
  from `general_vapour`x4, `general_vapour` = real `GasPlant` harvest reward,
  placed] + `parsnip`(2, produce vendor stock).
- `flaming_humbaba`: `fruity_juice`(1)[`blender` recipe: `cherry`x4(real
  `FruitTree` harvest reward, placed) + `plum`x2 + `orange`x1(both
  `fruit_changing_machine` recipe outputs from `cherry`)] + `hot_n_fizzy_sauce`
  (see Q1's `hearty_groddle_sammich` chain) + `gas_laughing`(1, `gassifier`
  from `general_vapour`x3).
- `pungent_sunrise`: `camphor`(1, real `spice_mill` output) + `exotic_juice`
  (1)[`blender` recipe: `pineapple`+`mangosteen`x3+`banana`, all
  `fruit_changing_machine` outputs from `cherry`] + `fruit_salad`(1)
  [`knife_and_board` recipe: `bunch_of_grapes`+`banana`+`apple`, all
  `fruit_changing_machine` outputs from `cherry`].
All the tools involved (`saucepan`, `gassifier`, `blender`,
`fruit_changing_machine`, `knife_and_board`, `cocktail_shaker`) are real
`kitchen`/`hardware`/`ToolVendor` stock.

## Action rate-limit gating audit (2026-08-29)

Prompted by the `chicken.dart` `squeeze()`/`customizeActions()` bug fixed
earlier this session (`customizeActions()` correctly gated the `squeeze`
action on a daily cap derived from `squeezeList`, but `squeeze()` never
added to `squeezeList`, so the cap never engaged). Audited every entity
class under `coUserver/lib/entities/` (`npcs/`, `plants/`, `items/`) for the
same bug *shape*: a per-instance tracking field (list/map/counter/DateTime)
read by `customizeActions()` (or an equivalent client-facing gate) to
disable an action or vary a parameter, cross-checked against whether the
corresponding action handler(s) actually keep that field's data current on
the successful-use path -- in both directions (gate reads stale/never-updated
data, or handler tracks data nothing ever reads).

**Method**: grepped `customizeActions` (8 hits) and a broad set of
tracking-shaped identifiers/comments (`List<String>`, `Map<String,\s*int>`,
`lastUsed`, `timesUsed`, `history`, `DateTime last`, `cooldown`,
`dailyLimit`, `once per`, `Count\b`, `Attempts\b`, `Cooldown`, etc.) across
every `.dart` file in `npcs/`, `plants/`, and `items/`, then read each hit's
full class to compare its gate logic against its handler(s) line-for-line.

### Findings

No further instances of the chicken.dart bug shape (gate reads a tracking
field the handler never populates, or vice versa) were found. One related
but distinct issue turned up:

1. **`coUserver/lib/entities/npcs/animals/butterfly.dart`, class `Butterfly`
   -- dead tracking field `numMilks`.** Declared (`int numMilks = 0;`) and
   reset to `0` inside `massage()`'s successful-lotion branch, but never
   incremented anywhere in `milk()` (or elsewhere) and never read by any
   gate -- grep-confirmed as the field's only two references in the entire
   codebase. Unlike the chicken.dart bug there is no `customizeActions()`
   (or other) gate currently trying to read it, so nothing is silently
   broken today; it reads as a vestige of an unimplemented "N free milkings
   per massage" mechanic. Proposed fix (once intent is confirmed): either
   increment `numMilks` on each successful `milk()` call and use it in a
   real gate (e.g. disable/limit `milk` after N uses per massage), or
   remove the dead field entirely if no such limit was ever intended.

### Checked and confirmed correctly wired (no re-check needed)

- `coUserver/lib/entities/npcs/animals/chicken.dart` (`Chicken`) -- the
  originating bug, already fixed this session (`squeezeList` is now
  populated in `squeeze()`).
- `coUserver/lib/entities/npcs/animals/piggy.dart` (`Piggy`) -- `nibbleCounts`
  and `petCounts` are both correctly incremented in `nibble()`/`pet()` past
  their success checks, matching what `customizeActions()` reads.
- `coUserver/lib/entities/npcs/items/icon.dart` (`Icon`) -- `currants` is
  correctly debited/credited in `tithe()`/`ruminate()`/`revere()`/`reflect()`
  on their success paths, matching the `customizeActions()` gate.
- `coUserver/lib/entities/plants/trees/tree.dart` (`Tree`, and all of its
  subclasses: `WoodTree`, `BeanTree`, `BubbleTree`, `EggPlant`, `FruitTree`,
  `GasPlant`, `PaperTree`, `SpicePlant`) -- gating uses `state`/`maxState`
  directly (incremented/decremented in `water()`/`harvest()`), not a
  separate tracking field; no drift possible.
- `coUserver/lib/entities/npcs/rube.dart` (`Rube`) -- `tradeAttempts` is
  read and incremented in the same method (`talkTo()`); no separate gate to
  drift out of sync with.
- `coUserver/lib/entities/npcs/crab.dart` (`Crab`) -- `listenHistory` is
  populated at the end of `playMusic()` and consumed internally by
  `likesSong()`; no external `customizeActions()`-style gate.
- Plants with depletion-based gating via `state`/`respawn` (self-contained,
  no separate tracking field): `PeatBog`, `MortarBarnacle`, `IceNubbin`
  (`IceKnob`), `DirtPile`, `Rock` (and its rock subclasses).
- Concurrency-only counters (`openCount` in the `Vendor`/`StreetSpirit`
  family, `communeCount` in `Shrine`) track simultaneously-open UI windows
  for animation state, not a rate limit, and are correctly
  incremented/decremented on both open and close paths.
- Entities with no per-instance rate-limit tracking at all (actions are
  either unlimited, gated purely by inventory/energy/item requirements, or
  gated by a single directly-mutated `state`/`respawn` field): `Mailbox`,
  `Still`, `Garden`/`HerbGarden`, `Fox`/`SilverFox`/`FoxBait`, `Blob`,
  `Salmon`, `Firefly`, `HeliKitty`, `Batterfly`, `Auctioneer`,
  `HellBartender`, `DustTrap`, `RacingCubimal` family, `VisitingStone`,
  `DemoChicken`, all `Vendor` subclasses (`StreetSpiritGroddle`, etc.),
  `BabyAnimals`, `StreetEntityBalancer`, `Recipe`/`RecipeBook`, `FocusingOrb`,
  `Quill`, `Potions`.

## Sprite-flip (facing direction) audit (2026-08-29)

Prompted by a bug found and fixed in `Piggy`: the client's sprite-flip
convention (`coUclient/lib/src/game/entities/npc.dart` -- renders
**unmirrored** when `facingRight == true`, `scale3d(-1,1,1)` mirrored
otherwise) assumes every converted sprite sheet's raw art faces **right** by
default, matching `defaultXAction()`'s `x += speed * (facingRight ? 1 : -1)`
(`coUserver/lib/entities/npcs/npc.dart`). This holds for some converted
animals (`chicken-walk.png`) but not others -- `Piggy`'s entire converted
state set faced left, causing it to visually walk backward relative to its
movement direction; fixed earlier this session by individually mirroring
every frame of all 7 states (both `content/sprites/piggy/` and
`coUclient/web/files/sprites/generated/converted/piggy-*.png`), preserving
frame order.

**Method**: every entity under `coUserver/lib/entities/npcs/` (`animals/`,
plus vendors/giants/`Crab` from `tools/seed-demo-world.mjs`'s
`REAL_TYPES`/`VENDOR_NPC_TYPES`) was checked for (a) whether any of its
states actually move horizontally via `moveXY()`'s `facingRight`-driven
`defaultXAction()`, and if so (b) which way its raw converted art visually
faces, by cropping individual frames (using each state's own `Spritesheet()`
frame-width/height args) to PNGs and visually inspecting them at 3-12x
scale, across multiple frames per state (not just frame 0) to rule out a
misleading neutral pose.

### Fixed

Individually mirrored every frame of every state (frame order preserved,
same method as the `Piggy` fix), applied to both `content/sprites/<name>/`
and `coUclient/web/files/sprites/generated/converted/<name>-*.png`:

- **`Fox`** (`coUserver/lib/entities/npcs/animals/fox.dart`) -- all 9 real
  states (`brushed`, `eat`, `eatEnd`, `eatStart`, `jump`, `pause`, `run`,
  `taunt`, `walk`); raw art faced left (head/snout on the left, tail on the
  right). Note: the class already had a `facingRight = false;` line in its
  constructor with a comment noting the left-facing art, but that value is
  overwritten immediately by `update()`'s `facingRight = (movingTo.x >
  this.x)` as soon as the fox actually moves toward bait/home, so it never
  prevented the backward-run visual bug; left as-is since it's harmless
  (the fox starts hidden and its facing is always recomputed from movement
  before it becomes visible).
- **`SilverFox`** (same file, extends `Fox`) -- same 9 states, own
  `silverfox-*.png` art, same left-facing issue (identical frame layout to
  `Fox`, confirmed independently by direct visual inspection of its own
  converted files, not assumed from the `Fox` fix).
- **`Batterfly`** (`coUserver/lib/entities/npcs/animals/batterfly.dart`) --
  all 5 states (`chew`, `front_turned`, `front_waiting`, `fly_profile`,
  `fly_profile_turned`); raw art clearly faced left (bat-like face/snout on
  the left throughout the whole `fly_profile` flap cycle, confirmed across
  5 sampled frames). `fly_profile` is the state `update()` actually drives
  movement through (`currentState.stateName.contains("fly")`).

### Checked and confirmed already correct or non-directional (no re-check needed)

- **`Chicken`** (`walk`, `flying`) -- raw art already faces right
  (beak/head on the right); matches the task's prior spot-check.
- **`Salmon`** (`swim`, `swimUp15`, `swimUp30`, `swimDown15`, `swimDown30`,
  `turn`) -- **contradicts this investigation's own starting assumption**:
  all 5 movement states were individually inspected at high zoom across
  multiple frames each, and every one clearly shows the fish's eye/mouth on
  the *right* side with the tail fin flexing on the left -- i.e. the raw art
  already faces right in every state, including the up/down variants (which
  are diagonal, not purely vertical: `Salmon.update()`'s `moveXY(yAction:
  ...)` still runs the default `facingRight`-driven horizontal
  `xAction`, so all 5 states move horizontally the same way, and all 5 were
  checked on that basis). No mismatch found; no fix applied, despite prior
  guidance that this entity needed one.
- **`HeliKitty`** (`2fly`, `3fly`) -- a front-on/hovering chibi-cat design
  (helicopter tail spinning overhead); no side-profile head/tail asymmetry
  across a full sampled cycle, so mirroring produces no visually detectable
  difference. No fix applied.
- **`Butterfly`** (`fly-side`, the only state `update()` actually drives
  movement through) -- wings-only silhouette with a thin, non-directional
  body segment; no discernible head/antennae orientation across 12 sampled
  frames spanning the whole flap cycle. No fix applied.
- **`Crab`** (`walk`) -- fully front-facing/symmetric across the entire
  24-frame walk cycle (eyes, claws, legs all centered); mirroring is a
  no-op visually. No fix applied.
- **`ToolVendor`** (`walk`, the only state its movement code actually sets
  via `setState()` -- `walk_left`/`turn_left`/`turn_right` sprites exist in
  its `states` map but are dead code, never reached by `setState()`) --
  front-facing/symmetric creature design. No fix applied.
- **`SnoConeVendingMachine`** -- does not use the mirror convention at all:
  `facingRight` is set once (`true`) in the constructor and never toggled
  again, so the client always renders it unmirrored; direction instead
  comes from switching between its own dedicated `walk_left`/`walk_right`
  sprite sheets. Immune to this bug class by construction. Not touched.
- **`StreetSpiritFirebog`** (`idle_move`, its only real-art moving state --
  inherited `StreetSpirit.speed = 75`) -- front-facing/symmetric jellyfish-
  like design. No fix applied.
- **`StreetSpiritGroddle`**, `alph`/`day` variant only (the sole one of its
  24 giant/light combos with real converted art -- see the class's own
  source comment; the other 23 remain on dead `childrenofur.com` links and
  are out of scope) -- `idle_move` is front-facing/symmetric. No fix
  applied.
- Confirmed stationary (no state ever calls `moveXY()` with a nonzero,
  `facingRight`-driven horizontal `xAction`, so this bug class cannot apply
  regardless of art): `Garden`/`HerbGarden`, `GardeningGoodsVendor`
  (`scarecrow.dart`), `DustTrap`, `Mailbox`, `StreetSpiritZutto` (`speed =
  0`), `Shrine` and all giant subclasses (`update()` is a no-op), all
  `Vendor` base-class behavior with no movement override.

**Verification**: `docker compose restart client` rebuilt with 0 errors
across several webdev rebuild cycles; `node tools/validate-content.mjs`
still passes (1861 sprite sheets checked, same pass/fail counts as before --
expected, since only pixel content changed, not geometry or manifests). Not
independently re-confirmed with an in-browser screenshot this session.

## Tree-family maturity-sprite frame-order audit (2026-08-29)

Prompted by a live user report that `SpicePlant` showed its full/lush frame
*after* harvesting rather than before. By the game's own logic this is
backwards: `Tree.harvest()` decrements `state` toward 0 (`state == 0` ->
"nothing to harvest", `harvest()` returns false) and `Tree.water()`
increments `state` toward `maxState` (`state == maxState` -> "not thirsty",
`water()` returns false) (`coUserver/lib/entities/plants/trees/tree.dart`),
and the client maps `state` directly to sprite-sheet column with **no
reversal** (`column = state % numColumns` in
`coUclient/lib/src/game/entities/plant.dart`). So frame 0 of every
maturity-level sheet must depict the bare/depleted state and the last frame
must depict the full/lush state, for all 8 `Tree` subclasses (`WoodTree`,
`BeanTree`, `BubbleTree`, `FruitTree`, `PaperTree`, `EggPlant`, `GasPlant`,
`SpicePlant`).

**Method**: read each entity's `states` map for its real maturity-level
count (1-4 for `WoodTree`; 1 for `PaperTree`; 1-10 for the other 6) and each
state's exact `Spritesheet()` frame width/height. Cropped every individual
frame of every maturity level of every type (not just maturity_1, and not
just a full low-res strip) into per-type labeled grids (`PIL`, one row per
maturity level, one column per frame, each frame independently cropped from
its sheet using its own declared frame geometry) and visually inspected
each grid at readable size. Cross-referenced every type's original AS3
source (`tmp/glitch-items/harvestable_resources/*/trant_*.as` /
`wood_tree.as` / `paper_tree.as`) for its actual health-to-frame formula,
since a mismatched formula is a more reliable signal than eyeballing alone.

### Confirmed REVERSED and fixed: `GasPlant`, `SpicePlant`

Both source files use an **inverted** health formula not present in any
other tree type:

- `trant_gas.as:25`: `tree.gotoAndStop(11 - health);`
- `trant_spice.as:26`: `tree.gotoAndStop(11 - health);`

Health 1 (bare) therefore lives at SWF timeline frame 10, and health 10
(full) lives at frame 1. The conversion pipeline rasterized frames in raw
SWF frame order and placed them left-to-right as sheet columns 0-9 with no
correction for this inversion, so column 0 ended up as health 10 (full/lush)
and column 9 as health 1 (bare) -- exactly backwards from `Tree.state`'s
bare-at-0/full-at-max convention. Visually confirmed on the original art
before fixing: every maturity level of both types showed a dense, fully
bloomed frame 0 (purple flower clusters for `GasPlant`, red berry-like
clusters for `SpicePlant`) fading to a bare, whitened/dried final frame --
the reverse of every other tree type's own progression.

Fixed by cropping each of the 10 maturity-level sheets per type into its 10
individual frames (using that type's exact per-maturity-level frame
width/height from its `Spritesheet()` args) and reassembling them in
reversed column order -- a pure frame **reorder**, not a horizontal mirror
(mirroring is the unrelated animal-sprite `facingRight` bug fixed in the
"Sprite-flip" audit above; no frame here was flipped). Applied to both
`content/sprites/{gas_plant,spice_plant}/maturity_1.png` through
`maturity_10.png` and the matching
`coUclient/web/files/sprites/generated/converted/{gas_plant,spice_plant}-maturity_N.png`
copies -- confirmed byte-identical (md5) to their `content/sprites` source
both before and after the fix, so both locations stay in sync. Re-verified
visually after the fix: every one of the 10 maturity levels for both types
now shows a bare/thin frame 0 and a fully bloomed final frame, for all 10
maturity levels of both types.

### Confirmed already correct (bare-to-full, left-to-right): `WoodTree`, `BeanTree`, `BubbleTree`, `EggPlant`, `PaperTree`

- **`WoodTree`** -- no health dimension at all (only 4 maturity stages,
  6 frames each, a plain chop-progression). Visually confirmed frame 0 =
  bare stump, frame 5 = full branching log pile, for all 4 maturity levels.
- **`PaperTree`** -- a single real 22-frame timeline,
  `paper_tree.as`: `gotoAndStop(paper_count+1)` for `paper_count` 0-21, a
  direct (non-inverted) mapping. Visually confirmed frame 0 = mostly green
  leaves with little white "paper", frame 21 = canopy fully covered in
  white paper-leaves (the harvestable), for its one maturity level.
- **`BeanTree`** -- `trant_bean.as:27`: `tree.setHealth(health);`, direct.
  Visually confirmed frame 0 = tightly curled, leafless dry growth, frame 9
  = open leaves with visible green bean pods, for all 10 maturity levels.
- **`BubbleTree`** -- `trant_bubble.as:27`: `tree.gotoAndPlay(health);`,
  direct. Visually confirmed frame 0 = sparse young growth, frame 9 =
  bushier growth with many more of the white ring-shaped harvestable
  bubbles attached, for all 10 maturity levels.
- **`EggPlant`** -- `trant_egg.as:25`: `tree.gotoAndStop(health);`, direct.
  Visually confirmed frame 0 = bare stalk with only small eye-like spots,
  frame 9 = stalk sprouting many white harvestable egg pods, for all 10
  maturity levels.

None of these five were modified.

### `FruitTree` -- ambiguous case, resolved: frame order is moot, not touched

This was flagged for special attention because a first quick look was
inconclusive -- its bare-branch frames look visually similar across a low-
res strip. Investigated in two ways:

1. **Source structure**: `trant_fruit.as`'s 10 `grow_N` maturity clips are
   each confirmed (per `content/source-manifest.json`'s conversion note for
   `fruit_tree`) to hold only **one** real top-level frame; the 10-level
   "health" and fruit-count visuals are driven entirely by separately
   toggling dozens of nested per-leaf (`fol_1..fol_maxfla`) and per-cherry
   (`cherry_1..cherry_maxcherry`) child clips via AS3, which has no single
   equivalent top-level frame range and isn't representable by this
   single-composited-frame-per-state sprite architecture. Each `maturity_N`
   sheet was therefore built by duplicating that one real, correctly
   converted default-health snapshot across all 10 columns -- documented in
   both `content/source-manifest.json`'s per-output `note` field and
   `fruittree.dart`'s own code comment above its `states` map.
2. **Pixel proof**: cropped every frame of 4 sampled maturity levels
   (`maturity_1`, `maturity_4`, `maturity_7`, `maturity_10`, chosen to span
   the low/mid/high end of the growth range) and diffed every frame against
   frame 0 of the same sheet with `PIL.ImageChops.difference`. Every single
   comparison across all 4 sheets returned `bbox=None` (no differing
   pixels at all) and `meandiff=0.0000` -- i.e. all 10 frames within a given
   maturity level's sheet are byte-identical duplicates, exactly as the
   source manifest documented.

Since every frame in a `FruitTree` maturity sheet is an identical copy of
the same image, reversing the column order produces a byte-identical sheet
-- there is no reversed-vs-correct distinction to make or fix for this
type. (What *does* legitimately vary is the image between different
maturity levels -- e.g. `maturity_4`'s duplicated frame shows a young,
sparsely-fruited tree while `maturity_10`'s shows a large, densely-fruited
canopy -- but that is the separate `maturity` dimension, not the `state`
dimension this audit covers, and was not touched.) Left entirely untouched.

**Verification**: `docker compose restart client` rebuilt with 0 errors;
`node tools/validate-content.mjs` still passes (1869 sprite sheets checked).
Not independently re-confirmed with an in-browser screenshot this session.

## Reliability and compatibility

- ~~Finish replacing raw Redstone mapper query results with typed lists across
  auth, users, auctions, quests, mailbox, buffs, skills, notes, and migrations.~~
  Done 2026-08-27: all remaining raw `dbConn.query` typed-assignment sites in
  coUserver and authServer now `.cast<T>()`; the `PlayerBuff._write` decode cast
  (the live 10-second error loop) is also fixed. A repeat multiline grep for
  `List<T> x = await dbConn.query` finds only a commented-out line.
- Guard nullable/dynamic WebSocket data (`firstConnect`, unknown handlers) and
  client street metadata comparisons. *(Partially done 2026-08-27:
  `street_update_handler.dart` now compares `map['firstConnect'] == true`, and
  the client `collectQuoin` handler tolerates late/unknown quoin responses.
  Remaining: audit other handlers for bare `if (map[...])` boolean conditions.)*
- Isolate other legacy browser APIs behind validated JavaScript adapters and add
  a current-Chromium startup/chat/street smoke test.
- Await and supervise server/auth startup stages; add timeouts and isolate
  individual socket/send failures so one client cannot terminate a service.
- Fix auth logout, verification-table/email handling, and bounded session expiry.
  *(Logout no-op (`SESSIONS.remove([token])`), the URL-encoded email in the
  verification dedupe query, and the `email_verification` table typo fixed
  2026-08-27. Remaining: bounded session expiry — `SESSIONS` still grows
  unbounded in memory with no TTL.)*

## Deployment and security

- Keep local-session authentication strictly development-only; authenticate
  HTTP and WebSocket callers server-side before any public deployment.
- Authorize state-changing APIs and replace reflective client-selected actions
  with an explicit allowlist.
- Restrict CORS, bind development-only services (especially PostgreSQL) to
  loopback, and use non-default secrets and production database authentication.
- Disable stack traces in production HTTP responses.

## Item economy

- Found 2026-08-28 while converting a standalone player-item icon batch:
  `coUserver` already has real, unmodified vendor-stock data wired for a wide
  swath of the item registry -- `ToolVendor.itemsForSale`
  (`coUserver/lib/entities/npcs/vendors/toolvendor.dart`),
  `MealVendor.itemsForSale`, and especially `StreetSpirit`'s per-category
  stock lists (`coUserver/lib/entities/npcs/vendors/vendor.dart`, switched on
  `vendors.json`'s real per-street `vendorType` assignment -- 865 streets
  across 9 categories: hardware, kitchen, groceries, toy, mining, produce,
  gardening, alchemical, animal).
  ~~None of these vendor NPC classes are currently placed/spawned anywhere in
  the live world (no street/hub seed data references them), so this real
  acquisition data is currently inert. Placing one vendor NPC per street
  (analogous to `tools/seed-demo-world.mjs`'s world-entity seeding, but for
  vendors) would make a large fraction of the item registry genuinely
  obtainable at once without any further per-item work.~~ Done 2026-08-28:
  `ToolVendor` and the 3 concrete real-art `StreetSpirit` subclasses
  (`StreetSpiritFirebog`/`Zutto`/`Groddle` -- not the abstract `StreetSpirit`
  base, which would crash on placement; see RECOVERY_TODO.md's "Vendor/harvest
  NPC family placement" row) are now placed by `tools/seed-demo-world.mjs` and
  verified live. `MealVendor` and the other named vendor NPCs
  (`jabba_helga.dart`, `jabba_unclefriendly.dart`, `snoconevendingmachine.dart`)
  remain unplaced -- out of scope for this pass, which covered only the 3
  classes with real converted art per CONTENT_RECOVERY_PLAN.md's asset-recovery
  tracking. Recipe data
  (`coUserver/lib/entities/items/actions/recipes/json/*.json`) is similarly
  real and wired but only reachable once a player owns the required tool.
- Some items have no acquisition route anywhere in the current codebase at
  all (not a placement gap, an actual missing design) -- e.g. `bacon` and
  `potion_rainbow_juice`, found while documenting the above batch's
  `content/runtime-manifest.json` rows. A systematic sweep of the item
  registry against vendor stock lists + recipe outputs + NPC harvest rewards
  would find the full set and is a prerequisite for RECOVERY_TODO.md's
  "Import/translate item, recipe, vendor, quest, and achievement graph" item.
- Found 2026-08-28 while converting a second batch (13 `croppery-gardening.json`
  crops -- broccoli/cabbage/carrot/corn/cucumber/onion/parsnip/potato/pumpkin/
  rice/spinach/tomato/zucchini): `coUserver/lib/entities/npcs/garden.dart`'s
  `Garden` NPC class is a third real, fully-implemented, currently-inert
  acquisition route (alongside `ToolVendor`/`StreetSpirit`) -- its `CROPS`
  list and `harvest()` method genuinely grant these 13 items, but no
  street/hub seed data spawns a `Garden` NPC anywhere, so it is real but
  unreachable in the live world, same placement gap as the vendor classes.
  12 of the 13 crops (all but pumpkin) are additionally real `produce`
  `StreetSpirit` vendor stock. Also confirmed this pass: `spices.json`'s
  16 spices (black_pepper, camphor, cardamom, cinnamon, cumin, curry, garlic,
  ginger, hot_pepper, licorice, mustard, nutmeg, older_spice, pinch_of_salt,
  saffron, turmeric) are ALL real, unmodified `spice_mill` recipe outputs
  from `allspice` (`coUserver/lib/entities/items/actions/recipes/json/
  spice_mill.json`).
  ~~Placing one `Garden` NPC per gardening-themed street (mirroring the
  proposed vendor-placement idea above) would make the crop-garden loop
  genuinely playable at once.~~ Done 2026-08-28: `Garden` is now placed by
  `tools/seed-demo-world.mjs` (~20% chance per street, boosted on
  `vendors.json` "gardening"/"produce" streets) and verified live; see
  RECOVERY_TODO.md's "Vendor/harvest NPC family placement" row.
- Done 2026-08-28 (third batch, same day as the crop batch above): converted
  icon/sprite art for all 16 non-`allspice` `spices.json` items, and
  re-verified the `spice_mill`-from-`allspice` recipe route directly rather
  than trusting the prior note. Found a more nuanced accessibility picture
  than the vendor/Garden placement gap documented above: `SpicePlant`
  (`coUserver/lib/entities/plants/trees/spiceplant.dart`), the world entity
  whose harvest grants the recipe's `allspice` input, **is** placed in the
  live world (`tools/seed-demo-world.mjs`'s `RARITY.SpicePlant`, 45% per
  street + a regional boost on uralia2/kajuu). [Update 2026-08-28: `Garden`,
  `ToolVendor`, and `StreetSpirit` (via its 3 concrete real-art subclasses)
  are now placed too -- see RECOVERY_TODO.md's "Vendor/harvest NPC family
  placement" row -- so the `spice_mill` tool needed for this recipe is a
  `ToolVendor`/`StreetSpirit`("kitchen") stock item on any street carrying
  one of those NPCs, same as `allspice` itself.] The remaining blocker for
  these 16 spices was narrower: the `spice_mill` tool itself is only sold by
  `ToolVendor`/`StreetSpirit`(`kitchen`), both previously confirmed inert
  (not instantiated anywhere outside their own class definitions) and now
  placed as noted above.
- Done 2026-08-28 (fourth batch, converted after the vendor/harvest NPC
  placement pass above, not before it like the spices batch): converted
  icon/sprite art for 15 `drinks.json` items. This is the first item-icon
  batch to directly benefit from that placement pass rather than merely
  document the gap it left -- beer/coffee (`groceries` StreetSpirit stock,
  86 streets) and earthshaker/face_smelter/flaming_humbaba (`mining`
  StreetSpirit stock, 42 streets) are now genuinely buyable wherever one of
  the 3 placed `StreetSpirit` subclasses lands on a matching-category
  street, and the `blender`/`cocktail_shaker`/`saucepan` tools needed for
  the batch's remaining recipe-output drinks are themselves real `kitchen`
  StreetSpirit stock (109 streets) -- the same "one hop already works"
  pattern the spices batch found for `spice_mill`, but for the tool itself
  this time, not just its plant input.
  Also found: two more real-but-entirely-unplaced acquisition routes,
  distinct in kind from the vendor/Garden gap above (these are individual
  NPC/entity classes, not a systemic vendor-family gap) -- `hooch` has
  both a `RespawningItem` world-entity harvestable (`HoochRespawningItem`,
  `coUserver/lib/entities/plants/respawning_items/hooch.dart`) and a
  standalone fermenting NPC-item (`Still`,
  `coUserver/lib/entities/npcs/items/still.dart`) that neither appear in
  `tools/seed-demo-world.mjs`; `crabato_juice` has a real reward chain on
  `Crab` (`coUserver/lib/entities/npcs/crab.dart`'s `playMusic()`) that is
  similarly never spawned. hooch in particular is a heavily-used recipe
  ingredient elsewhere (7 `tincturing_kit` essence recipes, 11 of 12
  `cocktail_shaker` recipes including several converted this same batch),
  so placing `HoochRespawningItem` or `Still` would unblock more than just
  the `hooch` item itself -- a good candidate for a future placement pass
  alongside `Garden`/`ToolVendor`/`StreetSpirit`.
  Done 2026-08-28: `HoochRespawningItem` (~25%/street), `Still` (~6%/street),
  and `Crab` (~22%/street) are now placed by `tools/seed-demo-world.mjs`
  and verified live (see RECOVERY_TODO.md's "Placement pass:
  hooch/purple_flower/crabato_juice" row) -- all four constructors were
  re-verified directly against `street.dart`'s reflective placement code
  before placing, not trusted from this note alone. Caveat carried
  forward: `HoochRespawningItem`/`Still` (unlike `Crab`) still render a
  broken on-map sprite -- only their item-icon art was ever converted,
  not their world-entity `Spritesheet`, which still points at a dead
  `childrenofur.com` URL; a separate future art-conversion item.
- Found 2026-08-28 (fifth batch, all 7 `herbalism.json` herbs + their 7
  seeds): a genuine *code* gap, not just a placement gap, distinct from
  everything found in prior batches. `HerbGarden`
  (`coUserver/lib/entities/npcs/garden.dart` line 556) extends `Garden`
  and carries its own herb-themed flavor text (`RESPONSES_HERB`), which
  reads as if it should grow herbs, but it never overrides
  `Garden.CROPS` or `ITEM_REQ_PLANT` -- both stay hardcoded to the same
  13 vegetable crops as the plain `Garden` class -- so `HerbGarden`
  cannot plant or harvest any herb even if it were placed in the world.
  Confirmed no `herbalism` vendor category exists anywhere in
  `vendor.dart`/`vendors.json` either (only `gardening`, 13 crop seeds,
  and `produce`, 13 crops). Net effect: 6 of the 7 herbs (gandlevery,
  hairball_flower, rookswort, rubeweed, silvertongue, yellow_crumb_flower)
  and all 7 herb seeds have no acquisition route of any kind in the
  current codebase -- the same "genuinely missing design" category as
  `bacon`/`potion_rainbow_juice`, not a placement gap that seeding could
  fix. The 7th herb, `purple_flower`, is the one exception:
  `PurpleFlowerRespawningItem`
  (`coUserver/lib/entities/plants/respawning_items/purple_flower.dart`)
  is a real, unmodified `RespawningItem` world-entity harvestable
  (3-minute respawn, same shape as `hooch`'s `HoochRespawningItem`) that
  was simply never referenced in `tools/seed-demo-world.mjs` -- unlike
  its 6 sibling herbs. Done 2026-08-28: now placed (~35% chance/street,
  maxCount 2) alongside `hooch`'s two routes, see RECOVERY_TODO.md's
  "Placement pass: hooch/purple_flower/crabato_juice" row; same
  still-dead-linked on-map sprite caveat as `HoochRespawningItem`/`Still`
  applies here too. All 7 herbs are real
  `tincturing_kit` recipe *inputs* (`essence_of_<herb>`) but never
  outputs, so that recipe file provides no acquisition route either.
  Fixing `HerbGarden` itself (adding a herb `CROPS`/`ITEM_REQ_PLANT` list,
  or a `herbalism` vendor category) is a candidate for the "Import/
  translate item, recipe, vendor, quest, and achievement graph" pass,
  not attempted here per the instruction to record routes honestly
  rather than invent or fix them.
- Found 2026-08-28 (sixth batch, scoped to `storage.json`/
  `advanced_resources.json`/`basic_resources.json`/`machines-fuel.json`
  to avoid colliding with other agents converting other categories in
  parallel): `vendor.dart`'s `pickItems(["Storage"])` helper (called by
  both `ToolVendor`'s constructor and the `hardware` `StreetSpirit`
  vendorType case) returns every item in the entire registry whose
  `category` field equals `"Storage"` -- i.e. it automatically stocks
  all 19 `storage.json` items (bags, toolboxes, the spice rack, the
  alchemistry kit, the firefly jar, etc.) with no per-item vendor code
  at all. Combined with the already-placed `ToolVendor`/`StreetSpirit`
  subclasses (see "Vendor/harvest NPC family placement" in
  RECOVERY_TODO.md), this means the *entire* `storage.json` category is
  already genuinely live-buyable today, not just the 3 items
  (alchemistry_kit, firefly_jar, spicerack) whose icon/sprite art was
  actually converted this pass -- the remaining 16 `storage.json` items
  have real matching source SWFs (confirmed by direct search under
  `tmp/glitch-items/misc/bag_*` and `misc/firefly_jar`) and are pure
  icon-conversion work away from being visually complete, not blocked on
  any further game-logic or placement work.
  Also found a real, substantial, fully-live crafting chain in
  `advanced_resources.json`: `ingot` (`smelter` + `chunk_metal`),
  `copper`/`tin`/`molybdenum` (`alchemical_tongs` + `ingot` + colored
  elements, themselves `grinder` outputs of `chunk_dullite`/
  `chunk_beryl`/`chunk_sparkly` + `cherry`), `thread` (`spindle` +
  `fiber`), `string`/`general_fabric` (`loomer` + `thread`), and
  `barnacle_talc` (`grinder` + `barnacle`) all trace end-to-end through
  real, unmodified recipes to raw-material world-entities (MetalRock,
  DulliteRock, BerylRock, SparklyRock, Fox, MortarBarnacle, FruitTree)
  and tools (smelter, alchemical_tongs, grinder, spindle, loomer) that
  are every one of them already placed in the live world -- this is a
  second, independent confirmation (after the spices/drinks batches)
  that the 2026-08-28 vendor/harvest NPC placement pass unlocked entire
  downstream recipe trees, not just the directly-placed NPCs' own stock.
  By contrast, `advanced_resources.json`'s other 10 items (beam, board,
  girder, metal_bar, metal_rod, plain_crystal, snail, urth_block,
  wood_post, bushel_of_grain) and `machines-fuel.json`'s `fuel_cell`
  were checked against every `recipes/json/*.json` file and every named
  vendor `itemsForSale`/vendorType case and confirmed to have **no
  acquisition route of any kind** -- genuinely missing design, same
  category as `bacon`/`potion_rainbow_juice`/6 of the 7 herbs, not a
  placement gap. `machines-fuel.json`'s other 9 items, however, ARE all
  real `ToolVendor`/`StreetSpirit(hardware)` stock (confirmed directly),
  same live route as the batch's own `machine_stand` -- another
  category, like `storage.json`, where the remaining unconverted items
  are pure icon-conversion work, not a blocked design/placement gap.
- Found 2026-08-28 (seventh batch, scoped to exactly `alchemical.json`/
  `collectibles.json`/`licenses-permits.json`/`tinctures-potions.json`
  to avoid colliding with other agents converting other categories in
  parallel), with a self-correction worth recording as a process note:
  an initial pass checked only `test_tube.json`/`beaker.json`/
  `alchemical_tongs.json`/`tincturing_kit.json` for where
  `red_element`/`green_element`/`blue_element`/`shiny_element` come
  from, found nothing, and wrongly concluded they had no acquisition
  route at all. Re-checking `grinder.json` (which the sixth batch's own
  note above already used for `copper`/`tin`/`molybdenum`, but this
  pass initially failed to cross-reference) found real
  `blue_element-grinder`/`green_element-grinder`/`red_element-grinder`/
  `shiny_element-grinder` recipes producing all 4 elements from
  `chunk_dullite`/`chunk_beryl`/`chunk_sparkly` (+ `cherry` for red) --
  the same DulliteRock/BerylRock/SparklyRock/FruitTree harvests already
  confirmed placed. So `abbasidose` (`test_tube`) and `fertilidust`
  (`beaker`, via element-derived `humbabol`/`potoxin`/`cosmox`) are
  genuinely live end-to-end (multi-hop: harvest rock/fruit -> grind ->
  test_tube -> beaker), corrected in `content/runtime-manifest.json`
  before this pass finished. Takeaway for future batches: always check
  every `recipes/json/*.json` file for a candidate output, not just the
  files whose tool name obviously matches the item's category -- a raw
  material can be produced by a recipe under an unrelated-sounding tool
  (here, alchemical raw materials came from `grinder`, a "mining/
  hardware" tool, not from any alchemy-named tool). Confirmed genuinely
  routeless in this same batch (recipe files and vendor `itemsForSale`
  lists checked directly, `grinder.json`-style cross-referencing
  included): `potion_amorous_philtre`, `potion_ancestral_spirits`,
  `potion_tree_poison` (tinctures-potions.json), `card_carrying_
  qualification` (whose only other reference, a same-named achievement
  in `player.json`, cannot grant items -- the achievements subsystem
  never calls any item-granting method anywhere, confirmed by grep),
  `fox_permit`, `general_building_permit`, `teleportation_script_
  imbued`, `teleportation_script`, `your_papers` (licenses-permits.json),
  and `wooden_apple`/`magical_pendant` (collectibles.json, spot-checked
  against several sibling `artifact_*`-sourced collectibles too, none of
  which turned up a route either). `essence_of_gandlevery` has a real
  `tincturing_kit` recipe (tool itself live) but is blocked by two
  already-documented gaps at once: `gandlevery` the herb has no route
  (the fifth batch's `HerbGarden` gap) and `hooch` was real-but-unplaced
  (now placed, see the placement-pass row above). One genuine exception
  found live: `note` -- `NoteManager.appEdit`
  (`coUserver/lib/entities/items/actions/note.dart`) consumes 1 `paper`
  and grants a `note` via a real HTTP route, auto-learning
  `penpersonship`; `paper` comes from the already-placed `PaperTree`.
- Found 2026-08-28 (world-entity art batch): 9 more `RespawningItem`
  world-entity classes now have real, converted, working on-map art but are
  not placed anywhere in `tools/seed-demo-world.mjs` -- the same
  real-but-unplaced pattern already fixed once for
  `HoochRespawningItem`/`PurpleFlowerRespawningItem`/`Still`/`Crab`.
  `AwesomeStewRespawningItem`, `ButterflyMilkRespawningItem`,
  `CinnamonRespawningItem`, `CoffeeRespawningItem`,
  `EarthshakerRespawningItem`, `FruityJuiceRespawningItem`, `HellGrapes`
  (grants `bunch_of_grapes`, plus a real `squish` energy-reward action),
  `HellTomato` (grants `tomato`), and `PlainBubbleRespawningItem`
  (`coUserver/lib/entities/plants/respawning_items/*.dart`) each inherit
  `RespawningItem`'s real, unmodified `pick up` action
  (`InventoryV2.addItemToUser` on a real item id, then a respawn timer) --
  confirmed by reading the base class directly, not assumed. A future
  placement pass extending `tools/seed-demo-world.mjs` the same way the
  hooch/purple_flower/still/crab pass did (RECOVERY_TODO.md's "Placement
  pass: hooch/purple_flower/crabato_juice" row) would make all 9 genuinely
  reachable at once. Not placed in this pass per its own scoping
  instruction not to modify `tools/seed-demo-world.mjs`.
- Found/closed 2026-08-28 (final world-entity art batch, RECOVERY_TODO.md's
  FOURTEENTH row): converted the last 9 world-entity classes this project
  had identified as having dead/missing on-map art --
  `DustTrap`/`Mailbox`/`GardeningGoodsVendor`
  (`coUserver/lib/entities/npcs/{dust_trap,mailbox,vendors/scarecrow}.dart`),
  4 `RespawningItem` growth-stage entities
  (`CocktailShakerRespawningItem`/`HotNFizzySauceRespawningItem`/
  `LaughingGasRespawningItem`/`NoNoPowderRespawningItem`), and the 2
  multi-skin item-triggered NPC families `Icon` (11 giant skins) and
  `RacingCubimal` (44 skins). Same real-but-unplaced-in-`seed-demo-world.mjs`
  finding as the bullet above for the first 3 NPCs and the 4
  `RespawningItem` classes (their matching player items are separately
  obtainable via vendor/recipe routes already documented in earlier
  batches, so only the ground-spawn harvest route itself is blocked).
  `Icon`/`RacingCubimal` turned out to have a materially better
  accessibility story on closer reading, worth calling out since it
  contradicts the "needs a placement pass" pattern every other
  `ITEM_ENTITIES`-adjacent finding in this file follows: both are
  dynamically spawned by a real, already-wired player item action, not by
  static world placement at all -- `icon_of_<giant>`'s `Place` action
  (`emblems-icons.json`) runs `Item.place()`
  (`coUserver/lib/entities/items/item.dart`) -> `EntityItem.place()`
  (`coUserver/lib/entities/npcs/items/entity_item.dart`), which looks up
  the item type in the real, unmodified `ITEM_ENTITIES` map and calls
  `StreetEntities.setEntity()` directly; `cubimal_<name>`'s `Race` action
  (`collectibles.json`) runs `Cubimal.race()`
  (`coUserver/lib/entities/items/actions/itemgroups/cubimals.dart`), which
  reads the same `ITEM_ENTITIES` map itself rather than going through
  `Item.place()`. Both confirmed by reading `item.dart`/`entity_item.dart`/
  `cubimals.dart` directly, not inferred from the map's existence. Both
  triggering items are themselves already live end-to-end: `icon_of_<giant>`
  via `Emblem.iconize()` (11x placed-Shrine-sourced `emblem_of_<giant>` ->
  1x icon, all 11 giants), and `cubimal_<name>` via
  `CubimalBox.takeOutCubimal` from a real, vendor-stocked
  `cubimal_series_1_box`/`cubimal_series_2_box` (43 of the 44 skins --
  `cubimal_factorydefect_chick` has real converted art now but still no
  box-drop-table entry, the same gap the TWELFTH item-icon batch already
  found and left open). Net effect: `tools/seed-demo-world.mjs` needs no
  change at all for `Icon`/`RacingCubimal` to render correctly in the live
  world; only `DustTrap`/`Mailbox`/`GardeningGoodsVendor` and the 4
  `RespawningItem` classes remain open placement-pass candidates from this
  batch. No other in-scope world-entity classes with dead/missing on-map
  art are known to remain as of this batch -- `content/runtime-manifest.json`
  now stands at 794 rows (9 new) and `content/source-manifest.json` gained
  62 new per-source-SWF entries (one per converted source file: 3
  multi-state NPCs + 4 single-state respawning items + 11 icon skins + 44
  cubimal skins); `tools/validate-content.mjs` still passes. **Placed
  2026-08-28, same day (RECOVERY_TODO.md's "Placement pass:
  DustTrap/Mailbox/GardeningGoodsVendor/4 respawning items" row)**: all 7
  of these open candidates added to `tools/seed-demo-world.mjs` and seeded
  live. Force-loading each live surfaced one genuine pre-existing bug
  (`GardeningGoodsVendor.SELL_ITEMS`'s over-strict `List<Map<String,
  dynamic>>` type vs. `Item.getMap()`'s untyped `Map` return, which also
  silently truncated that street's whole entity-load loop on failure), fixed
  with a type-annotation-only change to `scarecrow.dart`. All 7 re-verified
  constructing cleanly afterward, including `DustTrap`/`Mailbox` on their
  non-standard constructor-argument paths. No open placement-pass
  candidates remain from this batch.
- Found 2026-08-28 (eighth item-icon batch, scoped to `gasses-bubbles.json`/
  `herdkeeping.json`/`emblems-icons.json`/`quest_items.json`): independently
  hit and fixed the same `ffdec -export frame` opaque-backdrop defect
  described in the "Asset conversion pipeline" section below, on 13 of 16
  source SWFs (confirmed via PIL alpha-extrema check, `(255,255)` on every
  one before fixing). Rather than the chroma-key-with-decontamination
  approach used for the 129-file retroactive fix, or `-ignorebackground`
  (found by a parallel agent's own pass -- see below), this pass built and
  used a difference-matting tool (`tools/swf-patch-bgcolor.py` +
  `tools/swf-export-frame-alpha.py`): byte-patch the SWF's
  `SetBackgroundColor` tag to black, export the same frame against both the
  original white and the patched black backdrop, then solve
  `alpha = 1 - (C_white - C_black)/255` per pixel. **Cross-checked against
  `-ignorebackground` after the fact** (this section's own note below,
  found independently by a parallel agent converting different assets the
  same day): re-exported one of this batch's affected files
  (`crying_gas.swf`) with `-ignorebackground` and confirmed byte-for-byte
  visually identical output to the difference-matted version (both show
  genuine alpha extrema `(0,255)`, same checkerboard-composited preview).
  So `-ignorebackground` is confirmed to work for this batch's source
  family too, and is simpler (one export pass, no patched-SWF intermediate)
  -- recommended for future `-export frame` batches over either the
  chroma-key or difference-matting workaround. This pass's own 16 items
  were already fully converted via the matting tool before making this
  comparison, so were not redone; the matting tool is left in `tools/` as a
  documented working alternative (useful if `-ignorebackground` is ever
  found to misbehave on some source, since it needs no assumption about
  what "ignoring" the background actually renders as underneath).
- Found 2026-08-28 (`keys.json`/`misc.json` batch, RECOVERY_TODO.md's NINTH
  batch row): a third independent confirmation of the above -- hit the same
  opaque-background defect on this batch's sources, first tried
  `-ignorebackground` directly (worked, genuine `(0,255)` alpha on all 53
  items including the one with a non-white `SetBackgroundColor`, verified
  visually), then switched to the established `tools/swf-patch-bgcolor.py`
  + `tools/swf-export-frame-alpha.py` difference-matting tool instead for
  consistency with the rest of the pipeline once it was found already
  checked in mid-session by a parallel agent. Also found: the entire
  achievement system (`coUserver/lib/achievements/achievements.dart` +
  `achievement_checkers.dart`) has **zero item-grant code anywhere** --
  confirmed by grep, no call to `InventoryV2.addItemToUser` or any other
  grant API exists in either file. `coUserver/lib/achievements/json/
  trophies.json` only holds display metadata (name/description/a dead
  `c2.glitch.bz` `imageUrl`) for each achievement. This means every
  `*_trophy`/`*_music_trophy` item in the item registry (16 of them in
  `misc.json` alone: `bb_music_trophy`, `bubble_trophy`, `trophy_cubimal`,
  `trophy_cubimal_2`, `db_music_trophy`, `dg_music_trophy`,
  `dr_music_trophy`, `egg_hunter_trophy`, `emblem_trophy`, `fruit_trophy`,
  `gas_trophy`, `gem_trophy`, `spice_trophy`, the 4
  `street_creator_*_trophy` items, `xs_music_trophy`) has no acquisition
  route at all -- a systemic missing-design gap (wiring achievement
  completion to a real item grant), not a per-item placement gap, and worth
  fixing once rather than per-trophy. Separately: `coUserver/lib/entities/
  doors/` only has one concrete locked-door subclass
  (`ld_teal-white-triangle.dart`) out of the 12 keys in `keys.json`, and
  even that one class is never instantiated anywhere outside its own file
  -- so all 12 door keys are equally unreachable regardless of whether a
  matching door class exists. If door placement is ever added to
  `tools/seed-demo-world.mjs`-style seeding, `keys.json` would need either
  11 more door subclasses or a generalization of `LockedDoor` to take its
  required key as placement data instead of being hardcoded per-subclass.
- Found 2026-08-28 (eleventh item-icon batch, `toys.json`/`tools.json`/
  `alchemical.json`, RECOVERY_TODO.md's "Continue asset conversion" row):
  a distinct flavor of the "genuinely missing design" gap already
  documented above for achievements/`bacon`/`potion_rainbow_juice` --
  several `toys.json` items have an `actionName` in their item JSON
  (`"Insert Note"` on `fortune_cookie`, `"Break Cookie"` on
  `fortune_cookie_withfortune`, `"Read Fortune"` on `fortune`) that reads
  as if it should do something, but grepping every literal string under
  `coUserver/lib/entities/items/actions/` found no handler implementing
  any of them -- confirmed these are pure display metadata, same as
  `card_carrying_qualification`'s achievement-only reference from the
  seventh batch. This blocks not just the action but the *acquisition*
  route for a related item in one case: `fortune_cookie_withfortune`
  cannot be crafted from `fortune_cookie` + `note` because `"Insert
  Note"` has no handler, even though both ingredients are themselves
  real (`fortune_cookie` is live `toy`-`StreetSpirit` stock; `note` is a
  real `NoteManager.appEdit` HTTP-route item per the seventh batch's own
  finding). Also confirmed in this batch: `dice.dart` (the file, not the
  `dice`/`12_sided_die` items) is entirely commented-out dead code --
  the `"Roll"` action on both dice items has no live server
  implementation either, though this doesn't block *acquiring* either
  item (both are real `toy`-`StreetSpirit` stock), only what happens
  after. Also found 3 tools (`high_class_hoe`, `irrigator_9000`,
  `super_scraper`) that are real `tinkertool` recipe outputs but are
  *not* listed in `ToolVendor`/any `StreetSpirit` category themselves --
  i.e. craftable-only upgrades to their vendor-stocked base tools
  (`hoe`, `watering_can`, `scraper`), a legitimate design (not a gap),
  but worth noting as a different accessibility shape than the plain
  "vendor stock" pattern most other tools follow.
- Found 2026-08-28 (twelfth item-icon batch, `collectibles.json`,
  RECOVERY_TODO.md's "Continue asset conversion" row): a genuinely live,
  previously-undocumented route for 43 of `collectibles.json`'s 44
  `cubimal_*` items -- `CubimalBox.takeOutCubimal`
  (`coUserver/lib/entities/items/actions/itemgroups/cubimals.dart`)
  consumes a real, live, vendor-stocked `cubimal_series_1_box`/
  `cubimal_series_2_box` and grants a random named cubimal item directly
  to inventory, end to end. The 1 exception, `cubimal_factorydefect_chick`,
  has real converted art but is not a key in either series table, so it
  has no acquisition route despite looking identical in kind to its 43
  siblings -- worth a second look if a "rare/bonus cubimal" drop table is
  ever added elsewhere. Also confirmed the artifact-piece "assemble into
  a whole item" gap the seventh batch found for `wooden_apple`/
  `magical_pendant` extends to every sibling `artifact_*` family
  (necklaces/beads, hair clip, chicken brick, mysterious cube, mirror
  with scribbles, nose of china, platinumium spork, torn manuscript,
  glove with metal finger) and to the 20 `piece_of_street_creator_*_
  trophy_*` fragments (whose already-converted whole-trophy siblings in
  `misc.json` narratively describe collecting "all five parts" but have
  no code that actually does so) -- no "combine/assemble" item-action
  exists anywhere in `coUserver` for any multi-piece collectible.
  Confirmed a dead end worth not re-attempting: 19 `collectibles.json`
  items forming a coherent "wearable artifact accessory" sub-family
  (`button_shape_of_*` x4, `caterpillar_trousers`, `ear_trumpet`,
  `extremely_long_scarf`, `fake_nose_made_of_{plaster,wool}`, `fan`,
  `handbag_clasp`, `intricately_carved_wooden_ear`,
  `oversized_protective_goggles`, `pouch_full_of_old_seeds`,
  `remains_of_a_daybag`, `tangled_pair_of_sock_garters`,
  `three_cornered_hat`, `twenty_nine_cornered_hat`, `very_tall_top_hat`)
  have dead iconUrls but no matching source SWF anywhere under
  `tmp/glitch-items` (the `artifacts/` folder holds exactly 11 artifact
  families total, confirmed by a full directory listing, none of these);
  together with the file's pre-existing 20 empty-iconUrl items (also
  individually re-checked by item name this pass, no hits), these 39
  items cap `collectibles.json` at 173/212 real converted art given
  currently-vendored source material.

- Found 2026-08-28 (parallel batch: 7 sub-agents converting
  `tinctures-potions.json`/`croppery-gardening.json`/`emblems-icons.json`/
  `storage.json`/`herdkeeping.json`+`quest_items.json`+
  `basic_resources.json`+`misc.json`/`drinks.json`/
  `advanced_resources.json`+`machines-fuel.json`, 124 items total): two new
  generic, fully-live accessibility mechanisms confirmed, both worth reusing
  for future giant/emblem-adjacent or crop-seed-adjacent batches instead of
  re-deriving per item -- (1) `Shrine.donate()`
  (`coUserver/lib/endpoints/metabolics/metabolics.dart`) is genuinely generic
  across all 11 giants (reflects on `${giantName}Favor` fields), so any
  `emblem_of_<giant>` item is live once that giant's Shrine is placed (all 11
  are); (2) `Emblem.iconize()`
  (`coUserver/lib/entities/items/actions/itemgroups/emblems-icons.dart`) is
  likewise generic (derives `icon_of_X` from whichever `emblem_of_X` invoked
  it), so every `icon_of_<giant>` item is live the same way. Also confirmed:
  `Garden.ITEM_REQ_PLANT` + the live `gardening` `StreetSpirit` vendor
  category cover all 13 crop seeds (not just the 13 crops themselves, already
  documented in an earlier batch); and `Vendor.pickItems(["Storage"])`
  covers the entire remaining `storage.json` category the same way it was
  already shown to cover the first 3 items of that file.
- Found 2026-08-28 (same batch): several more genuinely-missing-design gaps
  (no acquisition route of any kind, not a placement gap) -- all 16
  `tinctures-potions.json` "potion" items (Charades Potion, Door Drink,
  Draught of Giant Amicability, Dung-Kicker Drops, Elixir of Avarice,
  Embiggenifying Potion (both directions), Keycutter Tonic, Liquid Super-Hoe,
  Manyharvest Cordial, Potion of Animal Youth, Rook Balm, Seed-Dibber
  Libation, Soak-All Solution, Trantsformation Fluid, Tree Poison Antidote);
  5 of the 6 herb-essence tincturing_kit outputs (`essence_of_purple` is the
  live exception, since its herb input `purple_flower` is placed -- the other
  5 are recipe-real but blocked on their own unroutable herb input, the same
  `HerbGarden` gap documented in an earlier batch); all 10
  `advanced_resources.json` items in this batch (`beam`, `board`,
  `bushel_of_grain`, `girder`, `metal_bar`, `metal_rod`, `plain_crystal`,
  `snail`, `urth_block`, `wood_post` -- re-verified against all 22 recipe
  files and every vendor stock mechanism, not just re-trusted from a prior
  note); `drinks.json`'s `wine_of_the_dead` (its only candidate grant path,
  `HellBartender.glassOfWine()`, is a stub with no `InventoryV2` call at all);
  and `herdkeeping.json`'s `fox_bait`/`hogtied_piggy` plus
  `quest_items.json`'s `juju_trowel`/`note_hint`. Real converted art now
  exists for all of these regardless.
- Found 2026-08-28 (same batch): `fox_bait`'s item-icon source SWF
  (`tmp/glitch-items/misc/fox_bait/fox_bait.swf`) has its real art in a
  nested `DefineSprite` with labeled `stink1`/`stink2`/`stink3` decay-state
  frames -- a strong candidate to resolve the separately-tracked world-entity
  `FoxBait` sprite gap (`coUserver/lib/entities/npcs/animals/fox.dart`,
  previously deferred for lack of an identified source) in a future pass;
  not attempted here since it was out of this batch's item-icon-only scope.
- Found 2026-08-28 (same batch): 4 items confirmed to have no matching
  source SWF after a targeted re-search each -- `musicblock_bag`/Crabpack,
  `user_made_quest`, `salmon_bubble`, `new_player_pack_butterfly`. All 4 DO
  have real, live, non-art acquisition routes despite the missing art:
  `Crab.buyCrabpack()` (`coUserver/lib/entities/npcs/crab.dart`),
  `QuestService.createQuestItem()`
  (`coUserver/lib/entities/items/actions/quest_service.dart`),
  `Salmon.pocket()`'s ~50%-miss branch
  (`coUserver/lib/entities/npcs/animals/salmon.dart`), and a real
  `tinkertool.json` recipe (`create_new_player_pack_butterfly`) respectively
  -- recorded in `content/runtime-manifest.json`'s `deliberatelyDeferred`
  with the art gap as the honest reason, not the (real) gameplay route.

## Asset conversion pipeline

- Found/fixed 2026-08-28 (live bug triage, see RECOVERY_TODO.md): every
  asset converted via `ffdec -export frame` (main-timeline rasterization,
  used whenever a source SWF's art sits directly on the root timeline
  rather than inside a named `DefineSprite`) comes out with the SWF's
  `SetBackgroundColor` stage color baked in as an opaque fill -- this is
  inherent ffdec CLI behavior (`lastExportTransparentBackground` config has
  no effect on it), not a one-off mistake, and affected 129 of the ~161
  converted source SWFs (every crop/spice/drink/herb/tool item icon plus
  several rocks and dirt pile). `tools/README-swf-pipeline.md`'s pipeline
  steps should be updated to document a required post-export chroma-key
  pass for any `-export frame` conversion: read the SWF's
  `SetBackgroundColor` tag directly (byte offset, no rendering -- see the
  tag-parsing helpers already in `tools/swf-frame-labels.py`), then
  soft-key that exact color out with a distance-based alpha ramp *and*
  color decontamination (unpremultiplying the background's contribution
  from partially-covered edge pixels -- a naive alpha-only key leaves a
  visible fringe on saturated background colors, confirmed on a
  purple-background asset). This was fixed ad hoc for all 129 existing
  affected sources in the same pass but is not yet a permanent step in
  `tools/build-sprite-sheet.py` or the documented pipeline -- a future
  conversion batch that uses `-export frame` on a new source SWF needs to
  apply the same chroma-key step by hand (or this gets automated into the
  scripts) or it will reproduce the same defect.
- Found 2026-08-28 (world-entity art batch, RECOVERY_TODO.md's "World-entity
  art: hooch/purple_flower/still finish, plus 9 new RespawningItem
  conversions" row): the same opaque-background export defect described in
  the bullet above can be avoided entirely, with no post-hoc chroma-key/
  fringe risk, by passing ffdec's `-ignorebackground` **pre-option** flag
  (`ffdec -ignorebackground -export frame ...` / `-export sprite ...`) --
  distinct from the `-config lastExportTransparentBackground=...` mechanism
  the bullet above found ineffective. Verified directly on 12 source SWFs in
  this batch: a first export without the flag reproduced the exact same
  defect (PIL alpha `getextrema()` of `(255,255)`/`(254,255)`); re-exporting
  the identical frame ranges with `-ignorebackground` produced genuine 0-255
  alpha and fully transparent `(0,0,0,0)` corners on every output, with
  identical frame geometry otherwise. Since this renders with no background
  fill in the first place (rather than removing a baked-in color after
  the fact), it should also sidestep the edge-fringe/color-decontamination
  problem the chroma-key approach has to solve. Worth re-testing against a
  few of the 129 already-fixed sources from the bullet above and, if it
  holds up broadly, adopting `-ignorebackground` in
  `tools/README-swf-pipeline.md`'s documented `-export frame`/`-export
  sprite` steps as the primary fix instead of (or in addition to) the
  chroma-key post-process -- not done here, out of scope for a
  world-entity-only pass, but flagged for whoever next touches the pipeline
  docs or `tools/build-sprite-sheet.py`.
- Found 2026-08-28 (TENTH batch, `food.json`, RECOVERY_TODO.md's TENTH row):
  every one of the 142 remaining dead-link `food.json` items had a matching
  source SWF under `tmp/glitch-items/food/` -- no sub-group was skipped for
  lack of source art. Used `ffdec -ignorebackground -export frame` directly
  (rather than the `swf-patch-bgcolor.py`/`swf-export-frame-alpha.py`
  matting tool) since this batch reconfirmed the EIGHTH/NINTH batches'
  finding that the flag is a verified-equivalent, simpler one-pass fix for
  this same main-timeline `DefineSceneAndFrameLabelData` source family;
  0 failures across 284 output PNGs (142 items x icon+sprite), each
  individually PIL-alpha-extrema-checked non-opaque before finalizing. New
  wrinkle worth flagging for future large batches: frame counts were NOT
  uniformly 5 like the spice/drink batches -- ranged 2 to 5 total
  main-timeline frames per item (`butterfly_butter`/`stinky_cheese`/
  `very_stinky_cheese`/`very_very_stinky_cheese` = 3, `fried_egg` = 4, ~26
  items = 2, the rest = 5) -- so a batch script for a new category should
  read the real exported frame count per item (e.g. from ffdec's own
  "Exported frame N/M" stdout line) rather than assuming a fixed
  icon+4-stack layout; `tools/batch-convert-food.py` (new this pass, ad hoc
  but reusable) does this generically. Of the 142, 30 were checked
  individually against every recipe file/vendor list/NPC harvest method and
  found to have **no acquisition route of any kind** in the current
  codebase (`death_to_veg`, `desssert_rub`, `glitchepoix`, `green`,
  `heston_mash`, `hot_potatoes`, `hototot_rub`, `hungry_nachos`,
  `kind_breakfurst_burrito`, `king_of_condiments`, `legumes_abbassidienne`,
  `luxury_tortellini`, `maburger_royale`, `naraka_flame_rub`, `onion_ring`,
  `pad_tii`, `pi`, `potcorn`, `potians_feast`, `pottine`,
  `precious_potato_salad`, `red`, `roux`, `salmon_jaella`, `stock_sauce`,
  `swank_zucchini_loaf`, `swing_batter`, `trump_rub`, `urfu`,
  `vegmageddon`) -- this is a genuine game-design gap (their only other
  reference anywhere in `coUserver` is the generic `actions/consume.json`
  Eat table), not a conversion or placement gap, so a future pass should
  not re-search for a route for these 30 without first writing new
  recipe/vendor/reward data for them. 5 more (`snocone_blue`/`green`/
  `orange`/`purple`/`red`) are real `SnoConeVendingMachine` vendor stock;
  that vendor class was not in `tools/seed-demo-world.mjs`'s
  `VENDOR_NPC_TYPES` at the time this batch was converted (same shape as
  the already-fixed `Still`/`HoochRespawningItem`/`PurpleFlowerRespawningItem`
  gap) -- fixed 2026-08-28 as this file's own quest completability audit's
  Q7 fix (see the Q7 section above and RECOVERY_TODO.md's "Placement pass:
  SnoConeVendingMachine (Q7 fix)" row); all 5 items are now genuinely
  live-buyable.

## Operations and reproducibility

- Add durable, structured application logs with rotation/retention; Docker logs
  currently provide diagnosis only while a container and its log history remain.
- Add health checks, restart policies, and a simple local smoke-check command.
- Pin base images and Dart archives (including checksums), commit compatible
  dependency snapshots, and avoid `pub get` on every service boot.
- Track the root Docker/vendor setup and vendor revision provenance in version
  control; keep generated `.dart_tool` files out of working changes.
- ~~Make server-status metrics work in the image (or replace shell metrics with
  native runtime metrics).~~ Done 2026-08-27: memory uses `ProcessInfo.currentRss`;
  CPU degrades silently to 0.0 when `ps` is unavailable in the image. Weather
  polling is also skipped when no OpenWeatherMap key is configured, removing a
  guaranteed 401 log entry per street load.

## Audio

- ~~Bundle appropriately licensed world music and reference local URLs in the
  music manifest; preserve SoundCloud only as an optional fallback.~~
  Done 2026-08-28: 15 region/hub ambient tracks recovered (YouTube playlist +
  existing zip album), converted to ogg, and wired as a local-file fallback in
  `SoundManager.loadSong()`; SoundCloud remains the fallback path for any
  key without a local file. See `content/music-manifest.json` and
  `RECOVERY_TODO.md`'s "Sound policy" row. Licensing is documented as an
  explicit caveat (fan-preserved, not officially re-hosted), not a resolved
  clean-rights claim.
- Fill the remaining `forest_slow` region gap (no confidently-matched
  source track found) and consider wiring the already-reserved `wintry`
  music.json key to the "Wintry Place" street via a `coUserver`
  `streetdata.json` per-street override, mirroring the existing
  `WintryPlaceHandler` buff special-case.
- Consider reintroducing the original per-region multi-track rotation
  (arrays of several tracks per hub, as in the 2013 game server's
  `ambient_library`) instead of today's one-track-per-key architecture, if
  more source tracks per region are ever recovered.
