#!/usr/bin/env python3
"""
Patch the SetBackgroundColor tag (tag type 9) of an SWF file in place to a
chosen RGB color, writing the result to a new file. Used as part of a
difference-matting workaround for a known ffdec CLI defect: `-export frame`
(main-timeline frame export) always composites onto the SWF's own
SetBackgroundColor as an opaque backdrop -- unlike `-export sprite`
(per-symbol export), which renders with genuine alpha. `-config
lastExportTransparentBackground=true` does not affect `-export frame`
(verified empirically). Exporting the same frame once against white and once
against black and solving the standard difference-matting equations recovers
true per-pixel alpha without needing an external SVG rasterizer (none with a
working native cairo/dll was available in this environment).

Usage:
    python tools/swf-patch-bgcolor.py <in.swf> <out.swf> <r> <g> <b>

Only handles uncompressed (FWS) and zlib-compressed (CWS) SWFs (same subset
tools/swf-frame-labels.py already assumes); re-compresses CWS output.
"""
import struct
import sys
import zlib
from pathlib import Path


def patch(in_path, out_path, r, g, b):
    raw = Path(in_path).read_bytes()
    sig = raw[0:3]
    header = bytearray(raw[0:8])
    if sig == b"FWS":
        body = raw[8:]
    elif sig == b"CWS":
        body = zlib.decompress(raw[8:])
    else:
        raise NotImplementedError(f"Unsupported SWF signature {sig!r}")

    body = bytearray(body)

    # Skip the RECT (stage size) + frame rate (2 bytes) + frame count (2 bytes).
    nbits = body[0] >> 3
    total_bits = 5 + nbits * 4
    pos = (total_bits + 7) // 8
    pos += 4  # frame rate + frame count

    patched = False
    while pos + 2 <= len(body):
        code_and_length = struct.unpack_from("<H", body, pos)[0]
        tag_type = code_and_length >> 6
        length = code_and_length & 0x3F
        tag_header_len = 2
        if length == 0x3F:
            length = struct.unpack_from("<I", body, pos + 2)[0]
            tag_header_len = 6
        data_start = pos + tag_header_len
        if tag_type == 9:  # SetBackgroundColor
            if length != 3:
                raise ValueError(f"unexpected SetBackgroundColor length {length}")
            body[data_start:data_start + 3] = bytes([r, g, b])
            patched = True
            break
        if tag_type == 0:
            break
        pos = data_start + length

    if not patched:
        raise ValueError("SetBackgroundColor tag (type 9) not found")

    if sig == b"FWS":
        out = bytes(header) + bytes(body)
    else:
        out = bytes(header) + zlib.compress(bytes(body), 9)

    # File length field (bytes 4-8) must reflect the (uncompressed) total.
    out = bytearray(out)
    struct.pack_into("<I", out, 4, 8 + len(body))
    Path(out_path).write_bytes(bytes(out))


if __name__ == "__main__":
    if len(sys.argv) != 6:
        print(__doc__)
        sys.exit(1)
    patch(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]))
    print(f"wrote {sys.argv[2]}")
