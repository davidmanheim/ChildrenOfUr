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
const locations = path.join(root, 'coUserver', 'CAT422', 'locations');
// The first six are collectable quoins. `WoodTree`/`Chicken`/`Piggy`/`MetalRock`
// are real official-art entities (see CONTENT_RECOVERY_PLAN.md's asset-recovery
// pass; provenance in content/source-manifest.json) placed with deterministic,
// geometry-aware -- not historically recovered -- positions. `DemoWheat`
// remains a hand-drawn placeholder (no real crop asset has been converted
// yet). `DemoTree`/`DemoChicken` placeholders are retired by this array: the
// real WoodTree/Chicken take their place at the same index, so a rerun
// upgrades existing demo- rows in place (see the ON CONFLICT clause below).
const types = ['Img', 'Mood', 'Energy', 'Currant', 'Mystery', 'Favor',
  'WoodTree', 'Chicken', 'DemoWheat', 'Piggy', 'MetalRock'];

// Maps each seeded `type` to its content/runtime-manifest.json asset id, for
// content/placement-manifest.json provenance rows (see generatePlacementManifest below).
const RUNTIME_ASSET_ID = {
  Img: 'quoin-collectibles', Mood: 'quoin-collectibles', Energy: 'quoin-collectibles',
  Currant: 'quoin-collectibles', Mystery: 'quoin-collectibles', Favor: 'quoin-collectibles',
  WoodTree: 'wood_tree', Chicken: 'chicken', DemoWheat: 'demo-wheat',
  Piggy: 'piggy', MetalRock: 'metalrock',
};
// Types with real, newly-converted official art (as opposed to quoins/DemoWheat,
// which predate this pass) -- these get concrete example rows in the placement
// manifest; see generatePlacementManifest for why the full set isn't dumped there.
const NEWLY_PLACED_TYPES = ['WoodTree', 'Chicken', 'Piggy', 'MetalRock'];

function hash(value) {
  let result = 2166136261;
  for (const char of value) {
    result ^= char.charCodeAt(0);
    result = Math.imul(result, 16777619);
  }
  return result >>> 0;
}

function position(tsid, dynamic, index) {
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
	return {
		x: Math.round(l + (r - l) * fraction),
		// Entity coordinates are local to the street canvas, whose origin is at
		// its top rather than the game's signed ground coordinate.
		y: Math.round(height + ground - 55 - ((seed >>> 16) % 220))
  };
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

  for (let index = 0; index < types.length; index++) {
    const { x, y } = position(data.tsid, dynamic, index);
    rows.push({ id: `demo-${data.tsid}-${index}`, type: types[index], tsid: data.tsid, x, y });
  }
}

process.stdout.write('BEGIN;\n');
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
    `${EXAMPLES_PER_TYPE} concrete example rows per newly-converted real-asset type (chicken/wood_tree/piggy/` +
    `metalrock) for schema/provenance illustration; 'placementsByEntityType' below is the full aggregate.`,
  streetsCovered: new Set(rows.map(r => r.tsid)).size,
  totalStreets: Object.values(streets).filter(d => d?.tsid).length,
  placementsByEntityType,
};
fs.writeFileSync(placementManifestPath, JSON.stringify(placementManifest, null, 2) + '\n');
console.error(`Updated ${path.relative(root, placementManifestPath)} (${examples.length} example rows, ` +
  `coverage for ${Object.keys(placementsByEntityType).length} entity types).\n`);
