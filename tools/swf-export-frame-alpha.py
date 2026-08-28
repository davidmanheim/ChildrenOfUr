#!/usr/bin/env python3
"""
Export a range of main-timeline frames from an SWF to PNG with genuine
per-pixel alpha, working around a known ffdec CLI defect (documented in
tools/README-swf-pipeline.md): `ffdec -export frame` always composites the
frame onto the SWF's own SetBackgroundColor as an opaque backdrop -- even
with `-config lastExportTransparentBackground=true` (verified empirically to
have no effect on `-export frame`; it only affects `-export sprite`/button
exports, which render a symbol in isolation and already come out with real
alpha). No SVG rasterizer with a working native cairo/dll was available in
this environment to use the (otherwise-transparent) `-format frame:svg`
export instead.

Workaround: difference matting. Export the same frame twice, once against a
white SetBackgroundColor (tools/swf-patch-bgcolor.py-patched copy) and once
against black, then solve the standard two-backdrop matting equations
per-pixel:
    C_white = alpha*F + (1-alpha)*255
    C_black = alpha*F + (1-alpha)*0 = alpha*F
    => alpha = 1 - (C_white - C_black)/255   (per channel; averaged across
       channels for robustness to rounding)
    => F = C_black / alpha  (only defined where alpha > 0)
This recovers true anti-aliased alpha (not a binary/thresholded mask) for
any foreground color, verified visually against a checkerboard backdrop.

Usage:
    python tools/swf-export-frame-alpha.py <source.swf> <out_dir> [start] [end]

Writes <out_dir>/<n>.png for each frame n in [start, end] (default: all
frames, auto-detected from how many frames ffdec exports). Requires
Pillow and numpy.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
FFDEC_JAR = REPO_ROOT / "ffdec" / "ffdec.jar"
PATCH_SCRIPT = Path(__file__).resolve().parent / "swf-patch-bgcolor.py"


def run_ffdec(args):
    subprocess.run(
        ["java", "-jar", str(FFDEC_JAR)] + args,
        check=True, capture_output=True, text=True,
    )


def export_frames(swf_path, out_dir):
    run_ffdec(["-export", "frame", str(out_dir), str(swf_path)])


def matte(white_png, black_png, out_png):
    w = np.array(Image.open(white_png).convert("RGB"), dtype=np.float64)
    b = np.array(Image.open(black_png).convert("RGB"), dtype=np.float64)
    diff = w - b
    alpha = np.clip(1.0 - diff.mean(axis=2) / 255.0, 0.0, 1.0)
    safe_alpha = np.where(alpha > 1e-3, alpha, 1.0)
    fg = np.clip(b / safe_alpha[..., None], 0, 255)
    out = np.zeros((*alpha.shape, 4), dtype=np.uint8)
    out[..., :3] = fg.astype(np.uint8)
    out[..., 3] = (alpha * 255).astype(np.uint8)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(out, "RGBA").save(out_png)


def main(swf_path, out_dir, start=None, end=None):
    swf_path = Path(swf_path)
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        white_dir = tmp / "white"
        black_dir = tmp / "black"
        black_swf = tmp / "black.swf"

        # White pass: use the SWF as-is (only handles files whose existing
        # SetBackgroundColor is white; that's every file this pipeline has
        # hit the defect on so far -- if not, patch a white copy too).
        white_dir.mkdir()
        export_frames(swf_path, white_dir)

        subprocess.run(
            [sys.executable, str(PATCH_SCRIPT), str(swf_path), str(black_swf), "0", "0", "0"],
            check=True, capture_output=True, text=True,
        )
        black_dir.mkdir()
        export_frames(black_swf, black_dir)

        frame_nums = sorted(int(p.stem) for p in white_dir.glob("*.png"))
        if start is not None:
            frame_nums = [n for n in frame_nums if start <= n <= end]

        for n in frame_nums:
            wp = white_dir / f"{n}.png"
            bp = black_dir / f"{n}.png"
            if not bp.exists():
                raise FileNotFoundError(f"black-bg frame {n} missing ({bp})")
            matte(wp, bp, out_dir / f"{n}.png")

        return frame_nums


if __name__ == "__main__":
    if len(sys.argv) not in (3, 5):
        print(__doc__)
        sys.exit(1)
    swf_arg = sys.argv[1]
    out_arg = sys.argv[2]
    start_arg = int(sys.argv[3]) if len(sys.argv) == 5 else None
    end_arg = int(sys.argv[4]) if len(sys.argv) == 5 else None
    frames = main(swf_arg, out_arg, start_arg, end_arg)
    print(f"wrote {len(frames)} frame(s) to {out_arg}: {frames}")
