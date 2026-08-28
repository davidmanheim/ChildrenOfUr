#!/usr/bin/env python3
"""
One-off batch driver for the food.json conversion pass (2026-08-28).
Not part of the general pipeline; ad hoc script kept for reproducibility.

For each food item id -> source swf, run:
    ffdec -ignorebackground -export frame <tmpdir> <swf>
which (per tools/README-swf-pipeline.md) renders the main timeline with a
genuinely transparent background, verified equivalent to the
swf-patch-bgcolor.py/swf-export-frame-alpha.py difference-matting approach.

Then: frame 1 -> icon.png; remaining frames (2..N) packed into a horizontal
strip -> sprite.png (if N==1, reuse frame 1 for both, matching the
tool/alchemistry_kit precedent for genuinely single-frame sources).

Writes outputs to content/sprites/items/<id>/{icon,sprite}.png and
coUclient/web/files/sprites/generated/converted/item-<id>-{icon,sprite}.png.

Verifies real alpha variance (PIL extrema != (255,255)) before accepting.

Usage:
    python tools/batch-convert-food.py <mapping.json> <out_log.json>

mapping.json: {"item_id": "path/to/source.swf", ...}
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
FFDEC_JAR = REPO_ROOT / "ffdec" / "ffdec.jar"

CONTENT_SPRITES = REPO_ROOT / "content" / "sprites" / "items"
CLIENT_SPRITES = REPO_ROOT / "coUclient" / "web" / "files" / "sprites" / "generated" / "converted"


def export_frames(swf_path, out_dir):
    proc = subprocess.run(
        ["java", "-jar", str(FFDEC_JAR), "-ignorebackground", "-export", "frame", str(out_dir), str(swf_path)],
        capture_output=True, text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"ffdec failed: {proc.stdout}\n{proc.stderr}")
    # Count exported N.png files
    n = 0
    while (out_dir / f"{n+1}.png").exists():
        n += 1
    return n


def build_strip(frame_paths, out_png):
    frames = [Image.open(p) for p in frame_paths]
    sizes = {im.size for im in frames}
    if len(sizes) != 1:
        raise ValueError(f"inconsistent frame geometry: {sizes} for {frame_paths}")
    w, h = sizes.pop()
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, im in enumerate(frames):
        sheet.paste(im, (i * w, 0))
    out_png.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_png)
    return w, h, len(frames)


def verify_alpha(png_path):
    im = Image.open(png_path)
    extrema = im.split()[-1].getextrema()
    return extrema


def main(mapping_path, log_path):
    mapping = json.loads(Path(mapping_path).read_text(encoding="utf-8"))
    results = {}

    with tempfile.TemporaryDirectory(dir=str(REPO_ROOT / "tmp")) as tmp:
        tmp = Path(tmp)
        for item_id, swf_rel in mapping.items():
            swf_path = REPO_ROOT / swf_rel
            item_out = tmp / item_id
            try:
                n = export_frames(swf_path, item_out)
                if n < 1:
                    raise RuntimeError("no frames exported")

                frame1 = item_out / "1.png"
                extrema1 = verify_alpha(frame1)
                if extrema1 == (255, 255):
                    raise RuntimeError(f"frame 1 opaque, extrema={extrema1}")

                icon_dst_content = CONTENT_SPRITES / item_id / "icon.png"
                icon_dst_client = CLIENT_SPRITES / f"item-{item_id}-icon.png"
                icon_dst_content.parent.mkdir(parents=True, exist_ok=True)
                icon_im = Image.open(frame1).convert("RGBA")
                icon_im.save(icon_dst_content)
                icon_im.save(icon_dst_client)
                icon_w, icon_h = icon_im.size

                if n == 1:
                    sprite_dst_content = CONTENT_SPRITES / item_id / "sprite.png"
                    sprite_dst_client = CLIENT_SPRITES / f"item-{item_id}-sprite.png"
                    icon_im.save(sprite_dst_content)
                    icon_im.save(sprite_dst_client)
                    sprite_w, sprite_h, sprite_n = icon_w, icon_h, 1
                    sprite_range = [1, 1]
                else:
                    frame_paths = [item_out / f"{k}.png" for k in range(2, n + 1)]
                    for fp in frame_paths:
                        ex = verify_alpha(fp)
                        if ex == (255, 255):
                            raise RuntimeError(f"{fp.name} opaque, extrema={ex}")
                    sprite_dst_content = CONTENT_SPRITES / item_id / "sprite.png"
                    sprite_w, sprite_h, sprite_n = build_strip(frame_paths, sprite_dst_content)
                    sprite_dst_client = CLIENT_SPRITES / f"item-{item_id}-sprite.png"
                    Image.open(sprite_dst_content).save(sprite_dst_client)
                    sprite_range = [2, n]

                sprite_extrema = verify_alpha(sprite_dst_content)

                results[item_id] = {
                    "ok": True,
                    "totalFrames": n,
                    "icon": {"file": str(icon_dst_content.relative_to(REPO_ROOT)).replace("\\", "/"),
                             "runtimeFile": str(icon_dst_client.relative_to(REPO_ROOT)).replace("\\", "/"),
                             "frameWidth": icon_w, "frameHeight": icon_h, "numFrames": 1,
                             "sourceFrameRange": [1, 1], "alphaExtrema": list(extrema1)},
                    "sprite": {"file": str(sprite_dst_content.relative_to(REPO_ROOT)).replace("\\", "/"),
                               "runtimeFile": str(sprite_dst_client.relative_to(REPO_ROOT)).replace("\\", "/"),
                               "frameWidth": sprite_w, "frameHeight": sprite_h, "numFrames": sprite_n,
                               "sourceFrameRange": sprite_range, "alphaExtrema": list(sprite_extrema)},
                    "sourcePath": swf_rel,
                }
                print(f"OK {item_id}: {n} frames, icon {icon_w}x{icon_h}, sprite {sprite_w}x{sprite_h}x{sprite_n}")
            except Exception as e:
                results[item_id] = {"ok": False, "error": str(e), "sourcePath": swf_rel}
                print(f"FAIL {item_id}: {e}")

    Path(log_path).write_text(json.dumps(results, indent=2), encoding="utf-8")
    ok = sum(1 for r in results.values() if r["ok"])
    print(f"\n{ok}/{len(results)} converted successfully")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
