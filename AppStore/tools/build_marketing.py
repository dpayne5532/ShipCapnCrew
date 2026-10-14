"""Generate App Store screenshot / header HTML and render with headless Chrome."""
import os
import subprocess
import sys

from PIL import Image

S = sys.argv[1]          # scratchpad
OUT = sys.argv[2]        # repo AppStore dir
RAW = os.path.join(S, "raw")
HTML = os.path.join(S, "html")
os.makedirs(HTML, exist_ok=True)
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

GREEN, RED, CYAN, VIOLET = "#29ff8f", "#ff385c", "#3de8ff", "#8c3dff"

PIPS = {
    1: [(.5, .5)],
    2: [(.27, .27), (.73, .73)],
    3: [(.27, .27), (.5, .5), (.73, .73)],
    4: [(.27, .27), (.73, .27), (.27, .73), (.73, .73)],
    5: [(.27, .27), (.73, .27), (.5, .5), (.27, .73), (.73, .73)],
    6: [(.27, .25), (.27, .5), (.27, .75), (.73, .25), (.73, .5), (.73, .75)],
}

BASE_CSS = f"""
@font-face {{ font-family: Rounded; src: url(file:///System/Library/Fonts/SFNSRounded.ttf); font-weight: 100 1000; }}
@font-face {{ font-family: Mono; src: url(file:///System/Library/Fonts/SFNSMono.ttf); font-weight: 100 1000; }}
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
html, body {{ width: var(--w); height: var(--h); overflow: hidden; background: #05070f; }}
body {{ position: relative; font-family: Rounded, system-ui; color: white; }}
.bg {{ position: absolute; inset: 0; background: linear-gradient(#0d1229, #05070f); overflow: hidden; }}
.glow {{ position: absolute; border-radius: 50%; filter: blur(var(--blur)); }}
.grid {{ position: absolute; left: 0; bottom: 0; width: 100%; height: 50%;
  -webkit-mask-image: linear-gradient(transparent, black); }}
.die {{ position: absolute; border-radius: 24%; border: calc(var(--s) * .018) solid var(--t);
  width: var(--s); height: var(--s);
  background: linear-gradient(135deg, color-mix(in srgb, var(--t) 38%, transparent), rgba(5,8,15,.95) 90%);
  box-shadow: 0 0 calc(var(--s) * .18) color-mix(in srgb, var(--t) 60%, transparent),
              inset 0 0 calc(var(--s) * .1) color-mix(in srgb, var(--t) 25%, transparent); }}
.pip {{ position: absolute; width: 17%; height: 17%; border-radius: 50%; background: white;
  transform: translate(-50%, -50%); box-shadow: 0 0 calc(var(--s) * .08) var(--t); }}
.mono {{ font-family: Mono, ui-monospace, monospace; font-weight: 700; text-transform: uppercase; }}
.g {{ background: linear-gradient(90deg, {GREEN}, {CYAN}); -webkit-background-clip: text; color: transparent; }}
"""


def grid_svg(w, h, cols=12, rows=16, opacity=.24):
    lines = []
    vx, vy = w / 2, 0
    for i in range(-cols, cols + 1):
        lines.append(f'<line x1="{vx}" y1="{vy}" x2="{w/2 + i*w/5}" y2="{h}"/>')
    for i in range(1, rows + 1):
        y = h * (i / rows) ** 2
        lines.append(f'<line x1="0" y1="{y}" x2="{w}" y2="{y}"/>')
    return (f'<svg class="grid" viewBox="0 0 {w} {h}" preserveAspectRatio="none">'
            f'<g stroke="{CYAN}" stroke-opacity="{opacity}" stroke-width="{max(1, w/1500)}">'
            + "".join(lines) + "</g></svg>")


def die(value, size, x, y, tint, rotate=0, opacity=1, blur=0):
    pips = "".join(f'<div class="pip" style="left:{px*100}%;top:{py*100}%"></div>'
                   for px, py in PIPS[value])
    return (f'<div class="die" style="--s:{size}px;--t:{tint};left:{x}px;top:{y}px;'
            f'transform:rotate({rotate}deg);opacity:{opacity};filter:blur({blur}px)">{pips}</div>')


def glow(color, size, x, y, alpha, blur):
    return (f'<div class="glow" style="--blur:{blur}px;width:{size}px;height:{size}px;'
            f'left:{x}px;top:{y}px;background:color-mix(in srgb, {color} {alpha}%, transparent)"></div>')


def page(w, h, body, extra_css=""):
    return (f"<!doctype html><html style='--w:{w}px;--h:{h}px'><head><meta charset='utf-8'>"
            f"<style>{BASE_CSS}{extra_css}</style></head><body>{body}</body></html>")


def render(name, html, w, h, dest):
    path = os.path.join(HTML, name + ".html")
    with open(path, "w") as f:
        f.write(html)
    tmp = os.path.join(HTML, name + ".png")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--allow-file-access-from-files", "--force-device-scale-factor=1",
                    "--default-background-color=05070fff",
                    f"--window-size={w},{h}", f"--screenshot={tmp}", "file://" + path],
                   check=True, capture_output=True)
    im = Image.open(tmp).convert("RGB")  # App Store rejects alpha channels
    assert im.size == (w, h), (name, im.size)
    im.save(dest, optimize=True)
    print("wrote", dest, im.size)


# ---------------------------------------------------------------- screenshots
SHOTS = [
    ("01-roll", "1-hero", "The classic dice game", "Roll. Hold.<br><span class=g>Find your cargo.</span>"),
    ("02-hold", "2-hunt", "Tap to hold", "Lock in your<br><span class=g>6, 5 and 4</span>"),
    ("03-cargo", "3-turnover", "Auto scoring", "Your cargo,<br><span class=g>counted for you</span>"),
    ("04-free-roll", "6-free", "Free Roll", "No limits.<br><span class=g>Just keep rollin'</span>"),
    ("05-classic", "5-classic", "Classic Mode", "The original look,<br><span class=g>one tap away</span>"),
    ("06-settings", "4-settings", "Settings", "Play it<br><span class=g>your way</span>"),
]

# (output folder, raw capture folder, canvas size == simulator size, Dynamic Island box in raw px)
DEVICES = [
    ("6.3in-1206x2622", "raw63", (1206, 2622), (464, 42, 278, 110)),  # iPhone with Dynamic Island, medium
    ("6.9in-1320x2868", "raw", (1320, 2868), (521, 42, 278, 110)),    # iPhone with Dynamic Island, large
]

for folder, raw_dir, (SW, SH), (ix, iy, iw, ih) in DEVICES:
    k = SW / 1320  # layout was designed on the 1320-wide canvas
    screen_w = round(1000 * k)
    scale = screen_w / SW
    screen_h = round(SH * scale)
    bezel = round(22 * k)
    radius = round(190 * scale)
    css = f"""
.copy {{ position: absolute; top: {170*k}px; left: 0; right: 0; text-align: center; }}
.kicker {{ font-size: {40*k}px; letter-spacing: {12*k}px; color: {CYAN}; margin-bottom: {34*k}px; }}
h1 {{ font-size: {118*k}px; line-height: 1.04; font-weight: 850; letter-spacing: -1px; }}
.phone {{ position: absolute; left: {(SW - screen_w) / 2 - bezel}px; top: {610*k}px;
  width: {screen_w + 2*bezel}px; height: {screen_h + 2*bezel}px; padding: {bezel}px;
  border-radius: {radius + bezel}px; background: linear-gradient(145deg, #3a4157, #0b0e18 40%, #1b2030);
  box-shadow: 0 0 0 {3*k}px rgba(61,232,255,.35), 0 0 {120*k}px rgba(61,232,255,.28), 0 {60*k}px {120*k}px rgba(0,0,0,.6); }}
.phone img {{ width: {screen_w}px; height: {screen_h}px; border-radius: {radius}px; display: block; }}
.island {{ position: absolute; left: {bezel + ix*scale}px; top: {bezel + iy*scale}px;
  width: {iw*scale}px; height: {ih*scale}px; border-radius: 999px; background: #000; }}
"""
    dest_dir = os.path.join(OUT, "screenshots", folder)
    os.makedirs(dest_dir, exist_ok=True)
    for out_name, raw, kicker, headline in SHOTS:
        body = ('<div class="bg">'
                + glow(CYAN, 1100*k, -420*k, -300*k, 30, 220*k)
                + glow(VIOLET, 1200*k, 500*k, 1900*k, 32, 240*k)
                + grid_svg(SW, SH // 2) + "</div>"
                + f'<div class="copy"><div class="kicker mono">{kicker}</div><h1>{headline}</h1></div>'
                + f'<div class="phone"><img src="file://{S}/{raw_dir}/{raw}.png"><div class="island"></div></div>')
        render(f"{folder}-{out_name}", page(SW, SH, body, css), SW, SH,
               os.path.join(dest_dir, out_name + ".png"))

# ---------------------------------------------------------------- header 21:9
HW, HH = 3840, 1646
SAFE_W, SAFE_H = 1646, 661
sx, sy = (HW - SAFE_W) / 2, (HH - SAFE_H) / 2
HEADER_CSS = f"""
.label {{ position: absolute; font-size: 56px; letter-spacing: 16px; text-align: center; color: {CYAN};
  text-shadow: 0 0 30px rgba(61,232,255,.7); transform: translateX(-50%); }}
"""
size, gap = 400, 123
row_w = 3 * size + 2 * gap
x0, y0 = sx + (SAFE_W - row_w) / 2, sy + 40
body = ['<div class="bg">',
        glow(CYAN, 1800, 600, -900, 30, 300),
        glow(VIOLET, 1900, 1500, 700, 34, 320),
        glow(GREEN, 1200, 1320, 300, 14, 260),
        grid_svg(HW, HH // 2, cols=16, rows=14),
        "</div>"]
# ambient dice outside the safe area
for v, s, x, y, t, r, o, b in [
    (2, 240, 260, 260, GREEN, -18, .55, 3), (3, 170, 720, 1080, RED, 22, .45, 5),
    (1, 130, 1060, 180, GREEN, 12, .35, 7), (6, 260, 3320, 220, RED, 16, .55, 3),
    (4, 180, 2960, 1100, GREEN, -24, .45, 5), (5, 130, 2700, 150, GREEN, -10, .35, 7),
]:
    body.append(die(v, s, x, y, t, r, o, b))
for i, (v, label, tint) in enumerate([(6, "SHIP", RED), (5, "CAP'N", RED), (4, "CREW", GREEN)]):
    x = x0 + i * (size + gap)
    body.append(die(v, size, x, y0, tint, rotate=(-6, 0, 6)[i]))
    body.append(f'<div class="label mono" style="left:{x + size/2 + 8}px;top:{y0 + size + 70}px">{label}</div>')
render("header", page(HW, HH, "".join(body), HEADER_CSS), HW, HH,
       os.path.join(OUT, "header-3840x1646.png"))

# ---------------------------------------------------------------- search results 3:2
RW, RH = 3840, 2560
SAFE_W, SAFE_H = 2168, 1030
sx, sy = (RW - SAFE_W) / 2, (RH - SAFE_H) / 2
SEARCH_CSS = f"""
.title {{ position: absolute; left: 0; right: 0; text-align: center; font-weight: 850; font-size: 230px;
  letter-spacing: -3px; top: {sy - 10}px; }}
.tag {{ position: absolute; left: 0; right: 0; text-align: center; font-size: 60px; letter-spacing: 18px;
  color: {CYAN}; top: {sy + SAFE_H - 90}px; }}
"""
size, gap = 380, 120
row_w = 3 * size + 2 * gap
x0, y0 = (RW - row_w) / 2, sy + 330
body = ['<div class="bg">',
        glow(CYAN, 2200, 300, -1200, 30, 340),
        glow(VIOLET, 2400, 1700, 1200, 34, 360),
        grid_svg(RW, RH // 2, cols=16, rows=16),
        "</div>",
        '<div class="title"><span class="g">Ship Cap\'n Crew</span></div>']
for v, s, x, y, t, r, o, b in [
    (2, 300, 340, 420, GREEN, -18, .5, 4), (3, 220, 520, 1800, RED, 22, .45, 6),
    (6, 320, 3200, 380, RED, 16, .5, 4), (1, 220, 3160, 1850, GREEN, -24, .45, 6),
]:
    body.append(die(v, s, x, y, t, r, o, b))
for i, (v, tint) in enumerate([(6, RED), (5, RED), (4, GREEN)]):
    body.append(die(v, size, x0 + i * (size + gap), y0, tint, rotate=(-6, 0, 6)[i]))
body.append('<div class="tag mono">Roll · Hold · Find your cargo</div>')
render("search", page(RW, RH, "".join(body), SEARCH_CSS), RW, RH,
       os.path.join(OUT, "search-results-3840x2560.png"))
