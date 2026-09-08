from pathlib import Path
import sys
try:
    from PIL import Image
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow", "-q"])
    from PIL import Image

proj = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\vn_portraits")
neutral = proj / "goblin_girl_neutral.png"
teasing = proj / "goblin_girl_teasing.png"


def content_bbox(im: Image.Image, alpha_thresh=8, lum_thresh=12):
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    minx, miny, maxx, maxy = w, h, 0, 0
    found = False
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < alpha_thresh:
                continue
            if r + g + b < lum_thresh and a < 40:
                continue
            found = True
            minx = min(minx, x)
            miny = min(miny, y)
            maxx = max(maxx, x)
            maxy = max(maxy, y)
    if not found:
        return (0, 0, w, h)
    return (minx, miny, maxx + 1, maxy + 1)


def bbox_info(path: Path):
    im = Image.open(path)
    b = content_bbox(im)
    return b, b[3] - b[1], im.size


tb, th, _ = bbox_info(teasing)
nb, nh, _ = bbox_info(neutral)
print("teasing bbox", tb, "h", th)
print("neutral bbox", nb, "h", nh)

im = Image.open(neutral).convert("RGBA")
crop = im.crop(nb)
cw, ch = crop.size
scale = th / max(1, ch)
nw = max(1, int(round(cw * scale)))
nh2 = max(1, int(round(ch * scale)))
if nh2 > int(1920 * 0.92):
    scale = (1920 * 0.92) / ch
    nw = max(1, int(round(cw * scale)))
    nh2 = max(1, int(round(ch * scale)))
resized = crop.resize((nw, nh2), Image.Resampling.LANCZOS)
canvas = Image.new("RGBA", (1080, 1920), (0, 0, 0, 0))
x = (1080 - nw) // 2
y = tb[1]
if y + nh2 > 1920:
    y = max(0, 1920 - nh2)
canvas.paste(resized, (x, y), resized)
bak = proj / "goblin_girl_neutral_oversized.bak.png"
if not bak.exists():
    Image.open(neutral).save(bak)
canvas.save(neutral)
bb2, h2, _ = bbox_info(neutral)
print("fixed neutral bbox", bb2, "h", h2)
