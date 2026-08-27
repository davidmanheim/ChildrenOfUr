#!/usr/bin/env python3
"""
Resolve real (1-based) animation frame numbers for the named FrameLabel tags
inside a chosen symbol (DefineSprite) of an SWF file, and/or list every
DefineSprite character id with a SymbolClass name if one is exported.

Part of the reproducible FLA/SWF -> browser-safe sprite conversion pipeline
described in CONTENT_RECOVERY_PLAN.md (Implementation order step 1).

Why this exists: `ffdec -dumpSWF` prints a per-nested-tag-list counter next
to each FrameLabel, which is NOT the real SWF animation frame number (that
requires counting ShowFrame tags). This script counts ShowFrame tags itself
so state boundaries (e.g. "walk" -> frames 1-26) can be computed
automatically instead of by hand, and so the same recipe stays correct if
the source SWF is re-fetched or replaced.

Usage:
    # List every character id with a symbol-class name (finds the root symbol)
    python tools/swf-frame-labels.py symbols <file.swf>

    # List (frame_number, label) pairs for one DefineSprite character id
    python tools/swf-frame-labels.py labels <file.swf> <char_id>

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


def iter_tags(body, start, end=None):
    pos = start
    n = len(body) if end is None else end
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


def find_symbol_names(body, start):
    names = {}
    for tag_type, tag_data in iter_tags(body, start):
        if tag_type == 76:  # SymbolClass
            count = struct.unpack_from("<H", tag_data, 0)[0]
            off = 2
            for _ in range(count):
                char_id = struct.unpack_from("<H", tag_data, off)[0]
                off += 2
                end = tag_data.index(b"\x00", off)
                name = tag_data[off:end].decode("utf-8", "replace")
                off = end + 1
                names[char_id] = name
    return names


def find_sprite_body(body, start, target_id):
    """Return the tag-body slice for DefineSprite(target_id), scanning
    top-level tags only (nested sprites-within-sprites are not recursed
    into; none of the inventoried entities need that)."""
    for tag_type, tag_data in iter_tags(body, start):
        if tag_type == 39:  # DefineSprite
            char_id = struct.unpack_from("<H", tag_data, 0)[0]
            if char_id == target_id:
                # frame_count = struct.unpack_from("<H", tag_data, 2)[0]
                return tag_data[4:]
    return None


def frame_labels(sprite_body):
    frame = 1
    labels = []
    for tag_type, tag_data in iter_tags(sprite_body, 0):
        if tag_type == 1:  # ShowFrame
            frame += 1
        elif tag_type == 43:  # FrameLabel
            end = tag_data.index(b"\x00")
            name = tag_data[:end].decode("utf-8", "replace")
            labels.append((frame, name))
    return labels


def load(swf_path):
    raw = Path(swf_path).read_bytes()
    body = decompress_body(raw)
    offset = read_rect_end(body, 0)
    offset += 4  # frame rate + frame count
    return body, offset


def cmd_symbols(swf_path):
    body, offset = load(swf_path)
    names = find_symbol_names(body, offset)
    for char_id, name in sorted(names.items()):
        print(f"{char_id}\t{name}")


def cmd_labels(swf_path, char_id):
    body, offset = load(swf_path)
    sprite_body = find_sprite_body(body, offset, int(char_id))
    if sprite_body is None:
        print(f"DefineSprite chid={char_id} not found at top level", file=sys.stderr)
        sys.exit(1)
    labels = frame_labels(sprite_body)
    for frame, name in labels:
        print(f"{frame}\t{name}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "symbols":
        cmd_symbols(sys.argv[2])
    elif cmd == "labels":
        if len(sys.argv) != 4:
            print(__doc__)
            sys.exit(1)
        cmd_labels(sys.argv[2], sys.argv[3])
    else:
        print(__doc__)
        sys.exit(1)
