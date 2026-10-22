"""Build brand logo variants from the clean cutouts."""
import sys, numpy as np
from PIL import Image, ImageDraw
out = sys.argv[1]

def slab_mask(size, poly, off):
    m = Image.new('L', size, 0)
    ImageDraw.Draw(m).polygon([(x - off[0], y - off[1]) for x, y in poly], fill=255)
    return np.asarray(m) > 0

def load_poly(f):
    return [tuple(map(float, p.split(','))) for p in open(f).read().split()]

def on_dark(im, slab):
    a = np.asarray(im).astype(np.float32)
    rgb, al = a[..., :3], a[..., 3]
    L = rgb.mean(2); ch = rgb.max(2) - rgb.min(2)
    letters = (ch < 40) & ~slab
    # charcoal lettering -> light concrete, keeping texture order (outline stays darker than fill)
    new = 150 + L * 0.85
    rgb[letters] = np.stack([new * 0.97, new * 0.98, new], -1)[letters]
    return Image.fromarray(np.dstack([rgb.clip(0, 255), al]).astype(np.uint8), 'RGBA')

def one_color(im, color, slab):
    a = np.asarray(im).copy()
    L = a[..., :3].astype(np.float32).mean(2)
    # flat slab: keep the light paver tops, cut away grooves and side faces
    a[..., 3] = np.where(slab, np.clip((L - 120) / 40, 0, 1) * a[..., 3], a[..., 3]).astype(np.uint8)
    a[..., :3] = color
    return Image.fromarray(a, 'RGBA')

def pad_square(im, size, pad=0.08):
    s = max(im.size) / (1 - 2 * pad)
    c = Image.new('RGBA', (int(s), int(s)), (0, 0, 0, 0))
    c.alpha_composite(im, ((c.width - im.width) // 2, (c.height - im.height) // 2))
    return c.resize((size, size), Image.LANCZOS)

CHAR, WHITE = (43, 47, 51), (255, 255, 255)
st = Image.open('logo/stacked.png'); hz = Image.open('logo/horizontal.png')
st_slab = slab_mask(st.size, load_poly('poly1.txt'), (118, 230))
hz_slab = slab_mask(hz.size, load_poly('poly2.txt'), (203, 297))
# monogram = SCG + slab, from the larger stacked source (slab bottom is ~y527 in source -> 297 here)
mono = st.crop((0, 0, st.width, 300)); mono = mono.crop(mono.getbbox())
mono_slab = st_slab[:300][:mono.height, :mono.width] if False else None
files = {
    'scg-logo-stacked.png': st,
    'scg-logo-stacked-on-dark.png': on_dark(st, st_slab),
    'scg-logo-horizontal.png': hz,
    'scg-logo-horizontal-on-dark.png': on_dark(hz, hz_slab),
    'scg-monogram.png': mono,
    'scg-monogram-on-dark.png': on_dark(st, st_slab).crop((0, 0, st.width, 300)).crop(mono.getbbox() and (0, 0, 0, 0) or None) if False else None,
    'scg-logo-stacked-charcoal.png': one_color(st, CHAR, st_slab),
    'scg-logo-stacked-white.png': one_color(st, WHITE, st_slab),
    'scg-logo-horizontal-charcoal.png': one_color(hz, CHAR, hz_slab),
    'scg-logo-horizontal-white.png': one_color(hz, WHITE, hz_slab),
    
}
od = on_dark(st, st_slab).crop((0, 0, st.width, 300))
files['scg-monogram-on-dark.png'] = od.crop(od.getbbox())
mw = one_color(st, WHITE, st_slab).crop((0, 0, st.width, 300)); files['scg-monogram-white.png'] = mw.crop(mw.getbbox())
for name, im in files.items():
    if im is not None:
        im.save(f'{out}/{name}', optimize=True)
pad_square(mono, 512).save(f'{out}/scg-icon-512.png', optimize=True)
pad_square(mono, 180).save(f'{out}/apple-touch-icon.png', optimize=True)
pad_square(mono, 32, 0.02).save(f'{out}/favicon-32.png', optimize=True)
pad_square(mono, 48, 0.02).save(f'{out}/favicon.ico', sizes=[(16, 16), (32, 32), (48, 48)])
print('ok')
