"""Generate app icon and splash branding for Qarz Daftarchasi.

Outputs:
  qarzdaftar/assets/branding/icon.png            (1024x1024 main launcher icon)
  qarzdaftar/assets/branding/icon_foreground.png (1024x1024 adaptive icon foreground)
  qarzdaftar/assets/branding/splash.png          (1024x1024 splash logo, transparent bg)
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import sys

OUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "qarzdaftar",
    "assets",
    "branding",
)
os.makedirs(OUT_DIR, exist_ok=True)

PRIMARY = (13, 110, 253)   # #0D6EFD
ACCENT = (79, 70, 229)     # #4F46E5
WHITE = (255, 255, 255)


def gradient_square(size: int, c1, c2):
    img = Image.new("RGB", (size, size), c1)
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        r = int(c1[0] * (1 - t) + c2[0] * t)
        g = int(c1[1] * (1 - t) + c2[1] * t)
        b = int(c1[2] * (1 - t) + c2[2] * t)
        for x in range(size):
            px[x, y] = (r, g, b)
    return img


def round_corners(img: Image.Image, radius: int) -> Image.Image:
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    out = Image.new("RGBA", (w, h))
    out.paste(img, (0, 0), mask)
    return out


def find_font(prefer_size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf",
        "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/arial.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, prefer_size)
            except Exception:
                pass
    return ImageFont.load_default()


def draw_logo_letters(img: Image.Image, color=WHITE, scale: float = 0.55):
    w, h = img.size
    draw = ImageDraw.Draw(img)
    text = "QD"
    font = find_font(int(h * scale))
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    cx = (w - tw) / 2 - bbox[0]
    cy = (h - th) / 2 - bbox[1] - int(h * 0.02)
    draw.text((cx, cy), text, fill=color, font=font)


def draw_book_mark(img: Image.Image, color=WHITE):
    """Draw a stylized book/notebook with a coin shape."""
    w, h = img.size
    draw = ImageDraw.Draw(img, "RGBA")
    # Notebook outline
    margin = int(w * 0.22)
    bx = margin
    by = int(h * 0.26)
    bw = w - margin * 2
    bh = int(h * 0.50)
    radius = int(bw * 0.08)
    draw.rounded_rectangle(
        (bx, by, bx + bw, by + bh), radius=radius, fill=(255, 255, 255, 240)
    )
    # Three lines on the notebook
    line_color = PRIMARY
    line_x1 = bx + int(bw * 0.18)
    line_x2 = bx + int(bw * 0.82)
    line_thickness = max(int(h * 0.014), 4)
    for i in range(3):
        ly = by + int(bh * (0.30 + i * 0.20))
        draw.rounded_rectangle(
            (line_x1, ly, line_x2, ly + line_thickness),
            radius=line_thickness // 2,
            fill=line_color,
        )
    # Coin overlapping the notebook (top-right)
    coin_d = int(w * 0.32)
    coin_x = bx + bw - int(coin_d * 0.55)
    coin_y = by - int(coin_d * 0.35)
    draw.ellipse(
        (coin_x, coin_y, coin_x + coin_d, coin_y + coin_d),
        fill=(245, 158, 11, 255),  # warning/amber
        outline=(180, 110, 0),
        width=max(int(h * 0.008), 3),
    )
    # Coin "₿"-like marker
    font = find_font(int(coin_d * 0.55))
    txt = "$"
    bbox = draw.textbbox((0, 0), txt, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(
        (coin_x + (coin_d - tw) / 2 - bbox[0], coin_y + (coin_d - th) / 2 - bbox[1]),
        txt,
        fill=(120, 70, 0),
        font=font,
    )


def make_icon(size: int = 1024, with_book: bool = True) -> Image.Image:
    bg = gradient_square(size, PRIMARY, ACCENT)
    rounded = round_corners(bg, int(size * 0.22))
    if with_book:
        draw_book_mark(rounded)
    else:
        draw_logo_letters(rounded)
    return rounded


def make_foreground(size: int = 1024) -> Image.Image:
    """Adaptive icon foreground — transparent bg with the symbol inset."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inset = int(size * 0.25)
    inner_size = size - inset * 2
    inner = Image.new("RGBA", (inner_size, inner_size), (0, 0, 0, 0))
    draw_book_mark(inner, color=WHITE)
    img.paste(inner, (inset, inset), inner)
    return img


def make_splash(size: int = 1024) -> Image.Image:
    """Splash logo — transparent bg, gradient circle with mark inside."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # Soft glow behind
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse(
        (int(size * 0.05), int(size * 0.05), int(size * 0.95), int(size * 0.95)),
        fill=(*PRIMARY, 40),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(int(size * 0.05)))
    img = Image.alpha_composite(img, glow)
    # Main circle
    circle = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(circle)
    cdraw.ellipse(
        (int(size * 0.15), int(size * 0.15), int(size * 0.85), int(size * 0.85)),
        fill=(*PRIMARY, 255),
    )
    img = Image.alpha_composite(img, circle)
    # Place book mark
    inner_size = int(size * 0.55)
    inner = Image.new("RGBA", (inner_size, inner_size), (0, 0, 0, 0))
    draw_book_mark(inner, color=WHITE)
    offset = (size - inner_size) // 2
    img.paste(inner, (offset, offset), inner)
    return img


def main():
    icon = make_icon(1024, with_book=True)
    icon_path = os.path.join(OUT_DIR, "icon.png")
    icon.save(icon_path)
    print(f"wrote {icon_path}")

    fg = make_foreground(1024)
    fg_path = os.path.join(OUT_DIR, "icon_foreground.png")
    fg.save(fg_path)
    print(f"wrote {fg_path}")

    splash = make_splash(1024)
    splash_path = os.path.join(OUT_DIR, "splash.png")
    splash.save(splash_path)
    print(f"wrote {splash_path}")


if __name__ == "__main__":
    main()
