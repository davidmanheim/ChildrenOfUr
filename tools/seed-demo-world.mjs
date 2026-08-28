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
    FruitTree: 0.3, PaperTree: 0.3, Butterfly: 0.3, Batterfly: 0.3, HeliKitty: 0.3, DemoWheat: 0.3 },
  ilmenskie: { MetalRock: 2.2, Salmon: 1.6, WoodTree: 0.3, BeanTree: 0.3, BubbleTree: 0.3,
    FruitTree: 0.3, PaperTree: 0.3, Butterfly: 0.3, Batterfly: 0.3, HeliKitty: 0.3, DemoWheat: 0.3 },
  // Elevated grassland: good grazing, fewer big trees.
  highlands: { Chicken: 1.5, Piggy: 1.5, Fox: 1.5, WoodTree: 0.7, BeanTree: 0.7,
    BubbleTree: 0.7, FruitTree: 0.7, PaperTree: 0.7 },
  // Pastoral/farmland zones.
  uralia2: { Chicken: 1.6, Piggy: 1.6, DemoWheat: 1.6, WoodTree: 1.3, BeanTree: 1.3, FruitTree: 1.3 },
  kajuu: { Chicken: 1.6, Piggy: 1.6, DemoWheat: 1.6, WoodTree: 1.3, BeanTree: 1.3, FruitTree: 1.3 },
  // Ix: strange/artificial zone -- sparse ordinary life, exotic rarity up.
  ix: { WoodTree: 0.3, Chicken: 0.3, Piggy: 0.3, DemoWheat: 0.3, MetalRock: 0.3, BeanTree: 0.3,
    BubbleTree: 0.3, FruitTree: 0.3, PaperTree: 0.3, Fox: 0.3, HeliKitty: 0.3, Salmon: 0.3,
    Butterfly: 0.3, Batterfly: 0.3, SilverFox: 2.5 },
  // Hell: harsh territory -- sparse life generally, volcanic rock up.
  hell: { WoodTree: 0.3, Chicken: 0.3, Piggy: 0.3, DemoWheat: 0.3, BeanTree: 0.3, BubbleTree: 0.3,
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
// Quoins (collectibles) are placed one-of-each-always, unchanged from the
// original design. `WoodTree`/`Chicken`/`Piggy`/`MetalRock`/`Fox`/`SilverFox`/
// `HeliKitty`/`Salmon`/`Butterfly`/`Batterfly`/`BeanTree`/`BubbleTree`/
// `FruitTree`/`PaperTree` are real official-art entities (see
// CONTENT_RECOVERY_PLAN.md's asset-recovery pass; provenance in
// content/source-manifest.json) placed with deterministic, geometry-aware --
// not historically recovered -- positions, and a VARIED per-street subset
// (see the RARITY table below) rather than every type on every street.
// `DemoWheat` remains a hand-drawn placeholder (no real crop asset has been
// converted yet) but is included in that same varied rotation. The
// now-unused `DemoTree`/`DemoChicken` placeholder classes are no longer
// seeded at all, superseded by the real WoodTree/Chicken.
const QUOIN_TYPES = ['Img', 'Mood', 'Energy', 'Currant', 'Mystery', 'Favor'];
const REAL_TYPES = ['WoodTree', 'Chicken', 'DemoWheat', 'Piggy', 'MetalRock',
  'Fox', 'SilverFox', 'HeliKitty', 'Salmon', 'Butterfly', 'Batterfly',
  'BeanTree', 'BubbleTree', 'FruitTree', 'PaperTree'];
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
  DemoWheat: { chance: 50, maxCount: 2 }, Piggy: { chance: 50, maxCount: 2 },
  MetalRock: { chance: 50, maxCount: 2 },
  BeanTree: { chance: 45, maxCount: 2 }, BubbleTree: { chance: 45, maxCount: 2 },
  FruitTree: { chance: 45, maxCount: 2 }, PaperTree: { chance: 45, maxCount: 2 },
  Fox: { chance: 30, maxCount: 1 }, HeliKitty: { chance: 30, maxCount: 1 },
  Salmon: { chance: 30, maxCount: 1 }, Butterfly: { chance: 30, maxCount: 1 },
  Batterfly: { chance: 30, maxCount: 1 },
  SilverFox: { chance: 10, maxCount: 1 },
};

// Maps each seeded `type` to its content/runtime-manifest.json asset id, for
// content/placement-manifest.json provenance rows (see generatePlacementManifest below).
const RUNTIME_ASSET_ID = {
  Img: 'quoin-collectibles', Mood: 'quoin-collectibles', Energy: 'quoin-collectibles',
  Currant: 'quoin-collectibles', Mystery: 'quoin-collectibles', Favor: 'quoin-collectibles',
  WoodTree: 'wood_tree', Chicken: 'chicken', DemoWheat: 'demo-wheat',
  Piggy: 'piggy', MetalRock: 'metalrock',
  Fox: 'fox', SilverFox: 'silverfox', HeliKitty: 'helikitty', Salmon: 'salmon',
  Butterfly: 'butterfly', Batterfly: 'batterfly',
  BeanTree: 'bean_tree', BubbleTree: 'bubble_tree', FruitTree: 'fruit_tree', PaperTree: 'paper_tree',
};
// Types with real, newly-converted official art (as opposed to quoins/DemoWheat,
// which predate this pass) -- these get concrete example rows in the placement
// manifest; see generatePlacementManifest for why the full set isn't dumped there.
const NEWLY_PLACED_TYPES = ['WoodTree', 'Chicken', 'Piggy', 'MetalRock',
  'Fox', 'SilverFox', 'HeliKitty', 'Salmon', 'Butterfly', 'Batterfly',
  'BeanTree', 'BubbleTree', 'FruitTree', 'PaperTree'];

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

function position(tsid, dynamic, index, type) {
	const seed = hash(`${tsid}:${index}`);
	if (!dynamic) {
		// Some historical map records have no accompanying CAT422 layout. Keep
		// their synthetic entities near the default street origin so the seed is
		// complete without pretending that their original placement is known.
		return {
			x: Math.round(-900 + (seed % 1801)),
			y: Math.round(600 + ((seed >>> 16) % 180))
		};
	}
	const fraction = 0.12 + ((seed % 7600) / 10000);
	const l = Number(dynamic.l);
	const r = Number(dynamic.r);
	const ground = Number(dynamic.ground_y);
	const height = Math.abs(Number(dynamic.t) - Number(dynamic.b));
	// Entity coordinates are local to the street canvas, whose origin is at
	// its top rather than the game's signed ground coordinate; this is the
	// canvas-local Y of the walkable ground line.
	const groundLineY = height + ground;
	let y;
	if (FLOATING_TYPES.has(type)) {
		// Floating collectibles: hover well above the ground at a varied
		// height, matching the original quoin design.
		y = groundLineY - 55 - ((seed >>> 16) % 220);
	} else if (AERIAL_TYPES.has(type)) {
		// Flying creatures: a modest hover height, not quoin-height.
		y = groundLineY - 20 - ((seed >>> 16) % 80);
	} else {
		// Ground-anchored: feet on the ground line, with a few px of natural
		// variance so a street's row of entities doesn't look perfectly ruled.
		y = groundLineY - ((seed >>> 16) % 12);
	}
	return { x: Math.round(l + (r - l) * fraction), y: Math.round(y) };
}

const rows = [];
for (const data of Object.values(streets)) {
	if (!data?.tsid) continue;
	const gTsid = data.tsid.replace(/^L/, 'G');
	const file = path.join(locations, `${gTsid}.json`);
	let dynamic = null;
	if (fs.existsSync(file)) {
		try { dynamic = JSON.parse(fs.readFileSync(file, 'utf8')).dynamic; } catch {}
	}
	if (!dynamic || !Number.isFinite(Number(dynamic.l)) || !Number.isFinite(Number(dynamic.r)) ||
		!Number.isFinite(Number(dynamic.ground_y))) dynamic = null;

  // Quoins: unchanged from the original design -- one of each type on every
  // street, always present, same fixed-index id scheme (index doubles as
  // both the row id suffix and the position() jitter seed).
  for (let index = 0; index < QUOIN_TYPES.length; index++) {
    const { x, y } = position(data.tsid, dynamic, index, QUOIN_TYPES[index]);
    rows.push({ id: `demo-${data.tsid}-${index}`, type: QUOIN_TYPES[index], tsid: data.tsid, x, y });
  }

  // Real entities: varied per street per the RARITY table above, then
  // themed by region (REGION_THEME) instead of unconditionally placing all
  // 15 types everywhere at a flat rate.
  const region = regionKey(data);
  for (const type of REAL_TYPES) {
    const { chance, maxCount } = RARITY[type];
    const multiplier = REGION_THEME[region]?.[type] ?? 1;
    const effectiveChance = Math.max(2, Math.min(95, Math.round(chance * multiplier)));
    if (hash(`${data.tsid}:${type}:include`) % 100 >= effectiveChance) continue;
    const count = 1 + ((maxCount > 1 && hash(`${data.tsid}:${type}:count`) % 100 < 30) ? 1 : 0);
    for (let n = 1; n <= count; n++) {
      const seedKey = `${type}-${n}`;
      const { x, y } = position(data.tsid, dynamic, seedKey, type);
      rows.push({ id: `demo-${data.tsid}-${seedKey}`, type, tsid: data.tsid, x, y });
    }
  }
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
