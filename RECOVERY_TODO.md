# Local revival work tracker

This is the active implementation tracker. `POTENTIAL_TODO.md` remains a
separate list of review recommendations; items here are user-facing recovery
work that has been requested, observed, or is required to make a completed
feature genuinely usable.

Legend: **done** = implemented and smoke-tested; **active** = currently being
implemented/verified; **blocked** = needs a source or decision; **planned** =
accepted next work, not yet started.

## Runtime stability

| Status | Work | Evidence / next verification |
| --- | --- | --- |
| done | Local auth and local session | `LocalPlayer` can launch and travel through streets. Keep hosted Firebase path separate from local mode. |
| done | Server crash containment and logging | Latest game server starts and survives reconnects; Docker logs are the diagnosis surface. |
| done | Initial Dart/browser compatibility fixes | Number formatting, stale API calls, gamepad binding, timer/platform calls, and several mapper failures fixed as encountered. Continue regression smoke testing. |
| active | Map visited-street display | Verified 2026-08-27: server persists L-form TSIDs (18 rows for LocalPlayer in `metabolics.location_history`), and the null-history normalization is compiled into the served client bundle. Remaining: in-browser check of Tonga Trips/Pitika Parse/Jolkan Jank map highlighting. |
| active | Quoin feedback and reward clarity | Per-type visual tints added in `coUclient/web/files/css/desktop/quoins.css` (keyed on the existing type class from `Quoin.init`); denied quoins are now re-shown instead of staying invisible, and the collect handler no longer crashes on late responses (`metabolics_service.dart:collectQuoin`). Remaining: in-browser check of tint colors and meter/text response. |
| active | Transparent quoin rendering | Verified 2026-08-27: server sends `files/sprites/generated/local-quoin.svg` (running container confirmed) and the client serves it as `image/svg+xml`. Remaining: in-browser visual confirmation. |
| done | Buff persistence and buff-error loop | `PlayerBuff._write` failed on every call (`Map<String, dynamic>` assigned to `Map<String, int>`), so buff timers never persisted and the log filled with an error every 10s; fixed with an explicit `.cast<String, int>()` plus a real cache removal in `PlayerBuff.remove`. Post-restart logs are clean. |
| done | Server status metrics and weather noise | `bytesUsed` now uses `ProcessInfo.currentRss` (the image lacks `bc`/`ps`, so the shell scripts always failed); CPU degrade is silent; weather polling is skipped entirely when `openWeatherMap` is empty instead of logging a guaranteed 401 per street. Verified via `/serverStatus` returning a real RSS value with zero post-restart ERROR lines. |
| done | Auth logout/verification correctness | `SESSIONS.remove([token])` (List-as-key no-op), URL-encoded email used in the verification dedupe SELECT, and the `email_verification` table-name typo are fixed in `authServer/lib/auth.dart`; raw mapper query results there and across coUserver (auctions, mailbox, notes, users, skills, buffs, instancing, migrations) now cast to typed lists. Smoke-tested: localSession -> logout round-trip returns ok. |

## World data and content

| Status | Work | Evidence / next verification |
| --- | --- | --- |
| done | Geometry/world map | CAT422 map data loads; travel across streets works. |
| done | Synthetic placement seed | `tools/seed-demo-world.mjs` has deterministic geometry-aware quoin rows for all 3,180 unique map TSIDs. These are explicitly synthetic (`demo-` IDs). |
| active | Environmental entities | The current seed contains collectible quoins only. Add original-art-backed trees, animals, crops, rocks, and gardens after the asset conversion proof—not generic placeholders. |
| done | Authentic historic placements — decision | Decided 2026-08-27: not pursuing recovery of the original `street_entities`/MapFiller export. Generated/synthetic `demo-` placement (see `CONTENT_RECOVERY_PLAN.md`) is the permanent design, not an interim measure. |
| active | Official visual-asset archive | Full `tinyspeck/glitch-items` archive fetched locally for inventory (~0.76 GB); source formats are FLA/SWF. SWF→PNG conversion pipeline proven (JPEXS FFDec; see `tools/README-swf-pipeline.md` — the FFDec download itself is a one-time external human/CI step, not vendored). Chicken, wood tree, piggy, and a metal rock converted with real art and wired into their `coUserver` entity classes (`content/source-manifest.json`, `content/runtime-manifest.json`); `tools/validate-content.mjs` checks sprite geometry and manifest coverage. Not yet placed in the world — extend `tools/seed-demo-world.mjs` with `demo-` rows for these 4 types next. |
| active | FLA/SWF -> sprite conversion pipeline | Built and proven end-to-end (`tools/README-swf-pipeline.md`, `tools/swf-extract-bitmaps.py`, `tools/swf-frame-labels.py`, `tools/build-sprite-sheet.py`). Both inventoried source SWFs are 100% vector art with no embedded bitmaps, so rendering requires the external JPEXS `ffdec` tool (not vendored; downloaded on demand, see README). Converted 4 assets end-to-end: `Chicken` (17 states), `WoodTree` (4 maturity variants), `Piggy` (7 states), `MetalRock` (1 state) -- all 4 entity classes now point at local `coUclient/web/files/sprites/generated/converted/*.png` instead of the dead `childrenofur.com` host. `content/source-manifest.json` / `content/runtime-manifest.json` / `content/placement-manifest.json` added with `tools/validate-content.mjs` enforcing geometry, file existence, item-prerequisite, and accessibility-destination coverage (currently passing). Still open: no `street_entities` rows place these 4 real entities yet (`placement-manifest.json` is an empty skeleton) -- that's still the "Environmental entities" row above; and only 4 of ~5400 archive files are converted so far. |
| done | Encyclopedia links | The surviving `www2.childrenofur.com/encyclopedia/` mirror replaces defunct primary-site links in the footer, map context menu, and entity chat links. |
| planned | Street layer art localization | Use official `glitch-locations` art/metadata to eliminate remaining retired remote dependencies. |

## Gameplay and progression

| Status | Work | Evidence / next verification |
| --- | --- | --- |
| done | Local starter quest route | Local-only Q1 seed uses an existing quest; Magic Rock null-choice path was fixed. |
| active | Quest routing and WebSocket reliability | Verify quest list and progress against travel/actions after map and entity updates. |
| active | Item-tree recovery plan | `CONTENT_RECOVERY_PLAN.md` defines source provenance, accessibility destinations, and the rule that every runtime asset/item has a route or documented deferral. |
| planned | Import/translate item, recipe, vendor, quest, and achievement graph | Use CC0 original GameServerJS as reference data; add typed manifest plus prerequisite/reachability validation. |
| planned | Balanced synthetic progression | Once entity assets are local, seed animals/harvestables and make their rewards feed recipes, vendors, and quest prerequisites. |

## Deployment readiness

| Status | Work | Evidence / next verification |
| --- | --- | --- |
| planned | Split local and hosted auth configuration | Local bypass must be unavailable in deployed mode; retain Firebase-supported path. |
| planned | WebSocket/HTTP authentication and authorization | Required before any non-local deployment. Bind identity server-side and allowlist actions. |
| planned | Deterministic container builds | Pin toolchains/dependencies, add health checks/restarts, and bind local-only ports to localhost. |
| active | Sound policy | Original world music is hard to recover from the released asset archive directly, but was preserved via YouTube playlist: https://www.youtube.com/playlist?list=PLN0GhXnhPcciUtcwFG5MfdT284einO0k1 . A `Glitch Soundtrack MP3.zip` has been dropped in the repo root (gitignored — not committed; too large and not yet licensing-reviewed). Next step: confirm per-track licensing/attribution, extract and convert into the client's music manifest, then bundle for deployment (or retain YouTube/SoundCloud as an optional fallback); browser gesture gating is expected either way. |
| done | Version control / fork setup | Repo pushed to https://github.com/davidmanheim/ChildrenOfUr . `coUserver`/`coUclient`/`authServer` are git-subtree merges of real forks (davidmanheim/{coUserver,coUclient,authServer}, tracking ChildrenOfUr org upstream `dev`), preserving original commit history; local-revival changes sit in commits on top. See `LOCAL_SETUP.md` "Version control" for remote layout. `vendor/` stays plain vendored snapshots (not forked). |

## Verification checklist for each change

1. Rebuild/restart only the affected container(s).
2. Confirm the relevant HTTP/WebSocket endpoint is healthy.
3. Exercise the change in an actual browser session.
4. Inspect the game-server logs for errors for at least one reconnect/street change.
5. Update this tracker with the observed result and remaining dependency.
