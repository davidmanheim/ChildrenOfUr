# Content recovery and accessibility contract

Status: **design and inventory phase**. This document describes the rule for
bringing the released Glitch/Ur content into the local revival. It does **not**
claim that the missing original Children of Ur placement database has been
recovered.

## Authoritative inputs and provenance

| Source | Covers | License / use |
| --- | --- | --- |
| `tinyspeck/glitch-items` | Inhabitants, harvestables, item art, seeds, furniture, quest items, etc. | CC0; retain the source path and commit in the manifest. |
| `tinyspeck/glitch-locations` | Street art and construction data | CC0; inputs to CAT422 street rendering. |
| `tinyspeck/glitch-GameServerJS` | Original item, crafting, quest, and achievement logic | CC0 reference data; it must be translated and tested, never executed as trusted server code. |
| `www2.childrenofur.com/encyclopedia/` | Surviving Children of Ur reference pages for entities and locations | Reference-only live mirror; client links use this host instead of the defunct primary site. |
| recovered `street_entities` data, if obtained | Historical placements | Separate provenance and permission review; never mix it silently with synthetic rows. |

The official item bundle has been fetched locally for inventory. Its source
format is mostly FLA/SWF, so it is not browser-ready. Each selected asset must
be deterministically converted to a browser-safe SVG or PNG sprite sheet and
recorded in a checked-in manifest before the game points at it.

## The accessibility rule

Every *runtime-ready* item or visual asset has exactly one of these declared
destinations:

1. **Street presentation** — background/layer art required to render one or
   more CAT422 streets. It is accessible by visiting those streets.
2. **World entity** — a plant, animal, rock, NPC, door, or collectible with
   seeded or recovered placements. It is accessible by visiting an explicitly
   listed street set.
3. **Player item** — obtainable through one or more of a vendor, world-entity
   harvest, recipe, quest reward, achievement reward, or starter grant.
4. **UI/feedback visual** — reachable from a named UI state such as inventory,
   skill tree, quest log, achievement, or status effect.
5. **Deliberately deferred** — retained in the archive but not exposed. A
   concrete reason and a replacement milestone are mandatory. "Unknown" is
   not an acceptable shipped state.

An asset is never placed merely because it exists. A runtime manifest entry
must identify its source, conversion output, entity/item identity, destination,
and why that destination makes game sense. The importer must fail coverage
validation if any converted asset lacks one of the five destinations.

## Initial routing model

| Family | In-game role | Accessible through | Why |
| --- | --- | --- | --- |
| Street layers and scenery | Street presentation | Map travel | Reconstructs the visual identity of every street without inventing object placement. |
| Trees, rocks, peat, gardens, and other harvestables | World entities | Geometry-aware placements, then harvesting skills | Forms the resource loop for arborology, mining, and related skills. |
| Chickens, pigs, butterflies, foxes, etc. | World entities | Geometry-aware habitats and animal-kinship actions | Restores living streets and provides animal-derived resources. |
| Grain, crop seeds, herbs, and produce | Player items | Gardening, animal harvests, vendors, recipes, and quests | Feeds cooking, animal, and quest loops rather than becoming unexplained scenery. |
| Food, drinks, tools, furniture, and crafted goods | Player items | Recipes, vendors, quest rewards, achievements, and starter grants | Provides the economic/crafting tree. |
| Quest-only, achievement, and event art | UI/feedback or player items | The corresponding quest/achievement/event | Keeps rare assets discoverable without random world clutter. |

## First concrete assets

These source families are confirmed in the official item archive and are the
first candidates for conversion and integration:

- `inhabitants/chicken/npc_chicken.{swf,fla}` — animal entity; mapped to the
  existing `Chicken` behaviour and animal-kinship loop.
- `harvestable_resources/{bean_tree,bubble_tree,fruit_tree,wood_tree,...}` —
  existing tree classes and their harvesting skills.
- `seeds/seed_grain` and crop seed families — garden/crop progression, not
  generic static wheat decoration.
- `harvestable_resources/{rock_*,dirt_pile,peat_*,garden,...}` — existing
  resource entity classes and their tools/skills.

## Placement and reconstruction policy

Decision (2026-08-27): historic placement recovery is **not being pursued**.
The original crowdsourced `street_entities` export is not being sought out from
former maintainers. Generated, geometry-aware synthetic placement is the
accepted permanent design, not a stopgap. Synthetic rows use `demo-` IDs and
deterministic, geometry-aware positions, and are never labelled as original
placements. The seed should provide enough plants, animals, collectibles, and
resource nodes to exercise each obtainable loop, but it must not claim
historical accuracy.

If authentic placement data is ever independently offered, it may still be
imported via a staging table with validated type/coordinates/TSIDs and
retained provenance, replacing only the matching synthetic `demo-` rows
transactionally — but this is no longer an open action item.

## Required manifests and validation

Before importing the full set, add and maintain these checked-in artifacts:

- `content/source-manifest.json`: every selected original source path, source
  repository commit, license, and conversion result.
- `content/runtime-manifest.json`: one runtime asset/item per row with category,
  destination, route IDs, and status.
- `content/placement-manifest.json`: generated/recovered placement provenance,
  street coverage, and entity types.
- a validation command that rejects missing assets, invalid sprite geometry,
  dangling item prerequisites, and any runtime manifest entry without an
  accessibility destination.

The validation report should summarize: assets by source family; sprites ready
for the browser; entity and item routes by kind; reachable starter-to-endgame
item graph; placements by street; and explicitly deferred assets with reasons.

## Implementation order

1. Build a reproducible FLA/SWF-to-SVG-or-PNG conversion pipeline and prove it
   with the chicken and one tree; do not rely on retired remote image URLs.
2. Add the source/runtime manifests and coverage validator.
3. Convert and localize the existing server entity sprites, beginning with
   animals and harvestables already supported by `coUserver`.
4. Seed balanced, clearly synthetic habitats across all streets and verify
   their actions, rewards, respawns, and related item routes.
5. Translate the original item/recipe/quest data into typed local data,
   including prerequisite validation and starter paths.
6. Import verified historical placements if they are recovered; remove only the
   superseded synthetic rows.
