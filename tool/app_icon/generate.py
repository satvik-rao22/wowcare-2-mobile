#!/usr/bin/env python3
"""Render the square launcher-icon sources from the brand mark.

The brand mark (assets/bgImages/WowCare_2.png) sits on a 1000x1240 canvas with
uneven transparent padding, so it cannot feed flutter_launcher_icons directly:
a non-square source is resized onto the square icon grid and comes out squashed.
This trims the artwork to its own bounds and re-centres it on a 1024 square.

Run from the repo root:

    python3 tool/app_icon/generate.py
    dart run flutter_launcher_icons

Requires Pillow (`python3 -m pip install Pillow`).
"""

from pathlib import Path

from PIL import Image

SOURCE = Path("assets/bgImages/WowCare_2.png")
OUT_DIR = Path("tool/app_icon")
CANVAS = 1024

# Legacy/iOS icons are shown whole, so the mark can fill most of the square.
#
# The adaptive foreground is near full-bleed on purpose. Android masks that
# layer to a circle or squircle, but flutter_launcher_icons already writes
# `android:inset="16%"` into mipmap-anydpi-v26/ic_launcher.xml, which renders
# the drawable at 68% of the 108dp layer -- just inside the 72dp safe zone.
# Pre-shrinking the mark here as well would multiply the two insets together
# and leave it swimming in white space.
VARIANTS = {
    "wowcare_app_icon.png": 0.86,
    "wowcare_app_icon_foreground.png": 0.92,
}


def main() -> None:
    art = Image.open(SOURCE).convert("RGBA")
    art = art.crop(art.getbbox())  # tight bounds of the non-transparent mark
    aw, ah = art.size

    for name, scale in VARIANTS.items():
        target = CANVAS * scale
        ratio = min(target / aw, target / ah)
        w, h = int(aw * ratio), int(ah * ratio)

        canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        canvas.paste(art.resize((w, h), Image.LANCZOS), ((CANVAS - w) // 2, (CANVAS - h) // 2))
        canvas.save(OUT_DIR / name)
        print(f"{OUT_DIR / name}: {w}x{h} mark on {CANVAS}x{CANVAS} ({scale:.0%})")


if __name__ == "__main__":
    main()
