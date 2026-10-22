"""Remove a baked-in fake checkerboard from a logo and export a clean transparent PNG.

usage: cutout.py in out "x,y x,y ..."   (polyline = back edge of the slab top surface)
"""
import sys, json
import numpy as np, cv2
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

src, dst, poly = sys.argv[1], sys.argv[2], sys.argv[3]
poly = [tuple(map(float, p.split(','))) for p in poly.split()]
a = np.asarray(Image.open(src).convert('RGB')).astype(np.float32)
H, W, _ = a.shape
L = a.mean(2)
chroma = a.max(2) - a.min(2)
std = np.sqrt(np.maximum(cv2.blur(L * L, (5, 5)) - cv2.blur(L, (5, 5)) ** 2, 0))

# --- protected slab silhouette. Polygon given clockwise starting with the back edge (first
# NTOP points). The back edge is the only place light logo meets light checker, so it is drawn
# exactly (anti-aliased); everywhere else the polygon is shrunk and normal matting takes over.
NTOP = int(sys.argv[4]) if len(sys.argv) > 4 else 4
S = 8
def render(pts):
    m = Image.new('L', (W * S, H * S), 0)
    ImageDraw.Draw(m).polygon([(x * S, y * S) for x, y in pts], fill=255)
    return np.asarray(m.resize((W, H), Image.BOX)).astype(np.float32) / 255
cover = render(poly)
inside = cover > 0.5
shrunk = ndi.binary_erosion(inside, iterations=3)
top = poly[:NTOP]
near_top = np.zeros((H, W), bool)
for (xa, ya), (xb, yb) in zip(top, top[1:]):
    for x in range(int(xa), int(xb) + 1):
        y = ya + (yb - ya) * (x - xa) / max(xb - xa, 1)
        near_top[int(y) - 1:int(y) + 6, x] = True
protect = shrunk | (near_top & (cover > 0))
protect_alpha = np.where(near_top, cover, 1.0)

# --- background classification
g = np.median(L[(chroma < 10) & (L > 180) & (L < 230)])  # the checker gray
bgish = (chroma < 16) & ((L >= 230) | ((np.abs(L - g) < 14) & (std < 6)))
bgish &= ~protect
lab, n = ndi.label(bgish)
border = set(np.unique(np.r_[lab[0], lab[-1], lab[:, 0], lab[:, -1]])) - {0}
sizes = ndi.sum(np.ones_like(L), lab, range(1, n + 1))
bg = np.zeros((H, W), bool)
for i in range(1, n + 1):
    if i in border or sizes[i - 1] >= 8:  # outside + letter counters
        bg |= lab == i
# grow into light neutral pixels (checker seams, compression mush, stray white streaks)
cand = (((chroma < 22) & (L >= 170)) | ((chroma < 70) & (L >= 205))) & ~protect
bg = ndi.binary_propagation(bg, mask=bg | cand)
# enclosed light pockets (letter counters with colour bleed) are background too
plab, pn = ndi.label(cand & ~bg)
if pn:
    idx = range(1, pn + 1)
    psz = ndi.sum(np.ones_like(L), plab, idx)
    pL = ndi.mean(L, plab, idx)
    for i, (sz, ml) in enumerate(zip(psz, pL), 1):
        if sz >= 2 and ml >= 205:
            bg |= plab == i
# drop tiny opaque specks (jpeg/webp noise in the background)
fg = ~bg
flab, fn = ndi.label(fg)
fs = ndi.sum(np.ones_like(L), flab, range(1, fn + 1))
for i in range(1, fn + 1):
    if fs[i - 1] < 40:
        fg[flab == i] = False
bg = ~fg

# --- edge unmixing: alpha from projecting onto (nearest fg core colour - local bg colour)
core = ndi.binary_erosion(fg, iterations=2) | protect
pure_bg = ndi.binary_erosion(bg, iterations=2)
_, (by, bx) = ndi.distance_transform_edt(~pure_bg, return_indices=True)
_, (fy, fx) = ndi.distance_transform_edt(~core, return_indices=True)
B = a[by, bx]
F = a[fy, fx]
d = F - B
den = (d * d).sum(2)
al = ((a - B) * d).sum(2) / np.maximum(den, 1)
al = np.clip(al, 0, 1)
band = (ndi.binary_dilation(fg, iterations=2) & ~core) & (den > 900)
alpha = fg.astype(np.float32)
alpha[band] = al[band]
checker_like = ((chroma < 16) & (L >= g - 10)) | ((chroma < 45) & (L >= 225))
alpha[band & bg & checker_like] = 0
alpha[protect] = protect_alpha[protect]
rgb = a.copy()
# neutralise the stray green tint (AI artefact) - the palette has no green in the mark
gr = (a[..., 1] > a[..., 0] + 6) & (a[..., 1] > a[..., 2] + 2)
lum = a @ np.array([0.299, 0.587, 0.114], np.float32)
rgb[gr] = np.stack([lum[gr] * 0.96, lum[gr], lum[gr] * 1.06], -1)  # cool charcoal like the letters
rgb[band] = rgb[fy, fx][band]  # decontaminated colour: no white/grey halo
alpha = np.clip(alpha, 0, 1)
alpha[alpha < 0.03] = 0
alpha[(L >= 222) & (chroma < 60) & ~protect] = 0  # nothing in the lettering is near-white
olab, on = ndi.label(alpha > 0)
osz = ndi.sum(np.ones_like(L), olab, range(1, on + 1))
alpha[np.isin(olab, 1 + np.nonzero(osz < 12)[0])] = 0

out = np.dstack([rgb, alpha * 255]).round().astype(np.uint8)
im = Image.fromarray(out, 'RGBA')
bbox = im.getbbox()
im = im.crop(bbox)
im.save(dst, optimize=True)
print(json.dumps({'bbox': bbox, 'size': im.size, 'gray': float(g)}))
