#!/usr/bin/env python3
"""
Pack a contiguous run of already-rendered per-frame PNGs (as produced by
`ffdec -export sprite/frame <dir> <file.swf>`) into a single horizontal
sprite-sheet PNG, in the frame-grid layout the coUserver `Spritesheet`
class and the coUclient renderer expect (a single row of `numFrames`
frames, each `frameWidth`x`frameHeight`).

Part of the reproducible FLA/SWF -> browser-safe sprite conversion
pipeline described in CONTENT_RECOVERY_PLAN.md (Implementation order
step 1). This is the final step after:
  1. `ffdec -export sprite <dir> <file.swf>` (external tool, see
     tools/README-swf-pipeline.md) rasterizes the vector art frame-by-frame.
  2. `tools/swf-frame-labels.py labels <file.swf> <char_id>` resolves real
     (1-based) animation frame numbers for each named state, so the frame
     range passed here is derived from the source SWF, not guessed.

Usage:
    python tools/build-sprite-sheet.py <frames_dir> <start_frame> <end_frame> <out_png>

Fails loudly (non-zero exit) if any frame in the range is missing or if
frame dimensions are inconsistent within the run -- both are exactly the
"invalid sprite geometry" conditions the coverage validator
(tools/validate-content.mjs) also rejects at the manifest level, so a bad
sheet cannot silently reach the manifest in the first place.
"""
import json
import sys
from pathlib import Path

from PIL import Image


def build(frames_dir, start, end, out_png):
    frames_dir = Path(frames_dir)
    frames = []
    for n in range(start, end + 1):
        p = frames_dir / f"{n}.png"
        if not p.exists():
            raise FileNotFoundError(f"missing frame {n} ({p})")
        frames.append(Image.open(p))

    sizes = {im.size for im in frames}
    if len(sizes) != 1:
        raise ValueError(f"inconsistent frame geometry across {start}-{end}: {sizes}")
    frame_w, frame_h = sizes.pop()
    num_frames = len(frames)

    sheet = Image.new("RGBA", (frame_w * num_frames, frame_h), (0, 0, 0, 0))
    for i, im in enumerate(frames):
        sheet.paste(im, (i * frame_w, 0))

    out_png = Path(out_png)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_png)

    return {
        "file": str(out_png),
        "frameWidth": frame_w,
        "frameHeight": frame_h,
        "numFrames": num_frames,
        "sheetWidth": frame_w * num_frames,
        "sheetHeight": frame_h,
        "sourceFrameRange": [start, end],
    }


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(1)
    meta = build(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4])
    print(json.dumps(meta, indent=2))
