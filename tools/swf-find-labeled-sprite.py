#!/usr/bin/env python3
"""
Find the top-level DefineSprite in an SWF whose FrameLabel tags include a
given label name (e.g. "open"), and print its character id, total frame
count, and full label list.

Extends tools/swf-frame-labels.py for source assets (the shrine family) where
the animated/interactive content lives in one specific named top-level
DefineSprite among many single-frame decoration/mask sprites, rather than
being exported via SymbolClass or being the single obvious root timeline.
Written while converting the 11 giant shrines in
coUserver/lib/entities/npcs/shrines/ -- see content/source-manifest.json.

Usage:
    python tools/swf-find-labeled-sprite.py <file.swf> <label_name>

Depends only on the standard library (reuses swf-frame-labels.py's parsing
helpers via importlib, since '-' in the filename blocks a normal import).
"""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "swf_frame_labels", Path(__file__).with_name("swf-frame-labels.py")
)
sfl = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sfl)


def find_labeled_sprite(swf_path, label_name):
    body, offset = sfl.load(swf_path)
    results = []
    for tag_type, tag_data in sfl.iter_tags(body, offset):
        if tag_type != 39:  # DefineSprite
            continue
        char_id = sfl.struct.unpack_from("<H", tag_data, 0)[0]
        sprite_body = tag_data[4:]
        labels = sfl.frame_labels(sprite_body)
        if any(name == label_name for _, name in labels):
            frame = 1
            for tt, td in sfl.iter_tags(sprite_body, 0):
                if tt == 1:
                    frame += 1
            results.append((char_id, frame - 1, labels))
    return results


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    for char_id, total_frames, labels in find_labeled_sprite(sys.argv[1], sys.argv[2]):
        print(f"charId={char_id} totalFrames={total_frames} labels={labels}")
