"""
Generates print assets from data/projects.json.

  python make_assets.py https://YOURUSERNAME.github.io/ar-estate/

Outputs (in ./assets):
  marker.png                  ONE shared AR marker. Compile this once into targets.mind.
  qr_<project>_<cp>.png       QR code per project + channel partner
  card_<project>_<cp>.png     Sample card face: shared marker (left) + that CP's QR (right)

Because the marker is identical on every item, you compile targets.mind ONCE.
Only the QR/NFC link differs per project and per channel partner.

Requires: pip install pillow qrcode
"""
import json
import random
import sys
from pathlib import Path

import qrcode
from PIL import Image, ImageDraw, ImageFont

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "https://YOURUSERNAME.github.io/ar-estate/"
if not BASE_URL.endswith("/"):
    BASE_URL += "/"

data = json.loads(Path("data/projects.json").read_text(encoding="utf-8"))
out = Path("assets")
out.mkdir(exist_ok=True)

COLORS = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#F9FAFB", "#14B8A6"]


def font(size, bold=False):
    for name in ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf", "arial.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def make_marker(path, size=800):
    """Dense random triangles: many sharp corners = many tracking feature points."""
    random.seed(7)  # fixed seed -> identical marker every run
    img = Image.new("RGB", (size, size), "#0B1220")
    d = ImageDraw.Draw(img)
    for _ in range(170):
        x, y = random.randint(0, size), random.randint(0, size)
        pts = [(x + random.randint(-120, 120), y + random.randint(-120, 120)) for _ in range(3)]
        d.polygon(pts, fill=random.choice(COLORS), outline="#0B1220")
    img.save(path)
    return img


def make_qr(url, px=280):
    qr = qrcode.QRCode(box_size=8, border=2, error_correction=qrcode.constants.ERROR_CORRECT_M)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white").convert("RGB")
    return img.resize((px, px), Image.NEAREST)


marker = make_marker(out / "marker.png")
print("Wrote assets/marker.png  <- compile THIS into targets.mind")

for pid, p in data["projects"].items():
    cps = [""] + list((p.get("cps") or {}).keys())  # "" = generic link with no CP
    for cp in cps:
        url = f"{BASE_URL}?p={pid}" + (f"&cp={cp}" if cp else "")
        tag = f"{pid}_{cp or 'direct'}"

        qr_img = make_qr(url)
        qr_img.save(out / f"qr_{tag}.png")

        card = Image.new("RGB", (1050, 600), "#0B1220")
        card.paste(marker.resize((600, 600)), (0, 0))
        d = ImageDraw.Draw(card)
        d.text((640, 50), p["name"], font=font(40, True), fill="#F9FAFB")
        d.text((640, 110), "Scan for live updates", font=font(24), fill="#93C5FD")
        if cp:
            d.text((640, 160), p["cps"][cp]["name"], font=font(24), fill="#D1D5DB")
        card.paste(qr_img, (710, 270))
        card.save(out / f"card_{tag}.png", dpi=(300, 300))
        print(f"Wrote card_{tag}.png  ->  {url}")
