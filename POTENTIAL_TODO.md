# Potential follow-up work

This is a review-derived, **potential** work list.  It is not a commitment to
change every item, nor evidence that each path is currently user-visible.
Prioritize and verify items before implementation.

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
  `orange`/`purple`/`red`) are real `SnoConeVendingMachine` vendor stock
  but that vendor class is not in `tools/seed-demo-world.mjs`'s
  `VENDOR_NPC_TYPES` -- a good, low-risk candidate for a future placement
  pass (same shape as the already-fixed `Still`/`HoochRespawningItem`/
  `PurpleFlowerRespawningItem` gap).

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
