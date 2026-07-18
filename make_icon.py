#!/usr/bin/env python3
"""Bold single-emblem app icon: one oversized "2" playing card (the "heo" — strongest
card in Sâm Lốc) tilted on a felt-green gradient. No detailed scene, no text."""

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), "#0a2015")
draw = ImageDraw.Draw(img)

top = (8, 46, 28)
bottom = (5, 20, 13)
for y in range(SIZE):
    t = y / SIZE
    r = int(top[0] + (bottom[0] - top[0]) * t)
    g = int(top[1] + (bottom[1] - top[1]) * t)
    b = int(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

card_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
cdraw = ImageDraw.Draw(card_layer)
cw, ch = SIZE * 0.62, SIZE * 0.92
cx, cy = SIZE / 2, SIZE / 2
cdraw.rounded_rectangle(
    [cx - cw / 2, cy - ch / 2, cx + cw / 2, cy + ch / 2],
    radius=SIZE * 0.06, fill=(250, 247, 238, 255)
)

red = (196, 30, 40, 255)
try:
    font_big = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", int(SIZE * 0.40))
    font_pip = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", int(SIZE * 0.20))
except OSError:
    font_big = ImageFont.load_default()
    font_pip = font_big

def centered_text(d, text, font, cx, cy, fill):
    bbox = d.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text((cx - w / 2 - bbox[0], cy - h / 2 - bbox[1]), text, font=font, fill=fill)

centered_text(cdraw, "2", font_big, cx, cy - SIZE * 0.06, red)
centered_text(cdraw, "♥", font_pip, cx, cy + SIZE * 0.28, red)

rotated = card_layer.rotate(-8, resample=Image.BICUBIC, expand=False, center=(cx, cy))
img.paste(rotated, (0, 0), rotated)

img.save("/Users/user/SamLoc/SamLoc/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
print("wrote AppIcon.png", img.size)
