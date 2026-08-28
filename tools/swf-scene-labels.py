#!/usr/bin/env python3
"""
Parse the main-timeline DefineSceneAndFrameLabelData tag (tag type 86) of an
SWF and print (1-based frame number, label) pairs. This is a different
mechanism from the per-DefineSprite FrameLabel tag (type 43, handled by
tools/swf-frame-labels.py) -- AS3-published SWFs commonly store main-timeline
frame labels in tag 86 instead, with frame numbers stored directly as
0-based EncodedU32 offsets (no ShowFrame counting needed; the offsets in the
tag are already absolute).

Usage:
    python tools/swf-scene-labels.py <file.swf>

Depends only on the standard library.
"""
import struct
import sys
import zlib
from pathlib import Path


def decompress_body(raw):
    sig = raw[0:3]
    if sig == b"FWS":
        return raw[8:]
    if sig == b"CWS":
        return zlib.decompress(raw[8:])
    raise NotImplementedError(f"Unsupported SWF signature {sig!r} (LZMA/ZWS not handled)")


def read_rect_end(data, offset):
    nbits = data[offset] >> 3
    total_bits = 5 + nbits * 4
    return offset + (total_bits + 7) // 8


def iter_tags(body, start):
    pos = start
    n = len(body)
    while pos + 2 <= n:
        code_and_length = struct.unpack_from("<H", body, pos)[0]
        pos += 2
        tag_type = code_and_length >> 6
        length = code_and_length & 0x3F
        if length == 0x3F:
            length = struct.unpack_from("<I", body, pos)[0]
            pos += 4
        tag_data = body[pos:pos + length]
        pos += length
        if tag_type == 0:
            break
        yield tag_type, tag_data


def read_encoded_u32(data, offset):
    result = 0
    shift = 0
    while True:
        b = data[offset]
        offset += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            break
        shift += 7
    return result, offset


def parse_scene_tag(tag_data):
    """Return a flat list of (1-based frame number, name) pairs.

    Empirically (verified against tmp/glitch-items/alchemy/fertilidust.swf,
    whose expected labels are independently known from
    content/source-manifest.json's item_icon_fertilidust entry), the item
    SWFs in this source tree encode ALL of their named frames -- both the
    nominal "scene" (e.g. "tool_animation") and what would normally be
    separate FrameLabel entries (e.g. the "5","4","3","2","1" quantity-stack
    poses) -- as scene entries sharing one scene_count, with nothing left
    for a following frame_label_count/label section. This function returns
    both the scene entries and any subsequent frame-label entries (if
    present) merged into one ordered list, since both use the identical
    (EncodedU32 0-based offset, null-terminated name) pair shape.
    """
    off = 0
    scene_count, off = read_encoded_u32(tag_data, off)
    result = []
    for _ in range(scene_count):
        offset_val, off = read_encoded_u32(tag_data, off)
        end = tag_data.index(b"\x00", off)
        name = tag_data[off:end].decode("utf-8", "replace")
        off = end + 1
        result.append((offset_val + 1, name))  # 0-based -> 1-based
    if off < len(tag_data):
        label_count, off = read_encoded_u32(tag_data, off)
        for _ in range(label_count):
            frame_num, off = read_encoded_u32(tag_data, off)
            end = tag_data.index(b"\x00", off)
            name = tag_data[off:end].decode("utf-8", "replace")
            off = end + 1
            result.append((frame_num + 1, name))  # 0-based -> 1-based
    return result


def main(swf_path):
    raw = Path(swf_path).read_bytes()
    body = decompress_body(raw)
    offset = read_rect_end(body, 0)
    offset += 4  # frame rate + frame count

    found = False
    for tag_type, tag_data in iter_tags(body, offset):
        if tag_type == 86:  # DefineSceneAndFrameLabelData
            found = True
            for frame, name in parse_scene_tag(tag_data):
                print(f"{frame}\t{name}")
    if not found:
        print("(no DefineSceneAndFrameLabelData tag found)", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1])
