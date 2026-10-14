"""Build the DanCo Worldwide logo set: mark + horizontal/stacked lockups, dark and light, SVG and PNG.

Usage: python build_logo.py <Fredoka variable TTF> <output dir>
Text is converted to outlines, so the SVGs don't depend on the font being installed.
Needs fontTools; PNGs are rendered with headless Chrome (transparent background).
"""
import os
import subprocess
import sys

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

FONT, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

PURPLE_TOP, PURPLE_BOTTOM = "#6C35CC", "#2B0B5E"
ROYAL = "#3E1785"      # wordmark on light backgrounds
LAVENDER = "#D2BCFF"   # "WORLDWIDE" on dark backgrounds
GOLD_EDGE = "#8A5A0B"


def instance(weight):
    font = TTFont(FONT)
    return instancer.instantiateVariableFont(font, {"wght": weight, "wdth": 100})


BOLD, SEMI = instance(700), instance(600)


def text_path(font, text, size, x, baseline, tracking=0.0):
    """Outline `text` as one SVG path. Returns (d, width)."""
    upm = font["head"].unitsPerEm
    scale = size / upm
    cmap, glyphs, hmtx = font.getBestCmap(), font.getGlyphSet(), font["hmtx"]
    pen = SVGPathPen(glyphs)
    cursor = x
    for i, ch in enumerate(text):
        name = cmap[ord(ch)]
        glyphs[name].draw(TransformPen(pen, (scale, 0, 0, -scale, cursor, baseline)))
        cursor += hmtx[name][0] * scale
        if i < len(text) - 1:
            cursor += tracking * size
    return pen.getCommands(), cursor - x


GOLD_STOPS = """
  <stop offset="0" stop-color="#FFF6CF"/>
  <stop offset=".22" stop-color="#FFD75E"/>
  <stop offset=".5" stop-color="#E3A626"/>
  <stop offset=".66" stop-color="#FFE493"/>
  <stop offset=".84" stop-color="#D8971C"/>
  <stop offset="1" stop-color="#A86A0C"/>"""


def mark_defs(p):
    """Gradients/filters for the mark; `p` prefixes ids so several marks can share a document."""
    return f"""
<linearGradient id="{p}bg" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="{PURPLE_TOP}"/><stop offset="1" stop-color="{PURPLE_BOTTOM}"/>
</linearGradient>
<radialGradient id="{p}sheen" cx=".28" cy=".18" r=".8">
  <stop offset="0" stop-color="#fff" stop-opacity=".28"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/>
</radialGradient>
<linearGradient id="{p}gold" x1="0" y1="0" x2=".35" y2="1">{GOLD_STOPS}
</linearGradient>
<linearGradient id="{p}shine" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#fff" stop-opacity=".55"/><stop offset=".42" stop-color="#fff" stop-opacity="0"/>
</linearGradient>
<radialGradient id="{p}pip" cx=".36" cy=".32" r=".75">
  <stop offset="0" stop-color="#FFF8DA"/><stop offset=".45" stop-color="#FFD35A"/><stop offset="1" stop-color="#B57812"/>
</radialGradient>
<filter id="{p}lift" x="-20%" y="-20%" width="140%" height="150%">
  <feDropShadow dx="0" dy="7" stdDeviation="8" flood-color="#14032E" flood-opacity=".65"/>
</filter>
<clipPath id="{p}back"><rect x="-300" y="-300" width="600" height="300"/></clipPath>
<clipPath id="{p}front"><rect x="-300" y="0" width="600" height="300"/></clipPath>"""


D_OUTER = ("M150 112H252A144 144 0 0 1 252 400H150A34 34 0 0 1 116 366V146A34 34 0 0 1 150 112Z")
D_COUNTER = ("M208 190H252A66 66 0 0 1 252 322H208A14 14 0 0 1 194 308V204A14 14 0 0 1 208 190Z")
SPARKLE = "M0 -30C4 -8 8 -4 30 0C8 4 4 8 0 30C-4 8 -8 4 -30 0C-8 -4 -4 -8 0 -30Z"


def orbit(p, half):
    return (f'<g transform="translate(256 262) rotate(-17)" clip-path="url(#{p}{half})">'
            f'<ellipse rx="214" ry="62" fill="none" stroke="url(#{p}gold)" stroke-width="20"/>'
            f'<ellipse rx="214" ry="62" fill="none" stroke="{GOLD_EDGE}" stroke-opacity=".35" stroke-width="2"/></g>')


def mark_body(p):
    """The 512x512 mark: purple tile, gold D wrapped in an orbit, a die pip, a sparkle."""
    d = D_OUTER + D_COUNTER
    return f"""
<rect width="512" height="512" rx="116" fill="url(#{p}bg)"/>
<rect width="512" height="512" rx="116" fill="url(#{p}sheen)"/>
<rect x="10" y="10" width="492" height="492" rx="106" fill="none" stroke="url(#{p}gold)" stroke-opacity=".55" stroke-width="5"/>
{orbit(p, "back")}
<g filter="url(#{p}lift)">
  <path d="{d}" fill-rule="evenodd" fill="url(#{p}gold)"/>
  <path d="{d}" fill-rule="evenodd" fill="url(#{p}shine)"/>
  <path d="{d}" fill-rule="evenodd" fill="none" stroke="{GOLD_EDGE}" stroke-opacity=".55" stroke-width="3"/>
  <circle cx="256" cy="256" r="29" fill="url(#{p}pip)"/>
</g>
{orbit(p, "front")}
<path d="{SPARKLE}" transform="translate(404 118)" fill="#FFF6CF"/>
<path d="{SPARKLE}" transform="translate(110 418) scale(.5)" fill="#FFE493" opacity=".85"/>"""


def svg(width, height, defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
            f'width="{width}" height="{height}"><defs>{defs}</defs>{body}</svg>\n')


def word_defs(p, size):
    """Gold for 'DanCo'. The text path is drawn with its baseline at y=0, so the gradient spans cap height above it."""
    return (f'<linearGradient id="{p}wgold" gradientUnits="userSpaceOnUse" x1="0" y1="{-size * .74}" x2="0" y2="{size * .02}">'
            f'{GOLD_STOPS}</linearGradient>')


def wordmark(p, x, top_baseline, size, theme, center_width=None):
    """'DanCo' above tracked 'WORLDWIDE'. Returns (svg, width, bottom)."""
    dan, dan_w = text_path(BOLD, "DanCo", size, 0, 0, tracking=0.01)
    ww_size = size * 0.3
    ww, ww_w = text_path(SEMI, "WORLDWIDE", ww_size, 0, 0, tracking=0.34)
    width = max(dan_w, ww_w)
    dan_x = x + ((width - dan_w) / 2 if center_width else 0)
    ww_x = x + ((width - ww_w) / 2 if center_width else 0)
    ww_baseline = top_baseline + ww_size * 1.75
    if theme == "dark":
        dan_fill, ww_fill, edge = f"url(#{p}wgold)", LAVENDER, f'stroke="{GOLD_EDGE}" stroke-opacity=".5" stroke-width="{size*.012}"'
    else:
        dan_fill, ww_fill, edge = ROYAL, "#B47A10", ""
    body = (f'<path transform="translate({dan_x} {top_baseline})" d="{dan}" fill="{dan_fill}" {edge}/>'
            f'<path transform="translate({ww_x} {ww_baseline})" d="{ww}" fill="{ww_fill}"/>')
    return body, width, ww_baseline


def write(name, content):
    path = os.path.join(OUT, name)
    with open(path, "w") as f:
        f.write(content)
    return path


def render_png(svg_path, png_path, width, height):
    html = svg_path.replace(".svg", ".render.html")
    with open(html, "w") as f:
        f.write(f'<!doctype html><html><body style="margin:0;background:transparent">'
                f'<img src="file://{svg_path}" width="{width}" height="{height}" style="display:block"></body></html>')
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    "--default-background-color=00000000", "--allow-file-access-from-files",
                    f"--window-size={width},{height}", f"--screenshot={png_path}", "file://" + html],
                   check=True, capture_output=True)
    os.remove(html)
    print("wrote", os.path.relpath(png_path, OUT), f"{width}x{height}")


# Mark
mark = svg(512, 512, mark_defs("m"), mark_body("m"))
render_png(write("danco-mark.svg", mark), os.path.join(OUT, "danco-mark-1024.png"), 1024, 1024)

for theme in ("dark", "light"):
    # Horizontal: mark left, words right.
    H = 240
    s = H / 512
    size = 132
    words, ww, bottom = wordmark("h", H + 44, 132, size, theme)
    width = round(H + 44 + ww + 8)
    body = f'<g transform="scale({s})">{mark_body("h")}</g>{words}'
    path = write(f"danco-horizontal-{theme}.svg",
                 svg(width, H, mark_defs("h") + word_defs("h", size), body))
    render_png(path, os.path.join(OUT, f"danco-horizontal-{theme}.png"), width * 2, H * 2)

    # Stacked: mark centered over centered words.
    M = 320
    size = 150
    words, ww, bottom = wordmark("s", 0, M + 40 + size * .72, size, theme, center_width=True)
    width = round(max(M, ww) + 40)
    words_x = (width - ww) / 2
    height = round(bottom + 24)
    body = (f'<g transform="translate({(width - M) / 2} 0) scale({M / 512})">{mark_body("s")}</g>'
            f'<g transform="translate({words_x} 0)">{words}</g>')
    path = write(f"danco-stacked-{theme}.svg",
                 svg(width, height, mark_defs("s") + word_defs("s", size), body))
    render_png(path, os.path.join(OUT, f"danco-stacked-{theme}.png"), width * 2, height * 2)
