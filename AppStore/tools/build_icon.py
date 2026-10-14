"""Render the neon app icon (1024x1024, no alpha) with headless Chrome."""
import os
import subprocess
import sys

from PIL import Image

OUT = sys.argv[1]  # destination PNG
WORK = os.path.join(os.path.dirname(os.path.abspath(OUT)), ".icon-build")
os.makedirs(WORK, exist_ok=True)
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

GREEN, RED, CYAN, VIOLET = "#29ff8f", "#ff385c", "#3de8ff", "#8c3dff"
PIPS = {
    4: [(.27, .27), (.73, .27), (.27, .73), (.73, .73)],
    5: [(.27, .27), (.73, .27), (.5, .5), (.27, .73), (.73, .73)],
    6: [(.27, .25), (.27, .5), (.27, .75), (.73, .25), (.73, .5), (.73, .75)],
}


def die(value, size, cx, cy, tint, rotate):
    pips = "".join(f'<i style="left:{x*100}%;top:{y*100}%"></i>' for x, y in PIPS[value])
    return (f'<div class="die" style="--s:{size}px;--t:{tint};left:{cx - size/2}px;top:{cy - size/2}px;'
            f'transform:rotate({rotate}deg)">{pips}</div>')


grid = []
w, h = 1024, 430
for i in range(-10, 11):
    grid.append(f'<line x1="{w/2}" y1="0" x2="{w/2 + i*w/4}" y2="{h}"/>')
for i in range(1, 10):
    y = h * (i / 9) ** 2
    grid.append(f'<line x1="0" y1="{y}" x2="{w}" y2="{y}"/>')

html = f"""<!doctype html><html><head><meta charset="utf-8"><style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
html, body {{ width: 1024px; height: 1024px; overflow: hidden; }}
body {{ position: relative; background: radial-gradient(120% 90% at 30% 15%, #16245a 0%, #0b1030 45%, #05070f 100%); }}
.glow {{ position: absolute; border-radius: 50%; }}
.g1 {{ width: 720px; height: 720px; left: -200px; top: -260px; background: {CYAN}; opacity: .28; filter: blur(150px); }}
.g2 {{ width: 760px; height: 760px; right: -280px; bottom: -300px; background: {VIOLET}; opacity: .5; filter: blur(160px); }}
.g3 {{ width: 520px; height: 300px; left: 252px; top: 600px; background: {GREEN}; opacity: .22; filter: blur(110px); }}
svg {{ position: absolute; left: 0; bottom: 0; width: 1024px; height: {h}px;
  -webkit-mask-image: linear-gradient(transparent, #000 70%); }}
.die {{ position: absolute; width: var(--s); height: var(--s); border-radius: 24%;
  border: calc(var(--s) * .035) solid var(--t);
  background: linear-gradient(135deg, color-mix(in srgb, var(--t) 42%, #070a16), #070a16 78%);
  box-shadow: 0 0 calc(var(--s) * .22) color-mix(in srgb, var(--t) 75%, transparent),
              0 0 calc(var(--s) * .06) var(--t),
              inset 0 0 calc(var(--s) * .14) color-mix(in srgb, var(--t) 35%, transparent),
              0 calc(var(--s) * .12) calc(var(--s) * .25) rgba(0,0,0,.55); }}
.die i {{ position: absolute; width: 18%; height: 18%; border-radius: 50%; background: #fff;
  transform: translate(-50%, -50%); box-shadow: 0 0 calc(var(--s) * .07) #fff, 0 0 calc(var(--s) * .14) var(--t); }}
</style></head><body>
<div class="glow g1"></div><div class="glow g2"></div><div class="glow g3"></div>
<svg viewBox="0 0 {w} {h}" preserveAspectRatio="none"><g stroke="{CYAN}" stroke-opacity=".35" stroke-width="2">{''.join(grid)}</g></svg>
{die(6, 360, 330, 395, RED, -16)}
{die(5, 360, 694, 395, RED, 16)}
{die(4, 440, 512, 610, GREEN, 0)}
</body></html>"""

src = os.path.join(WORK, "icon.html")
with open(src, "w") as f:
    f.write(html)
tmp = os.path.join(WORK, "icon.png")
subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                "--window-size=1024,1024", f"--screenshot={tmp}", "file://" + src], check=True, capture_output=True)
im = Image.open(tmp).convert("RGB")  # App Store icons must not have alpha
assert im.size == (1024, 1024), im.size
im.save(OUT, optimize=True)
print("wrote", OUT)
