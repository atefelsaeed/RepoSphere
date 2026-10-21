#!/usr/bin/env python3
"""Generates the RepoSphere app icon masters into assets/icon/.

Run:  python3 tool/make_icon.py      (needs Pillow)
Then: dart run flutter_launcher_icons

The mark is the in-app logo: a hub with five connected nodes.
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"
S = 1024
SS = 4  # supersampling for smooth edges

INDIGO_LIGHT = (99, 102, 241)   # #6366F1
INDIGO_DARK = (67, 56, 202)     # #4338CA
WHITE = (255, 255, 255, 255)


def gradient(size):
    """Diagonal gradient, light top-left to dark bottom-right."""
    base = Image.new("RGB", (size, size))
    px = base.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(
                round(INDIGO_LIGHT[i] + (INDIGO_DARK[i] - INDIGO_LIGHT[i]) * t)
                for i in range(3)
            )
    return base


def hub(size, scale):
    """Transparent layer with the white hub mark, scaled about the centre."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    c = size / 2
    ring = 262 * scale * size / S
    r_center = 100 * scale * size / S
    r_node = 74 * scale * size / S
    line_w = round(30 * scale * size / S)
    pts = [
        (c + ring * math.cos(math.radians(-90 + k * 72)),
         c + ring * math.sin(math.radians(-90 + k * 72)))
        for k in range(5)
    ]
    for p in pts:
        d.line([(c, c), p], fill=WHITE, width=line_w)
    d.ellipse([c - r_center, c - r_center, c + r_center, c + r_center], fill=WHITE)
    for x, y in pts:
        d.ellipse([x - r_node, y - r_node, x + r_node, y + r_node], fill=WHITE)
    return layer


def down(img):
    return img.resize((S, S), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    big = S * SS

    # 1. Full-bleed square (iOS/Android legacy/web/windows): OS applies its mask.
    bg = gradient(big).convert("RGBA")
    bg.alpha_composite(hub(big, 1.0))
    down(bg).convert("RGB").save(OUT / "icon.png")

    # 2. Android adaptive foreground: content inside the 66% safe zone.
    down(hub(big, 0.62)).save(OUT / "icon_foreground.png")

    # 3. macOS: rounded square with padding and a soft shadow (macOS doesn't mask).
    canvas = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    inset = round(100 * SS)
    box = [inset, inset, big - inset, big - inset]
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle(box, radius=round(185 * SS), fill=255)
    shadow = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [inset, inset + 12 * SS, big - inset, big - inset + 12 * SS],
        radius=round(185 * SS), fill=(0, 0, 0, 90))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14 * SS)))
    tile = gradient(big).convert("RGBA")
    tile.alpha_composite(hub(big, 0.80))
    canvas.paste(tile, (0, 0), mask)
    down(canvas).save(OUT / "icon_macos.png")
    print("wrote", sorted(p.name for p in OUT.iterdir()))


if __name__ == "__main__":
    main()
