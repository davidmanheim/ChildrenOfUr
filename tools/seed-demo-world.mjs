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
 * not include player, account, inventory, or production-derived data.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const streets = JSON.parse(fs.readFileSync(
  path.join(root, 'coUserver', 'lib', 'common', 'mapdata', 'json', 'streetdata.json'), 'utf8'));
const locations = path.join(root, 'coUserver', 'CAT422', 'locations');
// The first six are collectable quoins. The last three are deliberately named
// `Demo*` classes backed by local SVGs: visual reconstruction only, not a
// claim that the original street had a specific tree, chicken, or wheat patch.
const types = ['Img', 'Mood', 'Energy', 'Currant', 'Mystery', 'Favor',
  'DemoTree', 'DemoChicken', 'DemoWheat'];

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
		// placement on a later run without altering hand-authored entities.
		`ON CONFLICT (id) DO UPDATE SET x = EXCLUDED.x, y = EXCLUDED.y;\n`);
}
process.stdout.write('COMMIT;\n');
console.error(`Generated ${rows.length} synthetic demo entities.\n`);
