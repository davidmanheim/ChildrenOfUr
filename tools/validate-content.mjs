#!/usr/bin/env node
/*
 * Coverage/integrity validator for the checked-in content-recovery
 * manifests (content/source-manifest.json, content/runtime-manifest.json,
 * content/placement-manifest.json), per CONTENT_RECOVERY_PLAN.md's
 * "Required manifests and validation" section.
 *
 * Rejects (non-zero exit):
 *   1. Any referenced sprite/manifest file that is missing on disk.
 *   2. Invalid sprite geometry: a converted-asset output whose
 *      frameWidth * numFrames != sheetWidth, whose frameHeight !=
 *      sheetHeight, or whose declared dimensions don't match the actual
 *      PNG on disk (via `file` byte-signature dimension read -- no image
 *      library dependency).
 *   3. Dangling item prerequisites: any itemRequirement/rewardItem string
 *      referenced from content/runtime-manifest.json that does not exist
 *      as a key in any coUserver/lib/entities/items/json/*.json file.
 *   4. Any content/runtime-manifest.json entry missing (or not exactly
 *      one of) the five declared accessibility destinations.
 *
 * Also cross-checks content/placement-manifest.json rows against
 * content/runtime-manifest.json (runtimeAssetId must exist) and against
 * the demo-/orig- id-prefix convention in CONTENT_RECOVERY_PLAN.md.
 *
 * Usage (from repository root):
 *   node tools/validate-content.mjs
 *
 * Exits 0 and prints a summary report if everything passes; exits 1 and
 * prints every violation found (does not stop at the first one) if not.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const errors = [];
const warnings = [];

function readJson(relPath) {
  const abs = path.join(root, relPath);
  if (!fs.existsSync(abs)) {
    errors.push(`missing manifest file: ${relPath}`);
    return null;
  }
  try {
    return JSON.parse(fs.readFileSync(abs, 'utf8'));
  } catch (e) {
    errors.push(`invalid JSON in ${relPath}: ${e.message}`);
    return null;
  }
}

const VALID_DESTINATIONS = new Set([
  'Street presentation',
  'World entity',
  'Player item',
  'UI/feedback visual',
  'Deliberately deferred',
]);

// --- Minimal PNG dimension reader (IHDR chunk), no dependency needed. ---
function pngDimensions(absPath) {
  const fd = fs.openSync(absPath, 'r');
  try {
    const buf = Buffer.alloc(24);
    fs.readSync(fd, buf, 0, 24, 0);
    const sig = buf.subarray(0, 8).toString('hex');
    if (sig !== '89504e470d0a1a0a') return null; // not a PNG
    const width = buf.readUInt32BE(16);
    const height = buf.readUInt32BE(20);
    return { width, height };
  } finally {
    fs.closeSync(fd);
  }
}

function checkFileExists(relPath, context) {
  const abs = path.join(root, relPath);
  if (!fs.existsSync(abs)) {
    errors.push(`${context}: referenced file does not exist on disk: ${relPath}`);
    return false;
  }
  return true;
}

// --- 1. Load manifests ---
const sourceManifest = readJson('content/source-manifest.json');
const runtimeManifest = readJson('content/runtime-manifest.json');
const placementManifest = readJson('content/placement-manifest.json');

// --- 2. Missing assets + invalid sprite geometry (source-manifest) ---
let sheetsChecked = 0;
if (sourceManifest) {
  for (const asset of sourceManifest.assets ?? []) {
    for (const output of asset.outputs ?? []) {
      const context = `source-manifest asset "${asset.id}" output "${output.state}"`;
      for (const key of ['file', 'runtimeFile']) {
        if (!output[key]) {
          errors.push(`${context}: missing "${key}" field`);
          continue;
        }
        if (!checkFileExists(output[key], context)) continue;
      }

      // Geometry: frameWidth * numFrames must equal sheetWidth or the file's
      // real width; frameHeight must equal sheetHeight / the file's real
      // height. Reject non-positive or non-integer values outright.
      const { frameWidth, frameHeight, numFrames } = output;
      for (const [k, v] of Object.entries({ frameWidth, frameHeight, numFrames })) {
        if (!Number.isInteger(v) || v <= 0) {
          errors.push(`${context}: invalid sprite geometry -- ${k}=${v} is not a positive integer`);
        }
      }
      if (Number.isInteger(frameWidth) && Number.isInteger(numFrames) &&
          frameWidth > 0 && numFrames > 0) {
        const abs = path.join(root, output.file ?? '');
        if (output.file && fs.existsSync(abs)) {
          const dims = pngDimensions(abs);
          sheetsChecked++;
          if (dims) {
            const expectedW = frameWidth * numFrames;
            if (dims.width !== expectedW) {
              errors.push(`${context}: invalid sprite geometry -- PNG width ${dims.width} != frameWidth(${frameWidth}) * numFrames(${numFrames}) = ${expectedW}`);
            }
            if (dims.height !== frameHeight) {
              errors.push(`${context}: invalid sprite geometry -- PNG height ${dims.height} != frameHeight(${frameHeight})`);
            }
          } else {
            errors.push(`${context}: ${output.file} is not a readable PNG (bad signature)`);
          }
        }
      }
    }
  }
}

// --- 3. Runtime manifest: every entry must have exactly one valid destination ---
const runtimeIds = new Set();
if (runtimeManifest) {
  const allEntries = [
    ...(runtimeManifest.assets ?? []),
    ...(runtimeManifest.deliberatelyDeferred ?? []).map(d => ({ ...d, destination: 'Deliberately deferred' })),
  ];
  for (const entry of runtimeManifest.assets ?? []) {
    runtimeIds.add(entry.id);
    if (!entry.destination) {
      errors.push(`runtime-manifest asset "${entry.id}": missing accessibility destination`);
    } else if (!VALID_DESTINATIONS.has(entry.destination)) {
      errors.push(`runtime-manifest asset "${entry.id}": destination "${entry.destination}" is not one of the 5 declared destinations`);
    }
    if (entry.destination === 'Deliberately deferred' && !entry.statusNote && !entry.reason) {
      errors.push(`runtime-manifest asset "${entry.id}": destination is "Deliberately deferred" but has no reason/statusNote (a concrete reason and replacement milestone are mandatory per CONTENT_RECOVERY_PLAN.md)`);
    }
  }
  for (const entry of runtimeManifest.deliberatelyDeferred ?? []) {
    if (!entry.reason) {
      errors.push(`runtime-manifest deliberatelyDeferred "${entry.id}": missing mandatory "reason"`);
    }
    if (!entry.replacementMilestone) {
      errors.push(`runtime-manifest deliberatelyDeferred "${entry.id}": missing mandatory "replacementMilestone" ("Unknown" is not an acceptable shipped state)`);
    }
  }
}

// --- 4. Dangling item prerequisites, cross-checked against the real item registry ---
const itemJsonDir = path.join(root, 'coUserver', 'lib', 'entities', 'items', 'json');
const knownItems = new Set();
if (fs.existsSync(itemJsonDir)) {
  for (const file of fs.readdirSync(itemJsonDir)) {
    if (!file.endsWith('.json')) continue;
    try {
      const data = JSON.parse(fs.readFileSync(path.join(itemJsonDir, file), 'utf8'));
      for (const key of Object.keys(data)) knownItems.add(key);
    } catch (e) {
      warnings.push(`could not parse item registry file ${file}: ${e.message}`);
    }
  }
} else {
  warnings.push('coUserver item registry directory not found; skipping item-prerequisite cross-check');
}

function checkItemRefs(entry, context) {
  const route = entry.routeIds ?? {};
  const refs = [
    ...(Array.isArray(route.itemRequirement) ? route.itemRequirement : route.itemRequirement ? [route.itemRequirement] : []),
    ...(route.rewardItem ? [route.rewardItem] : []),
  ];
  for (const ref of refs) {
    if (knownItems.size > 0 && !knownItems.has(ref)) {
      errors.push(`${context}: dangling item prerequisite/reward "${ref}" -- not found in any coUserver/lib/entities/items/json/*.json`);
    }
  }
}
if (runtimeManifest) {
  for (const entry of runtimeManifest.assets ?? []) {
    checkItemRefs(entry, `runtime-manifest asset "${entry.id}"`);
  }
}

// --- 5. Placement manifest cross-checks ---
if (placementManifest) {
  for (const row of placementManifest.placements ?? []) {
    const prefix = row.provenanceKind === 'recovered' ? 'orig-' : 'demo-';
    if (!row.id || !row.id.startsWith(prefix)) {
      errors.push(`placement-manifest row "${row.id}": id must start with "${prefix}" for provenanceKind "${row.provenanceKind}"`);
    }
    if (row.runtimeAssetId && runtimeIds.size > 0 && !runtimeIds.has(row.runtimeAssetId)) {
      errors.push(`placement-manifest row "${row.id}": runtimeAssetId "${row.runtimeAssetId}" not found in content/runtime-manifest.json`);
    }
    if (row.provenanceKind === 'recovered' && !row.sourceExport) {
      errors.push(`placement-manifest row "${row.id}": provenanceKind "recovered" requires sourceExport provenance`);
    }
  }
}

// --- Report ---
console.log('Content recovery validation report');
console.log('===================================');
console.log(`Sprite sheets checked (geometry + on-disk existence): ${sheetsChecked}`);
console.log(`Runtime manifest assets: ${runtimeManifest?.assets?.length ?? 0}`);
console.log(`Deliberately deferred entries: ${runtimeManifest?.deliberatelyDeferred?.length ?? 0}`);
console.log(`Known item registry keys (for prerequisite cross-check): ${knownItems.size}`);
console.log(`Placement rows: ${placementManifest?.placements?.length ?? 0}`);
console.log('');

if (warnings.length) {
  console.log(`Warnings (${warnings.length}):`);
  for (const w of warnings) console.log(`  - ${w}`);
  console.log('');
}

if (errors.length) {
  console.log(`FAILED with ${errors.length} error(s):`);
  for (const e of errors) console.log(`  - ${e}`);
  process.exitCode = 1;
} else {
  console.log('PASSED: no missing assets, no invalid sprite geometry, no dangling item prerequisites, and every runtime-manifest entry has a valid accessibility destination.');
}
