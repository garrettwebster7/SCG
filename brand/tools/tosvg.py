"""Trace a cutout PNG into a flat 3-colour SVG (charcoal / amber / concrete)."""
import sys, numpy as np, potrace, cv2
from PIL import Image, ImageDraw
src, dst, polyf, ox, oy = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5])
UP = 4
a = np.asarray(Image.open(src)).astype(np.float32)
rgb, al = a[..., :3], a[..., 3] / 255
H, W = al.shape
L = rgb.mean(2); ch = rgb.max(2) - rgb.min(2)
poly = [tuple(map(float, p.split(','))) for p in open(polyf).read().split()]
m = Image.new('L', (W, H)); ImageDraw.Draw(m).polygon([(x - ox, y - oy) for x, y in poly], fill=255)
slab = np.asarray(m) > 0
# light front faces: below the last bright rim row in each column, nothing is a paver top
fa, fb = int(sys.argv[6]) - ox, int(sys.argv[7]) - ox
face = np.zeros_like(slab)
for x in range(fa, fb + 1):
    ys = np.nonzero(slab[:, x] & (L[:, x] > 222))[0]
    if len(ys):
        face[ys[-1] + 1:, x] = True
slab_tops = slab & ~face
amber = ((ch > 60) & (rgb[..., 0] > rgb[..., 2] + 50)).astype(np.float32) * al
tops = (cv2.medianBlur(((slab_tops & (cv2.GaussianBlur(L, (0, 0), 1) > 135)) * 255).astype(np.uint8), 7) > 127).astype(np.float32) * al

def layer(mask, thresh=0.5):
    big = cv2.resize(mask, (W * UP, H * UP), interpolation=cv2.INTER_CUBIC)
    big = cv2.GaussianBlur(big, (0, 0), UP * 0.6)
    bm = potrace.Bitmap(~(big > thresh))
    plist = bm.trace(turdsize=8 * UP, alphamax=1.0, opticurve=True, opttolerance=0.2)
    d = []
    for c in plist:
        s = c.start_point; d.append(f'M{s.x / UP:.2f},{s.y / UP:.2f}')
        for seg in c.segments:
            if seg.is_corner:
                d.append(f'L{seg.c.x / UP:.2f},{seg.c.y / UP:.2f}L{seg.end_point.x / UP:.2f},{seg.end_point.y / UP:.2f}')
            else:
                d.append(f'C{seg.c1.x / UP:.2f},{seg.c1.y / UP:.2f} {seg.c2.x / UP:.2f},{seg.c2.y / UP:.2f} {seg.end_point.x / UP:.2f},{seg.end_point.y / UP:.2f}')
        d.append('Z')
    return ''.join(d)

amber_d = layer(cv2.dilate(amber, np.ones((2, 2))))  # tuck under charcoal edge, no gaps
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
<title>Springfield Concrete Group</title>
<path fill="#2B2F33" fill-rule="evenodd" d="{layer(al)}"/>
<path fill="#D9922B" fill-rule="evenodd" d="{amber_d}"/>
<path fill="#D9D9D3" fill-rule="evenodd" d="{layer(tops)}"/>
</svg>
'''
open(dst, 'w').write(svg)
print(dst, len(svg) // 1024, 'KB')
