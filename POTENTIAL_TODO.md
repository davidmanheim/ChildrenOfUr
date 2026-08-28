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
