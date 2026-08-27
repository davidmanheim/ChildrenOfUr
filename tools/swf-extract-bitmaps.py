#!/usr/bin/env python3
"""
Minimal, dependency-light SWF bitmap-tag extractor.

Purpose: part of the reproducible FLA/SWF -> browser-safe sprite conversion
pipeline described in CONTENT_RECOVERY_PLAN.md. It does not attempt to
render SWF vector shapes; it extracts the embedded raster image tags
(DefineBits / DefineBitsJPEG2/3/4 / DefineBitsLossless/2) that Flash sprite
sheets typically store their baked frame art in, and writes each one out as
a PNG.

This is intentionally a small, auditable, standalone script (stdlib +
Pillow only) rather than a dependency on abandoned third-party SWF
libraries (pyswf, swf-extract) that do not install cleanly in this
environment (see content/source-manifest.json / tooling notes for why).

Usage:
    python tools/swf-extract-bitmaps.py <input.swf> <output_dir>

Writes <output_dir>/tag<id>_<WxH>.png for every recognized bitmap tag, plus
<output_dir>/manifest.json describing what was found (tag id, type, size,
and any shapes/tags that were present but NOT extracted, e.g. vector-only
DefineShape tags with no bitmap fill data recovered by this tool).
"""
import io
import json
import struct
import sys
import zlib
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow is required: pip install Pillow", file=sys.stderr)
    raise

TAG_NAMES = {
    2: "DefineShape", 6: "DefineBits", 8: "JPEGTables",
    20: "DefineBitsLossless", 21: "DefineBitsJPEG2", 22: "DefineShape2",
    32: "DefineShape3", 35: "DefineBitsJPEG3", 36: "DefineBitsLossless2",
    39: "DefineSprite", 43: "FrameLabel", 46: "DefineMorphShape",
    48: "DefineFont2", 56: "ExportAssets", 76: "SymbolClass",
    82: "DoABC", 83: "DefineShape4", 90: "DefineBitsJPEG4",
}
BITMAP_TAGS = {6, 20, 21, 35, 36, 90}


class BitReader:
    """Reads an SWF RECT (variable-length bit-packed rectangle)."""

    def __init__(self, data, offset):
        self.data = data
        self.byte_pos = offset
        self.bit_pos = 0

    def read_bits(self, n):
        value = 0
        for _ in range(n):
            byte = self.data[self.byte_pos]
            bit = (byte >> (7 - self.bit_pos)) & 1
            value = (value << 1) | bit
            self.bit_pos += 1
            if self.bit_pos == 8:
                self.bit_pos = 0
                self.byte_pos += 1
        return value

    def read_signed(self, n):
        value = self.read_bits(n)
        if value & (1 << (n - 1)):
            value -= (1 << n)
        return value

    def byte_offset_after(self):
        return self.byte_pos + (1 if self.bit_pos else 0)


def read_rect(data, offset):
    r = BitReader(data, offset)
    nbits = r.read_bits(5)
    xmin = r.read_signed(nbits)
    xmax = r.read_signed(nbits)
    ymin = r.read_signed(nbits)
    ymax = r.read_signed(nbits)
    twips = 20.0
    return {
        "xmin": xmin / twips, "xmax": xmax / twips,
        "ymin": ymin / twips, "ymax": ymax / twips,
        "width_px": round((xmax - xmin) / twips),
        "height_px": round((ymax - ymin) / twips),
    }, r.byte_offset_after()


def decompress_body(raw):
    sig = raw[0:3]
    version = raw[3]
    file_length = struct.unpack_from("<I", raw, 4)[0]
    header = raw[0:8]
    if sig == b"FWS":
        body = raw[8:]
    elif sig == b"CWS":
        body = zlib.decompress(raw[8:])
    elif sig == b"ZWS":
        raise NotImplementedError(
            "LZMA-compressed SWF (ZWS) is not supported by this minimal "
            "extractor; none of the inventoried assets use it as of this "
            "writing (all are CWS/zlib).")
    else:
        raise ValueError(f"Not an SWF file (bad signature {sig!r})")
    return header, version, file_length, body


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
        if tag_type == 0:  # End
            break
        yield tag_type, tag_data
    return


def decode_lossless(tag_data, has_alpha):
    char_id = struct.unpack_from("<H", tag_data, 0)[0]
    fmt = tag_data[2]
    width, height = struct.unpack_from("<HH", tag_data, 3)
    body_off = 7
    if fmt == 3:
        color_table_size = tag_data[body_off]
        body_off += 1
    compressed = tag_data[body_off:]
    raw = zlib.decompress(compressed)

    if fmt == 3:
        # 8-bit colormapped: palette (RGB or RGBA) then indexed rows,
        # each row padded to a 4-byte boundary.
        n_colors = color_table_size + 1
        entry_size = 4 if has_alpha else 3
        palette = raw[:n_colors * entry_size]
        pixels = raw[n_colors * entry_size:]
        row_bytes = (width + 3) & ~3
        img = Image.new("RGBA" if has_alpha else "RGB", (width, height))
        px = img.load()
        for y in range(height):
            row = pixels[y * row_bytes: y * row_bytes + width]
            for x in range(width):
                idx = row[x]
                base = idx * entry_size
                if has_alpha:
                    r, g, b, a = palette[base:base + 4]
                    px[x, y] = (r, g, b, a)
                else:
                    r, g, b = palette[base:base + 3]
                    px[x, y] = (r, g, b)
        return img.convert("RGBA"), char_id, width, height

    # fmt 4 = 15-bit RGB (DefineBitsLossless only), fmt 5 = 32-bit ARGB
    # (or 24-bit RGB packed in 32 bits for DefineBitsLossless).
    img = Image.new("RGBA", (width, height))
    px = img.load()
    if fmt == 4:
        row_bytes = ((width * 2) + 3) & ~3
        for y in range(height):
            row = raw[y * row_bytes: y * row_bytes + width * 2]
            for x in range(width):
                word = struct.unpack_from("<H", row, x * 2)[0]
                r = (word >> 10) & 0x1F
                g = (word >> 5) & 0x1F
                b = word & 0x1F
                px[x, y] = (r << 3, g << 3, b << 3, 255)
    else:
        row_bytes = width * 4
        for y in range(height):
            row = raw[y * row_bytes: y * row_bytes + row_bytes]
            for x in range(width):
                a, r, g, b = row[x * 4:x * 4 + 4]
                if not has_alpha:
                    a = 255
                # SWF lossless32 alpha is *not* premultiplied for
                # DefineBitsLossless; DefineBitsLossless2 (has_alpha) IS
                # stored premultiplied per the SWF spec.
                if has_alpha and a not in (0, 255):
                    r = min(255, r * 255 // a) if a else 0
                    g = min(255, g * 255 // a) if a else 0
                    b = min(255, b * 255 // a) if a else 0
                px[x, y] = (r, g, b, a)
    return img, char_id, width, height


def fix_jpeg_data(data):
    # SWF DefineBits/JPEG2 data occasionally begins with an erroneous
    # extra SOI/EOI marker pair (FF D9 FF D8) right after the true leading
    # FF D8; strip it if present, per well-known SWF JPEG quirks.
    if data[0:2] == b"\xff\xd8" and data[2:6] == b"\xff\xd9\xff\xd8":
        return data[0:2] + data[6:]
    return data


def decode_jpeg2(tag_data):
    char_id = struct.unpack_from("<H", tag_data, 0)[0]
    jpeg_data = fix_jpeg_data(tag_data[2:])
    img = Image.open(io.BytesIO(jpeg_data)).convert("RGBA")
    return img, char_id, img.width, img.height


def decode_jpeg3(tag_data, with_deblock=False):
    char_id = struct.unpack_from("<H", tag_data, 0)[0]
    off = 2
    if with_deblock:
        off += 2  # DeblockParam (fixed 8.8) for DefineBitsJPEG4
    alpha_data_offset = struct.unpack_from("<I", tag_data, off)[0]
    off += 4
    jpeg_data = fix_jpeg_data(tag_data[off:off + alpha_data_offset])
    alpha_compressed = tag_data[off + alpha_data_offset:]
    img = Image.open(io.BytesIO(jpeg_data)).convert("RGB")
    try:
        alpha_raw = zlib.decompress(alpha_compressed)
        alpha_img = Image.frombytes("L", img.size, alpha_raw)
        img = img.convert("RGBA")
        img.putalpha(alpha_img)
    except Exception:
        img = img.convert("RGBA")
    return img, char_id, img.width, img.height


def extract(swf_path, out_dir):
    raw = Path(swf_path).read_bytes()
    header, version, file_length, body = decompress_body(raw)
    frame_rect, offset = read_rect(body, 0)
    # frame rate (2 bytes) + frame count (2 bytes)
    offset += 4

    out_dir.mkdir(parents=True, exist_ok=True)
    found = []
    unextracted_shapes = 0
    tag_counts = {}

    for tag_type, tag_data in iter_tags(body, offset):
        name = TAG_NAMES.get(tag_type, f"tag{tag_type}")
        tag_counts[name] = tag_counts.get(name, 0) + 1
        if tag_type in (2, 22, 32, 83):
            unextracted_shapes += 1
            continue
        if tag_type not in BITMAP_TAGS:
            continue
        try:
            if tag_type == 20:
                img, char_id, w, h = decode_lossless(tag_data, has_alpha=False)
            elif tag_type == 36:
                img, char_id, w, h = decode_lossless(tag_data, has_alpha=True)
            elif tag_type == 21:
                img, char_id, w, h = decode_jpeg2(tag_data)
            elif tag_type == 35:
                img, char_id, w, h = decode_jpeg3(tag_data, with_deblock=False)
            elif tag_type == 90:
                img, char_id, w, h = decode_jpeg3(tag_data, with_deblock=True)
            else:
                continue  # tag 6 DefineBits (needs external JPEGTables) - rare/unsupported here
        except Exception as exc:
            found.append({
                "tag": name, "error": str(exc), "extracted": False,
            })
            continue

        out_name = f"tag{char_id}_{w}x{h}.png"
        img.save(out_dir / out_name)
        found.append({
            "tag": name, "char_id": char_id, "width": w, "height": h,
            "file": out_name, "extracted": True,
        })

    manifest = {
        "source": str(swf_path),
        "swf_version": version,
        "frame_rect_px": {"width": frame_rect["width_px"], "height": frame_rect["height_px"]},
        "tag_counts": tag_counts,
        "unextracted_vector_shape_tags": unextracted_shapes,
        "bitmaps": found,
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))
    return manifest


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    m = extract(sys.argv[1], Path(sys.argv[2]))
    print(json.dumps(m, indent=2))
