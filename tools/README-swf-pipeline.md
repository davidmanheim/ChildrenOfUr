# FLA/SWF -> browser-safe sprite conversion pipeline

Implements CONTENT_RECOVERY_PLAN.md implementation-order step 1. Proven
end-to-end on `inhabitants/chicken` and `harvestable_resources/wood_tree`;
see `content/source-manifest.json` for exactly what was produced.

## Why this is a multi-tool pipeline, not one script

Every source SWF inventoried so far (`npc_chicken.swf`, `wood_tree.swf`) is
**100% vector art** -- zero embedded bitmap tags. This was verified, not
assumed: `tools/swf-extract-bitmaps.py` walks the raw SWF tag stream and
extracts any `DefineBits*`/`DefineBitsLossless*` raster tags directly
(no rendering required); run against both source files it found 0 bitmaps
and 161 / 24 un-rendered vector shape tags respectively. That rules out a
simple "unzip the bitmaps out" shortcut and means genuine vector
rasterization is required.

There is no pure-Python or pure-Node library in this environment that
renders SWF vector shapes + nested MovieClip timelines correctly (the
`pyswf` PyPI package installs but targets Python 2-era APIs and needs
`pylzma`, which fails to build here without the MSVC C++ toolchain; the
`swf-extract` npm package extracts bitmaps only, same limitation as our
own fallback script, and its own dependency tree is broken -- `require`
fails on a missing `lodash` transitive dependency it doesn't declare).

**The one tool that actually renders SWF vector/timeline content
correctly is [JPEXS Free Flash Decompiler (ffdec)](https://github.com/jindrapetrik/jpexs-decompiler)**,
a Java application. It is NOT vendored into this repository (~20MB Java
archive) and must be fetched by whoever re-runs the pipeline:

```sh
curl -sL -o ffdec.zip \
  https://github.com/jindrapetrik/jpexs-decompiler/releases/download/version26.2.1/ffdec_26.2.1.zip
unzip ffdec.zip -d ffdec
# Requires a JRE/JDK on PATH (any Java 11+; this pass used Zulu 21).
java -jar ffdec/ffdec.jar -help
```

This is the one non-automatable gap: **a human or CI step must install a
JRE and download this exact (or a newer, re-verified) ffdec release**
before the pipeline below can run. Everything downstream of that is
scripted and reproducible.

## Pipeline steps

1. **(Optional/diagnostic) Try the cheap path first.**
   ```sh
   python tools/swf-extract-bitmaps.py <source.swf> <out_dir>
   ```
   If this reports non-zero `bitmaps`, you can skip ffdec entirely for
   that asset and go straight to packing. For every asset converted so
   far it reported zero, so step 2 was required.

2. **Rasterize every frame of every symbol.**
   ```sh
   java -jar ffdec/ffdec.jar -export sprite <frames_out_dir> <source.swf>
   ```
   This writes `<frames_out_dir>/DefineSprite_<charId>[_<name>]/<frameNum>.png`
   for every `DefineSprite` in the file, and `-export frame` does the same
   for the main timeline only. Use `-dumpSWF <source.swf>` (or
   `tools/swf-frame-labels.py symbols <source.swf>`) to find which
   character id is the actual top-level character (look for a
   `SymbolClass` entry whose name matches the file, e.g.
   `npc_chicken_fla.Chicken_1`).

   **`-export frame` bakes in an opaque background -- chroma-key it out.**
   Found 2026-08-28 (live bug triage, see RECOVERY_TODO.md): `-export
   frame` (used whenever a source SWF's art sits directly on the main
   timeline rather than inside a named `DefineSprite`, e.g. most item
   icons and a few world entities like `metalrock`) always rasterizes
   against the SWF's `SetBackgroundColor` stage tag as an *opaque* fill,
   not a transparent canvas -- this is inherent ffdec CLI behavior (its
   `lastExportTransparentBackground` config option has no effect on this
   export mode; verified by diffing output before/after setting it) and
   affected 129 of the ~161 sources converted so far before being fixed.
   `-export sprite` output does not have this problem (a `DefineSprite`
   character has no stage background of its own), so this step only
   applies when you used `-export frame`. After exporting, before packing:
   1. Read the exact background color straight from the SWF's
      `SetBackgroundColor` tag (tag type 9), a few bytes after the header
      -- do not guess it from a corner pixel. The tag-parsing helpers in
      `tools/swf-frame-labels.py` (`decompress_body`/`read_rect_end`/
      `iter_tags`) make this a few lines of code.
   2. Soft chroma-key that exact color out of every exported frame PNG:
      pixels within a small color-distance are made fully transparent,
      pixels beyond a larger distance are left untouched, and pixels in
      between get both a proportional alpha *and* their RGB pulled back
      out along the bg->pixel blend line (undoing the "rendered =
      coverage*fg + (1-coverage)*bg" compositing ffdec performed). Skipping
      the color pull-back (alpha-only keying) leaves a visible
      background-color fringe on antialiased edges, especially noticeable
      against saturated background colors -- confirmed on a
      purple-background asset during the 2026-08-28 fix.
   3. Only then proceed to step 4 (pack into a sprite sheet) using the
      keyed frames, not the raw ffdec output.
   This is not yet automated into `build-sprite-sheet.py` itself -- treat
   it as a required manual step for any new `-export frame` conversion
   until it is (see POTENTIAL_TODO.md's "Asset conversion pipeline").

3. **Resolve real animation-frame numbers for each named state.**
   ```sh
   python tools/swf-frame-labels.py labels <source.swf> <char_id>
   ```
   Prints `<real_frame_number> <label>` pairs by counting `ShowFrame` tags
   directly (NOT by trusting ffdec's `-dumpSWF` per-line counters, which
   are nested-tag-list positions, not frame numbers -- see the docstring
   in that script for why this distinction matters). The gap between one
   label's frame and the next label's frame is that state's frame range.

4. **Pack each state's frame range into one sprite sheet.**
   ```sh
   python tools/build-sprite-sheet.py <frames_out_dir>/DefineSprite_<charId>_<name> <start> <end> <out.png>
   ```
   Produces a single horizontal PNG strip (`frameWidth x numFrames` wide,
   `frameHeight` tall) matching the grid layout
   `coUserver/lib/entities/spritesheet.dart`'s `Spritesheet` class expects,
   and prints the exact `frameWidth`/`frameHeight`/`numFrames`/
   `sheetWidth`/`sheetHeight` JSON to wire into the entity's Dart source
   and into `content/source-manifest.json`. Fails loudly (missing-frame or
   inconsistent-geometry) rather than silently producing a bad sheet.

5. **Wire the output into the entity and manifests.**
   - Copy the sheet into `coUclient/web/files/sprites/generated/converted/`
     (this is the directory the client's static file server already
     serves; see the pre-existing `demo-*.svg` sprites there for the
     convention this follows).
   - Point the entity's `Spritesheet(...)` states at the local
     `files/sprites/generated/converted/...` path instead of a remote URL.
   - Add/update rows in `content/source-manifest.json` (provenance) and
     `content/runtime-manifest.json` (route + accessibility destination).
   - Run `node tools/validate-content.mjs` and fix anything it rejects.

## Requirements to install (for a human or CI runner)

- A JRE/JDK (11+) on `PATH`, to run `ffdec.jar`.
- The pinned `ffdec_26.2.1.zip` release above (or a newer release,
  re-verified against these same two proof assets before trusting it for
  new ones).
- Python 3 with Pillow (`pip install Pillow`) for
  `tools/build-sprite-sheet.py` and `tools/swf-extract-bitmaps.py`.
- Node.js for `tools/validate-content.mjs` (stdlib only, no npm install
  needed).

No network access is required at conversion time beyond the one-time
ffdec download; all SWF parsing happens locally.
