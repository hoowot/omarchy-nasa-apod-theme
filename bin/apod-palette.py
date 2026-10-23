#!/usr/bin/env python3
# Builds an Omarchy colors.toml from an image.
#
#   apod-palette.py <image> <colors.toml>
#
# Quantizes the image to 16 colors with ImageMagick, takes the most common
# color as the background, the most saturated color that contrasts with it
# as the accent, and fills the named ANSI colors from image hues where the
# image has one close enough (otherwise from the accent's saturation).
import sys, subprocess, colorsys, re


# Resource limits for ImageMagick, so a crafted image can't use unbounded
# memory, disk or time.
MAGICK_LIMITS = ["-limit", "width", "32KP", "-limit", "height", "32KP",
                 "-limit", "area", "256MP", "-limit", "memory", "1GiB",
                 "-limit", "map", "2GiB", "-limit", "disk", "4GiB",
                 "-limit", "time", "120"]


def image_format(path):
    # Never let ImageMagick guess a file's format: some of its formats (SVG,
    # MVG, MSL, PostScript and others) can read or write local files or run
    # external programs. Accept only JPEG, PNG or WebP, identified by their
    # leading bytes.
    with open(path, "rb") as f:
        head = f.read(12)
    if head.startswith(b"\xff\xd8\xff"):
        return "jpeg"
    if head.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        return "webp"
    raise SystemExit(f"{path}: not a JPEG, PNG or WebP image")


def get_histogram(path, ncolors=16, size=150):
    out = subprocess.run(
        ["magick", *MAGICK_LIMITS, f"{image_format(path)}:{path}",
         "-resize", f"{size}x{size}", "-colors", str(ncolors),
         "+dither", "-depth", "8", "-format", "%c", "histogram:info:-"],
        capture_output=True, text=True, check=True, timeout=180
    ).stdout
    colors = []
    for line in out.splitlines():
        m = re.search(r"^\s*(\d+):.*?(#[0-9A-Fa-f]{6})", line)
        if m:
            colors.append((int(m.group(1)), m.group(2).upper()))
    colors.sort(key=lambda c: -c[0])
    return colors


def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hsl(rgb):
    r, g, b = [c / 255 for c in rgb]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return h * 360, s, l


def hsl_to_hex(h, s, l):
    r, g, b = colorsys.hls_to_rgb((h % 360) / 360, l, s)
    return "#{:02X}{:02X}{:02X}".format(round(r * 255), round(g * 255), round(b * 255))


def clamp(x, lo=0.0, hi=1.0):
    return max(lo, min(hi, x))


def main():
    img_path, out_path = sys.argv[1], sys.argv[2]
    hist = get_histogram(img_path)
    if not hist:
        print("no colors extracted", file=sys.stderr)
        sys.exit(1)

    total = sum(c for c, _ in hist)
    palette = []
    for count, hexcode in hist:
        h, s, l = rgb_to_hsl(hex_to_rgb(hexcode))
        palette.append({"hex": hexcode, "h": h, "s": s, "l": l, "weight": count / total})

    avg_l = sum(p["l"] * p["weight"] for p in palette)
    mode = "dark" if avg_l < 0.5 else "light"

    bg = palette[0]
    bg_l = clamp(bg["l"], 0.08, 0.22) if mode == "dark" else clamp(bg["l"], 0.85, 0.97)
    bg_s = clamp(bg["s"] * 0.6, 0, 0.55)
    background = hsl_to_hex(bg["h"], bg_s, bg_l)

    fg_l = 0.92 if mode == "dark" else 0.15
    foreground = hsl_to_hex(bg["h"], clamp(bg["s"] * 0.15, 0, 0.2), fg_l)

    candidates = sorted(palette, key=lambda p: -p["s"])
    accent_c = next((p for p in candidates if abs(p["l"] - bg_l) > 0.15), candidates[0])
    accent = hsl_to_hex(accent_c["h"], clamp(accent_c["s"], 0.45, 0.9), clamp(accent_c["l"], 0.45, 0.75))

    targets = {"red": 0, "orange": 30, "yellow": 55, "green": 130, "cyan": 185, "blue": 225, "magenta": 300}
    named = {}
    for name, target_h in targets.items():
        best, best_dist = None, 999
        for p in palette:
            if p["s"] < 0.15:
                continue
            dist = min(abs(p["h"] - target_h), 360 - abs(p["h"] - target_h))
            if dist < best_dist:
                best_dist, best = dist, p
        if best and best_dist < 25:
            s = clamp(best["s"], 0.4, 0.85)
            l = clamp(best["l"], 0.45, 0.72) if mode == "dark" else clamp(best["l"], 0.35, 0.55)
            named[name] = hsl_to_hex(target_h, s, l)
        else:
            s = clamp(accent_c["s"], 0.45, 0.8)
            l = 0.62 if mode == "dark" else 0.45
            named[name] = hsl_to_hex(target_h, s, l)

    brown = hsl_to_hex(25, 0.35, 0.42 if mode == "dark" else 0.35)
    sel_delta = 0.12 if mode == "dark" else -0.12
    muted_delta = 0.25 if mode == "dark" else -0.25
    selection = hsl_to_hex(bg["h"], clamp(bg_s * 0.7, 0, 0.3), clamp(bg_l + sel_delta, 0.05, 0.95))
    muted = hsl_to_hex(bg["h"], clamp(bg_s * 0.35, 0, 0.2), clamp(bg_l + muted_delta, 0.05, 0.95))

    dark_background = hsl_to_hex(bg["h"], bg_s, clamp(bg_l - 0.05, 0.01, 0.98))
    darker_background = hsl_to_hex(bg["h"], bg_s, clamp(bg_l - 0.09, 0.01, 0.98))
    lighter_background = hsl_to_hex(bg["h"], bg_s, clamp(bg_l + 0.09, 0.02, 0.98))

    dark_foreground = hsl_to_hex(bg["h"], 0.05, clamp(fg_l - 0.35, 0.1, 0.9))
    light_foreground = hsl_to_hex(bg["h"], 0.05, clamp(fg_l - 0.08, 0.1, 0.95))
    bright_foreground = foreground

    lines = [
        f'mode = "{mode}"', "",
        f'accent = "{accent}"',
        f'selection = "{selection}"',
        f'muted = "{muted}"', "",
        f'background = "{background}"',
        f'dark_background = "{dark_background}"',
        f'darker_background = "{darker_background}"',
        f'lighter_background = "{lighter_background}"', "",
        f'foreground = "{foreground}"',
        f'dark_foreground = "{dark_foreground}"',
        f'light_foreground = "{light_foreground}"',
        f'bright_foreground = "{bright_foreground}"', "",
    ]
    for name in ["red", "yellow", "orange", "green", "cyan", "blue", "magenta"]:
        lines.append(f'{name} = "{named[name]}"')
    lines.append(f'brown = "{brown}"')
    lines.append("")
    for name in ["red", "yellow", "green", "cyan", "blue", "magenta"]:
        lines.append(f'bright_{name} = "{named[name]}"')

    with open(out_path, "w") as f:
        f.write("\n".join(lines) + "\n")

    print(f"mode={mode} background={background} accent={accent}")


if __name__ == "__main__":
    main()
