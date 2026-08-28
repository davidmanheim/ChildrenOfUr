#!/usr/bin/env node
/*
 * Generates an idempotent, synthetic local-world seed covering every street
 * record in the bundled map data. CAT422 geometry is used when present; a
 * deterministic safe fallback is used for map records without geometry.
 * This is not recovered Children of Ur placement data.
 *
 * Usage (from repository root):
 *   node tools/seed-demo-world.mjs | docker compose exec -T postgres psql -U cou -d cou
 *
 * The script only emits INSERTs for `demo-` IDs in `street_entities`; it does
 * not include player, account, inventory, or production-derived data. As a
 * side effect (independent of the piped SQL) it also overwrites
 * content/placement-manifest.json's `placements`/`coverageSummary` to reflect
 * what this run seeds -- see the comment above that write for why it's a
 * bounded sample plus aggregate stats rather than a full row dump. Re-run
 * `node tools/validate-content.mjs` afterward to confirm the manifests are
 * still consistent.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const streets = JSON.parse(fs.readFileSync(
  path.join(root, 'coUserver', 'lib', 'common', 'mapdata', 'json', 'streetdata.json'), 'utf8'));
const hubs = JSON.parse(fs.readFileSync(
  path.join(root, 'coUserver', 'lib', 'common', 'mapdata', 'json', 'hubdata.json'), 'utf8'));
const locations = path.join(root, 'coUserver', 'CAT422', 'locations');
// streetdata.json's top-level keys are the actual street names (`Street.label`
// at runtime -- confirmed by reading coUserver/lib/streets/street.dart and
// coUserver/lib/common/mapdata/mapdata.dart's getStreetByName, which indexes
// _streets by this same key). vendors.json is keyed by that identical street
// name (862/865 of its keys match a streetdata.json key directly), and
// Vendor's constructor (coUserver/lib/entities/npcs/vendors/vendor.dart) reads
// `vendorTypes[streetName]` using the Street object's own `label` field --
// so a placed vendor NPC automatically gets the right stock category with no
// extra logic here; we only need the street name to apply a documented,
// grounded (not invented) Garden placement bias below.
const vendorTypeByStreetName = JSON.parse(fs.readFileSync(
  path.join(root, 'coUserver', 'lib', 'entities', 'npcs', 'vendors', 'vendors.json'), 'utf8'));

// Resolves a street's region/biome key exactly the way the client already
// does for world music (coUclient mapdata.dart's checkStringSetting: the
// street's own `music` field if set, else its hub's `music` field via
// `hub_id`, else the "forest" default) -- reusing that same recovered
// region data (see content/music-manifest.json) to theme placement instead
// of re-deriving a new region scheme from scratch.
function regionKey(streetData) {
  if (streetData.music) return streetData.music;
  const hub = hubs[String(streetData.hub_id)];
  return hub?.music || 'forest';
}

// Best-effort *thematic* rarity adjustment per region -- deliberate creative
// judgment (per explicit user direction), not recovered historical
// placement data. Like every other `demo-` row, this must never be
// presented as authentic; it exists only to make different areas feel
// different instead of every street carrying an identical roster.
// Multipliers apply to a type's base RARITY.chance above; a region/type
// combination not listed here keeps the base rate unchanged. `jal` and
// `nottis` are intentionally left un-themed: no confident thematic read on
// either from the data available, and guessing was exactly what the user
// asked this project not to do with placement.
const REGION_THEME = {
  // Bog/swamp: bubbles fit thematically; farm animals don't.
  firebog: { BubbleTree: 1.8, Salmon: 1.8, Chicken: 0.4, Piggy: 0.4, MetalRock: 0.5 },
  // Caverns: rock and (underground pool) fish over surface flora/flyers.
  cave: { MetalRock: 2.2, Salmon: 1.6, WoodTree: 0.3, BeanTree: 0.3, BubbleTree: 0.3,
    FruitTree: 0.3, PaperTree: 0.3, Butterfly: 0.3, Batterfly: 0.3, HeliKitty: 0.3 },
  ilmenskie: { MetalRock: 2.2, Salmon: 1.6, WoodTree: 0.3, BeanTree: 0.3, BubbleTree: 0.3,
    FruitTree: 0.3, PaperTree: 0.3, Butterfly: 0.3, Batterfly: 0.3, HeliKitty: 0.3 },
  // Elevated grassland: good grazing, fewer big trees.
  highlands: { Chicken: 1.5, Piggy: 1.5, Fox: 1.5, WoodTree: 0.7, BeanTree: 0.7,
    BubbleTree: 0.7, FruitTree: 0.7, PaperTree: 0.7 },
  // Pastoral/farmland zones.
  uralia2: { Chicken: 1.6, Piggy: 1.6, WoodTree: 1.3, BeanTree: 1.3, FruitTree: 1.3 },
  kajuu: { Chicken: 1.6, Piggy: 1.6, WoodTree: 1.3, BeanTree: 1.3, FruitTree: 1.3 },
  // Ix: strange/artificial zone -- sparse ordinary life, exotic rarity up.
  ix: { WoodTree: 0.3, Chicken: 0.3, Piggy: 0.3, MetalRock: 0.3, BeanTree: 0.3,
    BubbleTree: 0.3, FruitTree: 0.3, PaperTree: 0.3, Fox: 0.3, HeliKitty: 0.3, Salmon: 0.3,
    Butterfly: 0.3, Batterfly: 0.3, SilverFox: 2.5 },
  // Hell: harsh territory -- sparse life generally, volcanic rock up.
  hell: { WoodTree: 0.3, Chicken: 0.3, Piggy: 0.3, BeanTree: 0.3, BubbleTree: 0.3,
    FruitTree: 0.3, PaperTree: 0.3, HeliKitty: 0.3, Butterfly: 0.3, Batterfly: 0.3, Salmon: 0.3,
    MetalRock: 1.4, Fox: 1.2 },
  // Fungal/mushroom hubs: less woody growth, fewer farm animals.
  urwok: { WoodTree: 0.4, BeanTree: 0.4, BubbleTree: 0.4, FruitTree: 0.4, PaperTree: 0.4, Chicken: 0.5, Piggy: 0.5 },
  kloroandhaoma: { WoodTree: 0.4, BeanTree: 0.4, BubbleTree: 0.4, FruitTree: 0.4, PaperTree: 0.4, Chicken: 0.5, Piggy: 0.5 },
  // Ancestral/spiritual zones: creature-with-a-mystical-vibe bias.
  ancestral: { Fox: 1.6, HeliKitty: 1.6, SilverFox: 1.8 },
  // Woodland (the default region for untagged hubs too): wildlife-friendly.
  forest: { Fox: 1.3, Butterfly: 1.3, Batterfly: 1.3, HeliKitty: 1.3 },
  forest_slow: { Fox: 1.3, Butterfly: 1.3, Batterfly: 1.3, HeliKitty: 1.3 },
  // Enchanted (the 3 streets with a real, already-recovered per-street
  // override, per content/music-manifest.json): magical-forest boost.
  enchanted: { WoodTree: 1.8, BeanTree: 1.8, BubbleTree: 1.8, FruitTree: 1.8, PaperTree: 1.8,
    Butterfly: 1.8, Batterfly: 1.5, SilverFox: 2 },
};
// Region theming for the second (rock/plant/tree) harvestable batch --
// merged into REGION_THEME so a region's entry carries both batches' biases
// without duplicating the table structure.
for (const [region, adjustments] of Object.entries({
  // Mining tiers (beryl/dullite/sparkly rock) and mortar barnacles (cling to
  // rock) belong wherever MetalRock already concentrates.
  cave: { BerylRock: 2.5, DulliteRock: 2.5, SparklyRock: 2.5, MortarBarnacle: 2, IceNubbin: 1.6 },
  ilmenskie: { BerylRock: 2.5, DulliteRock: 2.5, SparklyRock: 2.5, MortarBarnacle: 2, IceNubbin: 1.6 },
  // Bog: jellisac/peat are bog resources by name; gas plant (swamp gas) fits.
  // StreetSpiritFirebog is a genuinely regional asset here too -- its source
  // SWF and class name (coUserver/lib/entities/npcs/vendors/streetspiritfirebog.dart)
  // are explicitly the Firebog street spirit, not a guess.
  firebog: { Jellisac: 2, PeatBog: 2.2, GasPlant: 1.6, StreetSpiritFirebog: 9 },
  // Farmland/pastoral: egg plant fits alongside the other farm-style crops.
  uralia2: { EggPlant: 1.4, SpicePlant: 1.3 },
  kajuu: { EggPlant: 1.4, SpicePlant: 1.3 },
  // Ix/Hell: same "ordinary life suppressed" logic as the first batch.
  ix: { BerylRock: 0.4, DulliteRock: 0.4, SparklyRock: 0.4, DirtPile: 0.4, IceNubbin: 0.4,
    Jellisac: 0.4, MortarBarnacle: 0.4, PeatBog: 0.4, EggPlant: 0.4, GasPlant: 0.4, SpicePlant: 0.4 },
  hell: { BerylRock: 0.4, DulliteRock: 0.4, SparklyRock: 0.4, DirtPile: 0.4, IceNubbin: 0.4,
    Jellisac: 0.4, MortarBarnacle: 0.4, PeatBog: 0.4, EggPlant: 0.4, GasPlant: 0.4, SpicePlant: 0.4 },
})) {
  REGION_THEME[region] = { ...(REGION_THEME[region] ?? {}), ...adjustments };
}
// StreetSpiritZutto and StreetSpiritGroddle get no region theme: no confident
// biome association was found for either in any recovered data (same "don't
// guess" rule already applied to the giant shrines above) -- see the RARITY
// table below for their flat rates instead.
// Shrines are deliberately NOT region-themed: no confident giant-to-biome
// association exists in any data recovered so far (the 11 giants' regional
// SWF variants -- Firebog/Ix/Uralia reskins -- are a rendering detail, not a
// placement rule), and guessing one would be exactly the kind of
// unsupported claim this project's placement rules forbid. They get a flat,
// deliberately sparse rate everywhere instead (see RARITY below).
// Quoins (collectibles) are placed one-of-each-always, unchanged from the
// original design. `WoodTree`/`Chicken`/`Piggy`/`MetalRock`/`Fox`/`SilverFox`/
// `HeliKitty`/`Salmon`/`Butterfly`/`Batterfly`/`BeanTree`/`BubbleTree`/
// `FruitTree`/`PaperTree` are real official-art entities (see
// CONTENT_RECOVERY_PLAN.md's asset-recovery pass; provenance in
// content/source-manifest.json) placed with deterministic, geometry-aware --
// not historically recovered -- positions, and a VARIED per-street subset
// (see the RARITY table below) rather than every type on every street.
// `DemoWheat` (like the already-retired `DemoTree`/`DemoChicken` before it)
// is a hand-drawn placeholder class with no real item/action behind it --
// coUserver/lib/entities/plants/demo_plants.dart documents it as an
// "intentionally non-harvestable" offline visual stand-in. It is no longer
// seeded at all (removed 2026-08-28, see RECOVERY_TODO.md): unlike
// DemoTree/DemoChicken it was never superseded by a converted real-art
// entity, since no matching "wheat" source SWF or item exists in
// tmp/glitch-items/ or the item registry to replace it with. The
// `demo_plants.dart` class itself is left in place (same as `DemoTree`)
// since it's harmless dead code, not something rendered in the live world.
const QUOIN_TYPES = ['Img', 'Mood', 'Energy', 'Currant', 'Mystery', 'Favor'];
const SHRINE_TYPES = ['Alph', 'Cosma', 'Friendly', 'Grendaline', 'Humbaba', 'Lem', 'Mab',
  'Pot', 'Spriggan', 'Tii', 'Zille'];
// Vendor/harvest NPC family (third asset-conversion batch): Garden.CROPS and
// its harvest() route, ToolVendor.itemsForSale, and the per-street-category
// StreetSpirit vendor stock (vendors.json) are all real, unmodified game
// logic with real converted art, but were never placed anywhere -- see
// RECOVERY_TODO.md/POTENTIAL_TODO.md "Item economy". Deliberately NOT
// included: the abstract `StreetSpirit` base class itself. It has no `states`
// map and never calls setState() (only its concrete subclasses do), so its
// inherited update() would dereference a null `currentState` and crash the
// first simulate tick after placement -- confirmed by reading
// coUserver/lib/entities/npcs/vendors/street_spirit.dart and
// coUserver/lib/streets/street.dart's putEntitiesInMemory. The 3 concrete,
// real-art subclasses (StreetSpiritFirebog/Zutto/Groddle) are used instead.
// SnoConeVendingMachine (coUserver/lib/entities/npcs/vendors/
// snoconevendingmachine.dart) added 2026-08-28 (see POTENTIAL_TODO.md's
// "Quest completability audit": it's the only source of any `snocone_*`
// item anywhere in the codebase, and Q7 "Snocone Joy" requires buying one).
// Constructor signature re-verified directly against street.dart's
// reflective placement code before adding, not trusted from the quest-audit
// note alone: `SnoConeVendingMachine(String id, String streetName, String
// tsid, num x, num y, num z, num rotation, bool h_flip)` matches the exact
// `[id, label, tsid, x, y, z, rotation, h_flip]` argument order
// `putEntitiesInMemory` uses for every `Vendor` subclass, identical in
// shape to the already-placed `ToolVendor`. Its own on-map appearance art
// (idle_stand/walk_left/walk_right/walk_end/talk/attract) is real and
// already converted (`files/sprites/generated/converted/sno_cone-*.png`,
// confirmed present under coUclient/web/ and referenced directly by the
// class's own `states` map) -- unlike the Hooch/PurpleFlower/Still
// precedent, this is NOT a dead-linked-sprite placement; both the NPC's
// world sprite and its catalog's `snocone_blue/green/orange/purple/red`
// item icons were already converted in an earlier item-icon batch.
// GardeningGoodsVendor (coUserver/lib/entities/npcs/vendors/scarecrow.dart --
// the file is misnamed; the actual class is GardeningGoodsVendor, confirmed
// by grep, no `class Scarecrow` exists anywhere in coUserver) added
// 2026-08-28 alongside DustTrap/Mailbox/the 4 respawning items below (see
// POTENTIAL_TODO.md's quest-completability audit and RECOVERY_TODO.md --
// real, unmodified game logic and real converted art, just never placed).
// Confirmed by reading the class directly: `class GardeningGoodsVendor
// extends Vendor`, constructor `(String id, String streetName, String tsid,
// num x, num y, num z, num rotation, bool h_flip)` -- an exact match for the
// `[id, label, tsid, x, y, z, rotation, h_flip]` args `putEntitiesInMemory`
// uses for every `Vendor` subclass, identical in shape to Garden/ToolVendor
// above. It stocks hoe/watering_can/13 crop seeds (SELL_ITEMS) -- exactly
// the "gardening" vendorCategory's own definition (hoe/watering_can/seeds a
// garden needs, per the comment below), so it shares Garden's gardening-
// street placement boost (see gardenVendorBoost below); it does not stock
// produce, so it does NOT get the produce boost Garden also gets.
//
// DustTrap (coUserver/lib/entities/npcs/dust_trap.dart) is NOT a Vendor
// subclass (`class DustTrap extends NPC implements EventHandler<...>`), but
// is grouped here rather than in NPC_ITEM_TYPES because street.dart's
// `putEntitiesInMemory` special-cases it (`classMirror == findClassMirror
// ("DustTrap")`) to receive the exact same Vendor-shaped construction args
// as every type in this list, confirmed directly: DustTrap's constructor is
// `(String id, String streetName, this.tsid, num x, num y, num z, num
// rotation, bool h_flip)` -- matching `[id, label, tsid, x, y, z, rotation,
// h_flip]` exactly, not the plain-NPC `[id, x, y, z, rotation, h_flip,
// label]` shape NPC_ITEM_TYPES' Still/Crab use. No server-side code change
// was needed -- street.dart's special case already exists and was verified
// live (see RECOVERY_TODO.md/POTENTIAL_TODO.md for the verification note).
const VENDOR_NPC_TYPES = ['Garden', 'ToolVendor',
  'StreetSpiritFirebog', 'StreetSpiritZutto', 'StreetSpiritGroddle',
  'SnoConeVendingMachine', 'GardeningGoodsVendor', 'DustTrap'];
// Fourth/fifth drinks/herbalism conversion batches (see RECOVERY_TODO.md
// "Continue asset conversion") documented three real, unmodified, working
// acquisition routes that were simply never placed here -- confirmed directly
// by reading each class (not trusted from the prior batch note alone):
// `HoochRespawningItem` and `PurpleFlowerRespawningItem`
// (coUserver/lib/entities/plants/respawning_items/{hooch,purple_flower}.dart)
// are real `RespawningItem` (-> Plant) world-entity harvestables with the
// same constructor shape as the already-placed harvestable types above;
// `Crab` (coUserver/lib/entities/npcs/crab.dart) is a real NPC whose
// `playMusic()` action rewards `crabato_juice`. `Still`
// (coUserver/lib/entities/npcs/items/still.dart) is a real `EntityItem` (->
// NPC) that ferments corn/grain/potato/rice into hooch over time. All four
// use the exact `(id, x, y, z, rotation, h_flip, streetName)` constructor
// signature `street.dart`'s reflective placement code expects, and all four
// source files are already `part of entity;` in entity.dart, so no
// server-side code changes are needed to place them -- only this list.
// Unlike the batch above, `HoochRespawningItem`/`PurpleFlowerRespawningItem`/
// `Still` still point their own on-map Spritesheet at dead
// `https://childrenofur.com/...` URLs (only their *item-icon* art was
// converted in the drinks/herbalism batches, not their world-entity sprite);
// placing them makes their gameplay logic (harvest/ferment/reward) genuinely
// reachable, but their in-world sprite will render broken until a future
// pass converts that art too -- see RECOVERY_TODO.md. `Crab` already has
// real converted world-entity sprites (files/sprites/generated/converted/
// crab-*.png) from its own prior conversion batch, so it renders correctly.
// CocktailShakerRespawningItem/HotNFizzySauceRespawningItem/
// LaughingGasRespawningItem/NoNoPowderRespawningItem (coUserver/lib/entities/
// plants/respawning_items/{cocktail_shaker,hot_n_fizzy_sauce,laughing_gas,
// nonopowder}.dart -- note the last file is `nonopowder.dart`, not
// `no_no_powder.dart`) added 2026-08-28. All four are confirmed `class
// XRespawningItem extends RespawningItem` (RespawningItem itself `extends
// Plant`), constructor `(String id, num x, num y, num z, num rotation, bool
// h_flip, String streetName)` -- the same plain Plant-branch
// `[id, x, y, z, rotation, h_flip, label]` args as
// Hooch/PurpleFlowerRespawningItem above. Unlike Hooch/PurpleFlower, all
// four already have real converted on-map Spritesheet art (see
// content/runtime-manifest.json's cocktail_shaker/hot_n_fizzy_sauce/
// gas_laughing/no_no_powder entries -- "status": "converted", no dead-link
// caveat), so placing them makes both the art and the real
// pick-up-grants-item gameplay logic reachable at once.
const RESPAWNING_ITEM_TYPES = ['HoochRespawningItem', 'PurpleFlowerRespawningItem',
  'CocktailShakerRespawningItem', 'HotNFizzySauceRespawningItem',
  'LaughingGasRespawningItem', 'NoNoPowderRespawningItem'];
// Mailbox (coUserver/lib/entities/npcs/mailbox.dart) added 2026-08-28:
// confirmed `class Mailbox extends NPC` (not Vendor, not the DustTrap
// special case), constructor `(String id, num x, num y, num z, num
// rotation, bool h_flip, String streetName)` -- the plain NPC-branch
// `[id, x, y, z, rotation, h_flip, label]` args, identical in shape to
// Still/Crab. Its 'check for mail'/'view inbox' actions and the real
// /getMail, /sendMail, /collectItem, /collectCurrants, /deleteMail,
// /readMail HTTP routes are all real, unmodified, unchanged game logic --
// placing it is the only missing piece for the messaging system to be
// reachable at all.
const NPC_ITEM_TYPES = ['Still', 'Crab', 'Mailbox'];
const REAL_TYPES = ['WoodTree', 'Chicken', 'Piggy', 'MetalRock',
  'Fox', 'SilverFox', 'HeliKitty', 'Salmon', 'Butterfly', 'Batterfly',
  'BeanTree', 'BubbleTree', 'FruitTree', 'PaperTree',
  'BerylRock', 'DulliteRock', 'SparklyRock',
  'DirtPile', 'IceNubbin', 'Jellisac', 'MortarBarnacle', 'PeatBog',
  'EggPlant', 'GasPlant', 'SpicePlant',
  ...SHRINE_TYPES, ...VENDOR_NPC_TYPES, ...RESPAWNING_ITEM_TYPES, ...NPC_ITEM_TYPES];
const types = [...QUOIN_TYPES, ...REAL_TYPES]; // still used for the manifest's total-type-count text

// Per-street inclusion chance (0-100) and max instance count for each real
// type. Placing every type on every street uniformly (the old behavior) made
// all ~3,180 streets look identical -- confirmed by direct user feedback
// ("the set of items in the world seems limited and very repetitive").
// This gives each street a varied, still-deterministic subset instead: each
// type independently rolls whether it appears at all, and if so, whether a
// second instance does too. Common resources (trees, farm animals) show up
// on roughly half of streets; less-common animals on under a third;
// SilverFox (a color-variant rarity, not a distinct species) rarest of all.
const RARITY = {
  WoodTree: { chance: 50, maxCount: 2 }, Chicken: { chance: 50, maxCount: 2 },
  Piggy: { chance: 50, maxCount: 2 },
  MetalRock: { chance: 50, maxCount: 2 },
  BeanTree: { chance: 45, maxCount: 2 }, BubbleTree: { chance: 45, maxCount: 2 },
  FruitTree: { chance: 45, maxCount: 2 }, PaperTree: { chance: 45, maxCount: 2 },
  Fox: { chance: 30, maxCount: 1 }, HeliKitty: { chance: 30, maxCount: 1 },
  Salmon: { chance: 30, maxCount: 1 }, Butterfly: { chance: 30, maxCount: 1 },
  Batterfly: { chance: 30, maxCount: 1 },
  SilverFox: { chance: 10, maxCount: 1 },
  // Mining-tier rocks: rarer than MetalRock (50%), escalating with tier.
  BerylRock: { chance: 22, maxCount: 1 }, DulliteRock: { chance: 16, maxCount: 1 },
  SparklyRock: { chance: 10, maxCount: 1 },
  // Ground-resource plants: similar tier to the animal group above.
  DirtPile: { chance: 40, maxCount: 2 }, IceNubbin: { chance: 25, maxCount: 1 },
  Jellisac: { chance: 25, maxCount: 1 }, MortarBarnacle: { chance: 25, maxCount: 1 },
  PeatBog: { chance: 25, maxCount: 1 },
  // Harvestable trees: same common tier as bean/bubble/fruit/paper.
  EggPlant: { chance: 45, maxCount: 2 }, GasPlant: { chance: 45, maxCount: 2 },
  SpicePlant: { chance: 45, maxCount: 2 },
  // Giant shrines: deliberately sparse landmarks, not common flora/fauna --
  // the user asked for "more" shrines (there were previously zero placed at
  // all), not one on every street. At 5% across ~3,180 streets and 11
  // giants, each giant gets roughly 150-200 shrines world-wide: findable,
  // still special. No region theming (see REGION_THEME comment above) and
  // never more than one of a given giant on the same street.
  ...Object.fromEntries(SHRINE_TYPES.map(t => [t, { chance: 5, maxCount: 1 }])),
  // Vendor/harvest NPCs: useful/valuable, not decorative flora/fauna, so
  // deliberately rarer than the common-tier animals/trees (45-50%) above,
  // but still common enough that a player exploring a handful of streets
  // will reliably find one of each -- these are also each capped at a
  // single instance per street (a second garden/vendor on the same street
  // adds nothing but clutter).
  Garden: { chance: 20, maxCount: 1 },
  ToolVendor: { chance: 12, maxCount: 1 },
  // StreetSpiritFirebog's flat baseline stays low everywhere (see the
  // REGION_THEME firebog entry above, which raises it to ~36% there); Zutto
  // and Groddle get no regional read (no confident association found in any
  // recovered data -- same rule as the shrines), so a single flat rate
  // applies everywhere instead of inventing a theme. Groddle is the
  // "generic" street-spirit skin (its giant costume auto-matches whichever
  // shrine, if any, is on the same street, or picks randomly) so it's given
  // a slightly higher baseline than the two single-region variants.
  StreetSpiritFirebog: { chance: 4, maxCount: 1 },
  StreetSpiritZutto: { chance: 12, maxCount: 1 },
  StreetSpiritGroddle: { chance: 15, maxCount: 1 },
  // HoochRespawningItem/PurpleFlowerRespawningItem: ordinary ground-resource
  // harvestables (same RespawningItem shape as the mining-tier
  // rocks/plants above), not decorative flora -- placed at that same
  // general tier. PurpleFlowerRespawningItem respawns fast (3 min, vs.
  // Hooch's 7 min) so it can support the DirtPile-tier common rate;
  // HoochRespawningItem (found alcohol lying on the ground) is themed as a
  // rarer "find" than an ordinary flower, closer to the
  // IceNubbin/Jellisac/MortarBarnacle/PeatBog tier. No REGION_THEME entry
  // for either: no confident biome association was found in any recovered
  // data for either item (same "don't guess" rule already applied to the
  // shrines/StreetSpiritZutto/Groddle above).
  HoochRespawningItem: { chance: 25, maxCount: 1 },
  PurpleFlowerRespawningItem: { chance: 35, maxCount: 2 },
  // Still: a stationary fermenting "structure" NPC, not wildlife/flora --
  // rarer than ToolVendor (12%), same tier logic as the giant shrines'
  // "landmark, not commodity" reasoning above. No REGION_THEME entry: no
  // confident biome read for it either.
  Still: { chance: 6, maxCount: 1 },
  // Crab: a wandering novelty NPC (musicblock "DJ"), same general tier as
  // the other wildlife-ish creature NPCs above (Fox/HeliKitty/Salmon,
  // 30%/maxCount 1) but slightly rarer since it's a single distinctive
  // character rather than a species. No REGION_THEME entry: no confident
  // biome/beach association was found in any recovered data for it (same
  // "don't guess" rule as everything else above).
  Crab: { chance: 22, maxCount: 1 },
  // SnoConeVendingMachine: a useful specialty vendor (real converted art,
  // see the VENDOR_NPC_TYPES comment above), not a common decoration --
  // same "landmark/specialty" tier as ToolVendor (12%), but narrower still:
  // its catalog is fixed at exactly 5 sno-cone-flavor items (vs.
  // ToolVendor's broad tool/machine catalog), closer in scope to Still's
  // single-purpose niche (6%). Split the difference. No REGION_THEME entry:
  // `vendors.json`'s 9 vendor categories (gardening/produce/alchemical/
  // hardware/kitchen/groceries/toy/animal/mining) include no "snocone" or
  // related category, so there's no grounded per-region signal to theme on
  // (checked directly, same "don't guess" rule as the shrines/
  // StreetSpiritZutto/Groddle above) -- a flat rate applies everywhere.
  SnoConeVendingMachine: { chance: 10, maxCount: 1 },
  // DustTrap: a stationary "prank" structure (a hidden trap that smacks
  // down and grants a random paper/bun or a miss) -- same "landmark
  // structure, not commodity" tier as Still (6%), per direct user guidance.
  // No REGION_THEME entry: no confident biome read found for it either.
  DustTrap: { chance: 6, maxCount: 1 },
  // Mailbox: a stationary utility structure (enables the real player-to-
  // player messaging system) -- same tier as Still/DustTrap (6%) per direct
  // user guidance, even though its utility purpose could argue for higher;
  // ~190 mailboxes across ~3,180 streets is still reliably reachable. No
  // REGION_THEME entry: no confident biome read found for it.
  Mailbox: { chance: 6, maxCount: 1 },
  // GardeningGoodsVendor: a specialty vendor (real converted art, see the
  // VENDOR_NPC_TYPES comment above) -- split the difference between
  // SnoConeVendingMachine (10%) and ToolVendor (12%) for its flat base rate,
  // then boosted on "gardening"-category streets the same way Garden is
  // (see gardeningGoodsVendorBoost below) since its stock (hoe/watering_can/
  // 13 seeds) is exactly that category's own definition -- a real, grounded
  // per-street signal, not an invented heuristic. No general REGION_THEME
  // entry: the gardening-category boost already covers the one genuine
  // signal found for it.
  GardeningGoodsVendor: { chance: 11, maxCount: 1 },
  // CocktailShakerRespawningItem/HotNFizzySauceRespawningItem/
  // LaughingGasRespawningItem/NoNoPowderRespawningItem: ground-resource
  // harvestables (same RespawningItem shape as Hooch/PurpleFlower above),
  // tiered by each item's own in-code respawnTime -- the same grounded
  // "how special is this meant to be" signal the Hooch/PurpleFlower comment
  // above already uses (a short respawnTime supports a common rate; a long
  // one signals a deliberately rarer find). No REGION_THEME entry for any
  // of the four: no confident biome association was found for any of them
  // in any recovered data (same "don't guess" rule as everything else
  // above).
  // NoNoPowderRespawningItem: respawnTime 30s, the fastest of the four by
  // far -- placed at PurpleFlower's common tier (35%).
  NoNoPowderRespawningItem: { chance: 35, maxCount: 2 },
  // LaughingGasRespawningItem: respawnTime 3min, same as PurpleFlower's own
  // respawnTime -- same general tier, just below it since "gas" reads as a
  // slightly less mundane find than a flower.
  LaughingGasRespawningItem: { chance: 30, maxCount: 2 },
  // HotNFizzySauceRespawningItem: respawnTime 6min, close to Hooch's 7min --
  // placed at Hooch's tier.
  HotNFizzySauceRespawningItem: { chance: 25, maxCount: 1 },
  // CocktailShakerRespawningItem: respawnTime 45min -- 6-15x slower than the
  // other three, and it grants a tool item (cocktail_shaker) rather than a
  // consumable ingredient, both signaling a deliberately much rarer ground
  // find. Placed at ToolVendor's specialty tier (12%) instead of the
  // common-ingredient tier the other three respawning items above get.
  CocktailShakerRespawningItem: { chance: 12, maxCount: 1 },
};

// Maps each seeded `type` to its content/runtime-manifest.json asset id, for
// content/placement-manifest.json provenance rows (see generatePlacementManifest below).
const RUNTIME_ASSET_ID = {
  Img: 'quoin-collectibles', Mood: 'quoin-collectibles', Energy: 'quoin-collectibles',
  Currant: 'quoin-collectibles', Mystery: 'quoin-collectibles', Favor: 'quoin-collectibles',
  WoodTree: 'wood_tree', Chicken: 'chicken',
  Piggy: 'piggy', MetalRock: 'metalrock',
  Fox: 'fox', SilverFox: 'silverfox', HeliKitty: 'helikitty', Salmon: 'salmon',
  Butterfly: 'butterfly', Batterfly: 'batterfly',
  BeanTree: 'bean_tree', BubbleTree: 'bubble_tree', FruitTree: 'fruit_tree', PaperTree: 'paper_tree',
  BerylRock: 'rock_beryl', DulliteRock: 'rock_dullite', SparklyRock: 'rock_sparkly',
  DirtPile: 'dirt_pile', IceNubbin: 'ice_knob', Jellisac: 'jellisac',
  MortarBarnacle: 'mortar_barnacle', PeatBog: 'peat_base',
  EggPlant: 'egg_plant', GasPlant: 'gas_plant', SpicePlant: 'spice_plant',
  Alph: 'shrine_alph', Cosma: 'shrine_cosma', Friendly: 'shrine_friendly',
  Grendaline: 'shrine_grendaline', Humbaba: 'shrine_humbaba', Lem: 'shrine_lem',
  Mab: 'shrine_mab', Pot: 'shrine_pot', Spriggan: 'shrine_spriggan',
  Tii: 'shrine_ti', Zille: 'shrine_zille',
  Garden: 'garden', ToolVendor: 'toolvendor',
  StreetSpiritFirebog: 'streetspiritfirebog', StreetSpiritZutto: 'streetspiritzutto',
  StreetSpiritGroddle: 'streetspiritgroddle',
  // Crab has its own real converted-art runtime-manifest row (from its prior
  // NPC conversion batch). HoochRespawningItem/PurpleFlowerRespawningItem/
  // Still are deliberately NOT mapped here: their world-entity sprite was
  // never converted (still dead-linked, see the REAL_TYPES comment above),
  // so they're excluded from NEWLY_PLACED_TYPES below and never hit this
  // lookup -- giving them a runtime-manifest id here would misrepresent
  // them as having real converted world-entity art.
  Crab: 'crab',
  // SnoConeVendingMachine has its own real converted-art runtime-manifest
  // row (id "snoconevendingmachine") -- both its world-entity sprite and
  // its item catalog's icons are real, see the VENDOR_NPC_TYPES comment
  // above, so (unlike Hooch/PurpleFlower/Still) it belongs in
  // NEWLY_PLACED_TYPES below too.
  SnoConeVendingMachine: 'snoconevendingmachine',
  // DustTrap/Mailbox/GardeningGoodsVendor/the 4 respawning items added
  // 2026-08-28 all have their own real converted-art runtime-manifest rows
  // (ids match content/runtime-manifest.json exactly -- "scarecrow" for
  // GardeningGoodsVendor since that's the misnamed source file's id, and
  // "gas_laughing"/"no_no_powder" for LaughingGas/NoNoPowder since those are
  // the real item ids, not the class-name-derived strings), so all 7 belong
  // in NEWLY_PLACED_TYPES below too.
  DustTrap: 'dust_trap', Mailbox: 'mailbox', GardeningGoodsVendor: 'scarecrow',
  CocktailShakerRespawningItem: 'cocktail_shaker',
  HotNFizzySauceRespawningItem: 'hot_n_fizzy_sauce',
  LaughingGasRespawningItem: 'gas_laughing',
  NoNoPowderRespawningItem: 'no_no_powder',
};
// Types with real, newly-converted official art (as opposed to quoins,
// which predate this pass) -- these get concrete example rows in the placement
// manifest; see generatePlacementManifest for why the full set isn't dumped there.
const NEWLY_PLACED_TYPES = ['WoodTree', 'Chicken', 'Piggy', 'MetalRock',
  'Fox', 'SilverFox', 'HeliKitty', 'Salmon', 'Butterfly', 'Batterfly',
  'BeanTree', 'BubbleTree', 'FruitTree', 'PaperTree',
  'BerylRock', 'DulliteRock', 'SparklyRock',
  'DirtPile', 'IceNubbin', 'Jellisac', 'MortarBarnacle', 'PeatBog',
  'EggPlant', 'GasPlant', 'SpicePlant',
  ...SHRINE_TYPES, ...VENDOR_NPC_TYPES, 'Crab', 'Mailbox',
  'CocktailShakerRespawningItem', 'HotNFizzySauceRespawningItem',
  'LaughingGasRespawningItem', 'NoNoPowderRespawningItem'];
// (SnoConeVendingMachine/GardeningGoodsVendor/DustTrap are included via the
// VENDOR_NPC_TYPES spread above; the 4 respawning items are listed
// explicitly here rather than via a RESPAWNING_ITEM_TYPES spread, matching
// how Hooch/PurpleFlowerRespawningItem were deliberately left OUT of this
// list -- unlike those two, all 4 new respawning items have real converted
// art, not a dead-linked sprite, so they belong here.)

function hash(value) {
  let result = 2166136261;
  for (const char of value) {
    result ^= char.charCodeAt(0);
    result = Math.imul(result, 16777619);
  }
  return result >>> 0;
}

// Which types float (elevated above ground is correct -- matches the
// original design of collectibles/flyers) vs. are ground-anchored (must sit
// ON the walkable ground line, feet planted, like a real tree/animal).
// Everything not listed here is ground-anchored. The client places a
// sprite's *bottom* edge at its `y` (coUclient npc.dart:
// `top = map['y'] - animation.height`), so for a ground-anchored entity,
// `y` = the ground line's canvas-local coordinate puts it exactly on the
// ground; the old code applied the quoin float offset to every type
// uniformly, which put trees, rocks, and land animals floating up to ~275px
// in mid-air -- confirmed live (a Bean Tree rendered hovering well above the
// walkable surface).
const FLOATING_TYPES = new Set(['Img', 'Mood', 'Energy', 'Currant', 'Mystery', 'Favor']);
const AERIAL_TYPES = new Set(['Butterfly', 'Batterfly', 'HeliKitty']);

// Approximate on-screen widths (px), used only to keep placed entities
// within a street's bounds and spaced apart from each other -- deliberately
// generous/approximate, not exact per-frame sprite dimensions (those live in
// each Dart entity class's Spritesheet() call, not this script, and aren't
// worth re-deriving here just for a layout margin). Types not listed fall
// back to DEFAULT_WIDTH, a reasonable guess for an NPC/person-sized entity.
const DEFAULT_WIDTH = 180;
const WIDTH_BY_TYPE = {
	// Quoins/collectibles: small icon-sized sprites.
	Img: 50, Mood: 50, Energy: 50, Currant: 50, Mystery: 50, Favor: 50,
	// Trees: among the widest ground entities (frame widths seen in
	// converted trees run up to ~220px).
	WoodTree: 220, BeanTree: 220, BubbleTree: 220, FruitTree: 220, PaperTree: 220,
	// Ground resources/rocks.
	MetalRock: 140, BerylRock: 140, DulliteRock: 140, SparklyRock: 140,
	DirtPile: 200, IceNubbin: 120, Jellisac: 120, MortarBarnacle: 120, PeatBog: 160,
	EggPlant: 180, GasPlant: 180, SpicePlant: 180,
	HoochRespawningItem: 140, PurpleFlowerRespawningItem: 100,
	// Added 2026-08-28: DustTrap/Mailbox/the 4 new respawning items' actual
	// converted frame widths (5th positional arg of their default state's
	// Spritesheet() call -- (name, url, sheetWidth, sheetHeight, frameWidth,
	// frameHeight, numFrames, loops)) differ meaningfully from DEFAULT_WIDTH
	// (180), so each gets an explicit entry here, scaled similarly to the
	// existing Hooch(47px frame->140)/PurpleFlower(68px frame->100) margin
	// convention above rather than using the raw frame width directly.
	// GardeningGoodsVendor's own default state ('idle_stand') frame width is
	// 187px -- close enough to DEFAULT_WIDTH (180) that it gets no entry,
	// same as the other already-placed Vendor types (Garden/ToolVendor/etc.)
	// above, none of which have one either.
	DustTrap: 150, // 'up' (default/idle) state frame width 123px
	Mailbox: 120, // 'idle' (default) state frame width 101px
	CocktailShakerRespawningItem: 150, // frame width 125px
	NoNoPowderRespawningItem: 130, // frame width 85px
	LaughingGasRespawningItem: 100, // frame width 52px
	HotNFizzySauceRespawningItem: 90, // frame width 41px
	// Animals: generally smaller than trees/NPCs.
	Chicken: 90, Piggy: 110, Fox: 110, SilverFox: 110, Salmon: 90, Crab: 90,
	Butterfly: 60, Batterfly: 60, HeliKitty: 90,
};

function entityWidth(type) {
	return WIDTH_BY_TYPE[type] ?? DEFAULT_WIDTH;
}

function entityY(dynamic, type, seed) {
	if (!dynamic) {
		return Math.round(600 + ((seed >>> 16) % 180));
	}
	const ground = Number(dynamic.ground_y);
	const height = Math.abs(Number(dynamic.t) - Number(dynamic.b));
	// Entity coordinates are local to the street canvas, whose origin is at
	// its top rather than the game's signed ground coordinate; this is the
	// canvas-local Y of the walkable ground line.
	const groundLineY = height + ground;
	if (FLOATING_TYPES.has(type)) {
		// Floating collectibles: hover well above the ground at a varied
		// height, matching the original quoin design.
		return Math.round(groundLineY - 55 - ((seed >>> 16) % 220));
	} else if (AERIAL_TYPES.has(type)) {
		// Flying creatures: a modest hover height, not quoin-height.
		return Math.round(groundLineY - 20 - ((seed >>> 16) % 80));
	} else {
		// Ground-anchored: feet on the ground line, with a few px of natural
		// variance so a street's row of entities doesn't look perfectly ruled.
		return Math.round(groundLineY - ((seed >>> 16) % 12));
	}
}

// Lays out every entity placed on ONE street together, instead of each
// entity picking its own x independently (the old `position()` behavior).
// That independence was the root of two confirmed live bugs: (1) a sprite
// rolled near the outer edge of the allowed [0.12, 0.88] fraction range
// could still render partly off-street, because the fraction accounted for
// none of the entity's own width; (2) two entities on the same street had
// no awareness of each other and could land on overlapping/adjacent x
// values with nothing to keep them apart.
//
// This packs entities left-to-right in a street-varied order (hashed per
// street, so quoins don't always end up leftmost) using each entity's own
// approximate width plus a gap, exactly like laying out fixed-width boxes in
// a row: cursor starts at the street's left bound (+ edge margin), and each
// entity is placed at-or-after the cursor, which then advances by that
// entity's width. A first attempt used equal-size slots (usable-width / N)
// instead, which still overlapped constantly -- a slot narrower than the
// entity placed in it (very common: e.g. a 220px tree in a 200px slot)
// spills into its neighbor's slot no matter how the jitter is clamped, since
// the entity's own footprint alone exceeds its allotted space. Sequential
// packing has no such failure mode: neighbor i+1 can only start once
// neighbor i's box (including its full width) has already ended.
//
// Whatever width remains after every entity's width and a preferred gap are
// reserved gets spread out as extra breathing room (with a little
// hash-based jitter inside each entity's own share of it, never crossing
// into a neighbor's) so a sparse street doesn't clump everything at the
// left edge. Only when the raw SUM of entity widths alone exceeds the
// street's usable span -- more/wider things than the street can physically
// fit even packed edge to edge -- can the tail end still run past the right
// bound; that is a genuine capacity limit given how many entities this
// street rolled, not a placement bug.
function layoutPositions(tsid, dynamic, entries) {
	const EDGE_MARGIN = 24; // px kept clear of the street's outer l/r bounds
	const MAX_GAP = 40;     // preferred (not minimum) gap between neighbors

	const l = dynamic ? Number(dynamic.l) : -900;
	const r = dynamic ? Number(dynamic.r) : 900;
	const usable = Math.max(0, (r - l) - 2 * EDGE_MARGIN);

	const ordered = entries
		.map((entry, i) => ({ ...entry, i, sortKey: hash(`${tsid}:slot:${entry.seedKey}`) }))
		.sort((a, b) => a.sortKey - b.sortKey);
	const widths = ordered.map(entry => entityWidth(entry.type));
	const totalWidth = widths.reduce((sum, w) => sum + w, 0);
	const n = ordered.length;

	// Gap shrinks from MAX_GAP toward 0 as the street gets more crowded, so
	// entities never overlap as long as their combined width alone fits.
	const gapCount = Math.max(0, n - 1);
	const gap = gapCount > 0 ? Math.max(0, Math.min(MAX_GAP, (usable - totalWidth) / gapCount)) : 0;
	const packedWidth = totalWidth + gap * gapCount;
	// Leftover space beyond the preferred gaps, spread evenly across n+1
	// slots (before each entity, plus one trailing) as extra breathing room.
	const leftover = Math.max(0, usable - packedWidth);
	const extraPerSlot = n > 0 ? leftover / (n + 1) : 0;

	const results = new Array(entries.length);
	let cursor = l + EDGE_MARGIN;
	ordered.forEach((entry, idx) => {
		const width = widths[idx];
		const seed = hash(`${tsid}:${entry.seedKey}`);
		// Jitter within this entity's own share of the leftover space only
		// (never the neighbor's), so the no-overlap guarantee above holds
		// regardless of how much jitter lands. Guards on the ROUNDED value,
		// not extraPerSlot itself: a small positive leftover (e.g. 0.12px/
		// entity on a fairly full street) rounds to 0, and `seed % 0` is
		// `NaN` in JS -- which then failed every later bounds check
		// (`NaN >= x` is always false) and silently routed a fitting
		// entity through the genuine-overflow fallback below, discarding
		// its correct sequential position for an effectively unrelated one
		// -- confirmed live, reproducibly, as the source of overlaps on
		// streets whose entities should have fit with room to spare.
		const jitterRange = Math.round(extraPerSlot);
		const jitter = jitterRange > 0 ? (seed % jitterRange) : 0;
		// Hard safety-net on top of the packing math above: when a street's
		// rolled entities have more combined width than the street itself
		// (bottom-decile street widths run as low as 1000px against a median
		// of ~19 entities/street at ~150-220px each -- the packed cursor can
		// run past r well before every entity has been placed), clamping
		// straight to the edge would stack every overflowing entity on the
		// exact same pixel (the internal cursor keeps advancing unclamped,
		// so once one same-width entity overflows, every later one computes
		// the identical clamped position). Wrapping the overflow back into
		// the safe range via modulo instead spreads them back out across it
		// -- still crowded/overlapping in this genuinely-over-capacity case
		// (unavoidable: more entities than the street can hold), but not
		// literally identical, and always inside [l, r] either way.
		const minX = l + EDGE_MARGIN;
		const maxX = Math.max(minX, r - EDGE_MARGIN - width);
		const rawX = cursor + jitter;
		const span = maxX - minX;
		// FLOAT_SLACK absorbs floating-point drift from the fractional
		// gap/extraPerSlot arithmetic above (e.g. a cursor landing at
		// maxX + 5e-13 purely from repeated float addition) -- without it,
		// that kind of negligible overshoot on a street that actually fits
		// wrongly triggered the genuine-overflow branch below. And that
		// branch keys off `seed` (each entity's own hash), not `rawX` --
		// keying off the coordinate itself risked landing exactly on another
		// entity's real, unrelated position by coincidence (confirmed live:
		// it did, reproducibly, for one specific street).
		const FLOAT_SLACK = 0.5;
		const x = (rawX >= minX - FLOAT_SLACK && rawX <= maxX + FLOAT_SLACK)
			? Math.min(Math.max(rawX, minX), maxX)
			: (span > 0 ? minX + (seed % (span + 1)) : minX);
		results[entry.i] = { x: Math.round(x), y: entityY(dynamic, entry.type, seed) };
		cursor += extraPerSlot + width + gap;
	});
	return results;
}

const rows = [];
for (const [streetName, data] of Object.entries(streets)) {
	if (!data?.tsid) continue;
	const gTsid = data.tsid.replace(/^L/, 'G');
	const file = path.join(locations, `${gTsid}.json`);
	let dynamic = null;
	if (fs.existsSync(file)) {
		try { dynamic = JSON.parse(fs.readFileSync(file, 'utf8')).dynamic; } catch {}
	}
	if (!dynamic || !Number.isFinite(Number(dynamic.l)) || !Number.isFinite(Number(dynamic.r)) ||
		!Number.isFinite(Number(dynamic.ground_y))) dynamic = null;

  // Build the full list of entities to place on THIS street (quoins + real
  // types) before assigning any positions, so layoutPositions() can lay them
  // all out together -- sharing one non-overlapping slot allocation instead
  // of each entity picking an x independently with no awareness of the
  // street's other entities (see layoutPositions()'s comment above).
  const entries = [];

  // Quoins: unchanged from the original design -- one of each type on every
  // street, always present, same fixed-index id scheme.
  for (let index = 0; index < QUOIN_TYPES.length; index++) {
    entries.push({ type: QUOIN_TYPES[index], seedKey: String(index), id: `demo-${data.tsid}-${index}` });
  }

  // Real entities: varied per street per the RARITY table above, then
  // themed by region (REGION_THEME) instead of unconditionally placing all
  // 15 types everywhere at a flat rate.
  const region = regionKey(data);
  // Garden's placement is nudged toward streets vendors.json already marks
  // "gardening" (sells the hoe/watering_can/seeds a garden needs) or
  // "produce" (sells 12 of Garden's 13 crops) -- a real, grounded per-street
  // signal that already exists in the codebase, not an invented heuristic.
  // Every other street keeps Garden's flat base rate unchanged.
  const vendorCategory = vendorTypeByStreetName[streetName];
  const gardenVendorBoost = vendorCategory === 'gardening' ? 1.6
    : vendorCategory === 'produce' ? 1.3 : 1;
  // GardeningGoodsVendor (added 2026-08-28) stocks hoe/watering_can/13 crop
  // seeds -- exactly the "gardening" vendorCategory's own definition, with
  // no produce overlap -- so it shares Garden's gardening-street boost only
  // (not the produce boost Garden also gets, since GardeningGoodsVendor
  // sells no produce). See the VENDOR_NPC_TYPES comment above.
  const gardeningGoodsVendorBoost = vendorCategory === 'gardening' ? 1.6 : 1;
  for (const type of REAL_TYPES) {
    const { chance, maxCount } = RARITY[type];
    const multiplier = (REGION_THEME[region]?.[type] ?? 1) *
      (type === 'Garden' ? gardenVendorBoost
        : type === 'GardeningGoodsVendor' ? gardeningGoodsVendorBoost : 1);
    const effectiveChance = Math.max(2, Math.min(95, Math.round(chance * multiplier)));
    if (hash(`${data.tsid}:${type}:include`) % 100 >= effectiveChance) continue;
    const count = 1 + ((maxCount > 1 && hash(`${data.tsid}:${type}:count`) % 100 < 30) ? 1 : 0);
    for (let n = 1; n <= count; n++) {
      const seedKey = `${type}-${n}`;
      entries.push({ type, seedKey, id: `demo-${data.tsid}-${seedKey}` });
    }
  }

  // Quoins (FLOATING_TYPES) hover 55-275px above the ground line -- far
  // enough above the ground/aerial layer that they essentially never
  // visually compete for space with a tree, rock, or animal below them.
  // Packing them into the SAME sequential layout as ground entities anyway
  // needlessly reserved horizontal room for them, which pushed a meaningful
  // number of streets into "more combined width than the street can hold"
  // (the one case where entities still end up overlapping) purely because
  // of quoins that were never going to be at the same height in the first
  // place. Two independent packing passes -- one for quoins, one for
  // everything else -- share the same street bounds but no longer compete
  // with each other for room.
  const floatingEntries = entries.filter(entry => FLOATING_TYPES.has(entry.type));
  const groundEntries = entries.filter(entry => !FLOATING_TYPES.has(entry.type));
  const floatingPositions = layoutPositions(data.tsid, dynamic, floatingEntries);
  const groundPositions = layoutPositions(data.tsid, dynamic, groundEntries);
  floatingEntries.forEach((entry, i) => {
    const { x, y } = floatingPositions[i];
    rows.push({ id: entry.id, type: entry.type, tsid: data.tsid, x, y });
  });
  groundEntries.forEach((entry, i) => {
    const { x, y } = groundPositions[i];
    rows.push({ id: entry.id, type: entry.type, tsid: data.tsid, x, y });
  });
}

process.stdout.write('BEGIN;\n');
// REAL_TYPES rows now use a variable-count id scheme (demo-<tsid>-<type>-<n>)
// instead of the old fixed-index one (demo-<tsid>-<index>), and which
// streets/instances get a given type can change between runs as the RARITY
// table is tuned. Clear every previously-generated row for these types
// first (id LIKE 'demo-%' scopes this to generator-owned rows only) so a
// rerun never leaves stale duplicates behind under the old id scheme.
// Quoins are untouched: their id scheme and one-of-each-always-present
// design haven't changed.
process.stdout.write(
  `DELETE FROM street_entities WHERE id LIKE 'demo-%' AND type IN (` +
  REAL_TYPES.map(t => `'${t}'`).join(', ') + `);\n`);
// `DemoWheat` was removed from REAL_TYPES entirely (2026-08-28, see
// RECOVERY_TODO.md -- it's a placeholder class with no real item/action
// behind it, same category as the already-retired DemoTree/DemoChicken), so
// the DELETE above no longer covers it. Explicitly clean up any rows a prior
// run already seeded under the old REAL_TYPES membership, so a rerun of this
// script actually removes it from the live world instead of leaving stale
// placeholder rows behind.
process.stdout.write(`DELETE FROM street_entities WHERE id LIKE 'demo-%' AND type = 'DemoWheat';\n`);
for (const row of rows) {
	process.stdout.write(
		`INSERT INTO street_entities (id, type, tsid, x, y, z, h_flip, rotation, metadata_json) VALUES ` +
		`('${row.id}', '${row.type}', '${row.tsid}', ${row.x}, ${row.y}, 0, FALSE, 0, '{}') ` +
		// `demo-` IDs are owned by this generator, so it is safe to correct their
		// placement *and type* on a later run without altering hand-authored
		// entities -- this is what lets the DemoTree/DemoChicken -> WoodTree/
		// Chicken upgrade (see the `types` comment above) apply to existing rows.
		`ON CONFLICT (id) DO UPDATE SET type = EXCLUDED.type, x = EXCLUDED.x, y = EXCLUDED.y;\n`);
}
process.stdout.write('COMMIT;\n');
console.error(`Generated ${rows.length} synthetic demo entities.\n`);

// --- Also (re)generate content/placement-manifest.json's `placements` and
// `coverageSummary`, so the checked-in manifest reflects what this run seeds.
// Per CONTENT_RECOVERY_PLAN.md this file tracks placement provenance/coverage;
// it is NOT a full row-for-row dump of all ~35k seeded rows (that's just a
// restatement of the deterministic SQL above, regenerable any time by rerunning
// this script) -- instead it carries the full aggregate coverage stats plus a
// small set of concrete example rows per newly-converted real-asset type, which
// is enough to demonstrate/validate the schema and provenance without bloating
// a checked-in file with fully redundant data.
const EXAMPLES_PER_TYPE = 3;
const placementsByEntityType = {};
for (const row of rows) placementsByEntityType[row.type] = (placementsByEntityType[row.type] ?? 0) + 1;

const examples = [];
for (const type of NEWLY_PLACED_TYPES) {
  const forType = rows.filter(r => r.type === type).slice(0, EXAMPLES_PER_TYPE);
  for (const row of forType) {
    examples.push({
      id: row.id,
      provenanceKind: 'synthetic',
      entityType: row.type,
      runtimeAssetId: RUNTIME_ASSET_ID[row.type],
      tsid: row.tsid,
      x: row.x,
      y: row.y,
      sourceExport: null,
    });
  }
}

const placementManifestPath = path.join(root, 'content', 'placement-manifest.json');
const placementManifest = JSON.parse(fs.readFileSync(placementManifestPath, 'utf8'));
placementManifest.generatedAt = placementManifest.generatedAt; // left as-is; stamp manually on meaningful changes
placementManifest.placements = examples;
placementManifest.coverageSummary = {
  note: `Full per-row placement data (${rows.length} rows across ${types.length} types) lives in the ` +
    `database, deterministically regenerable by rerunning tools/seed-demo-world.mjs -- it is not exhaustively ` +
    `duplicated here to avoid an unmaintainable multi-megabyte JSON file. 'placements' above holds ` +
    `${EXAMPLES_PER_TYPE} concrete example rows per newly-converted real-asset type (${NEWLY_PLACED_TYPES.join('/')}) ` +
    `for schema/provenance illustration; 'placementsByEntityType' below is the full aggregate.`,
  streetsCovered: new Set(rows.map(r => r.tsid)).size,
  totalStreets: Object.values(streets).filter(d => d?.tsid).length,
  placementsByEntityType,
};
fs.writeFileSync(placementManifestPath, JSON.stringify(placementManifest, null, 2) + '\n');
console.error(`Updated ${path.relative(root, placementManifestPath)} (${examples.length} example rows, ` +
  `coverage for ${Object.keys(placementsByEntityType).length} entity types).\n`);
