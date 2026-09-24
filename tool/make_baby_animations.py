"""Builds the baby's speaking and idle animations from the still.

    python3 tool/make_baby_animations.py

Reads assets/allobaby/AlloMombabySquare.png and writes two animated WebPs
next to it, on the same canvas as the still so swapping between them never
shifts the baby:

  baby_speaking.webp  the mouth opens and closes in a speech rhythm, the head
                      sways and the hands bob in turn
  baby_idle.webp      breathing, a slow head tilt, the hands lifting with
                      each breath, and a blink

The mouth and eyes are redrawn from the still's own pixels. The head and hands
are moved with a smooth warp rather than cut out: the arms have no outline
against the chest, so a cut-out would leave a seam, while a warp only stretches
the skin around them a little, the way a puppet rig would.

WebP rather than GIF: GIF transparency is on/off per pixel, which leaves a
jagged fringe on the soft outline; WebP keeps the full alpha.

Re-run it whenever the still changes. The mouth and eye boxes below are in the
still's own pixels, so a redrawn baby needs them checked.
"""

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets/allobaby/AlloMombabySquare.png'
OUT_DIR = ROOT / 'assets/allobaby'

SKIN = (254, 215, 197)
MOUTH_BOX = (800, 555, 975, 675)  # x0, y0, x1, y1
EYE_BOXES = [(640, 420, 800, 565), (965, 400, 1125, 550)]
LID_COLOR = (74, 44, 38)

# In the still's pixels. The head turns about the neck; each fist bobs about
# its own centre, taking the forearm and a little of the chest with it.
NECK = (885, 745)
HEAD_FADE = (690, 780)  # fully turning above the first y, still below the second
FISTS = [(790, 820), (995, 820)]
FIST_REACH = 70  # how far around a fist the lift spreads (Gaussian sigma)
FEET_Y = 1130  # where the breathing stretch is anchored
OUTPUT_SCALE = 0.5
FPS = 14


def feature_mask(img, box, threshold):
    """The largest non-skin blob inside [box], holes filled, as a full-size
    boolean mask."""
    arr = np.asarray(img).astype(int)
    x0, y0, x1, y1 = box
    sub = arr[y0:y1, x0:x1]
    dist = np.sqrt(((sub[..., :3] - np.array(SKIN)) ** 2).sum(-1))
    blob = (dist > threshold) & (sub[..., 3] > 200)
    labels, n = ndimage.label(blob)
    if n == 0:
        raise SystemExit(f'nothing found in {box}')
    sizes = ndimage.sum(blob, labels, range(1, n + 1))
    keep = labels == (int(np.argmax(sizes)) + 1)
    keep = ndimage.binary_fill_holes(ndimage.binary_closing(keep, iterations=3))
    full = np.zeros(arr.shape[:2], bool)
    full[y0:y1, x0:x1] = keep
    return full


def soft(mask, grow, blur):
    m = ndimage.binary_dilation(mask, iterations=grow) if grow else mask
    img = Image.fromarray((m * 255).astype(np.uint8))
    return img.filter(ImageFilter.GaussianBlur(blur)) if blur else img


def paint_skin(canvas, mask_img):
    skin = Image.new('RGBA', canvas.size, SKIN + (255,))
    canvas.paste(skin, (0, 0), mask_img)


def with_mouth(base_no_mouth, sprite, box, openness):
    """Pastes the mouth squashed to [openness] of its height, the upper lip
    held where it is so it reads as the jaw moving."""
    x0, y0, w, h = box
    nh = max(4, int(round(h * openness)))
    nw = int(round(w * (1.0 - (openness - 0.6) * 0.06)))
    part = sprite.resize((nw, nh), Image.LANCZOS)
    frame = base_no_mouth.copy()
    frame.alpha_composite(part, (x0 + (w - nw) // 2, y0))
    return frame


def blink(frame, eye_masks, closed):
    """Lowers a skin-coloured lid over each eye to [closed] (0..1)."""
    if closed <= 0:
        return frame
    frame = frame.copy()
    draw = ImageDraw.Draw(frame)
    for mask in eye_masks:
        ys, xs = np.nonzero(mask)
        top, bottom = ys.min(), ys.max()
        left, right = xs.min(), xs.max()
        edge = top + (bottom - top) * closed
        lid = mask.copy()
        lid[int(edge):, :] = False
        paint_skin(frame, soft(lid, 9, 2.5))
        # The lid's rim: a gentle arc, curving down as the eye shuts.
        sag = (bottom - top) * 0.18 * closed
        pts = []
        for i in range(21):
            t = i / 20
            x = left + 6 + (right - left - 12) * t
            y = edge - sag * 0.2 + sag * math.sin(math.pi * t)
            pts.append((x, y))
        draw.line(pts, fill=LID_COLOR + (255,), width=9, joint='curve')
    return frame


def warp(frame, head_deg=0.0, head_nod=0.0, lifts=(0.0, 0.0), breath=0.0):
    """Bends [frame] with one smooth displacement field: the head turned by
    [head_deg] and dropped by [head_nod] px, each fist raised by its entry in
    [lifts] px, and the whole baby stretched upward from the feet by [breath].

    Distances are in the still's pixels and scaled to the frame, so this runs
    on the downscaled output.
    """
    k = frame.width / STILL_WIDTH
    arr = np.asarray(frame).astype(np.float32)
    h, w = arr.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)

    # Backward mapping: for each output pixel, where in [frame] it comes from.
    src_x = xx.copy()
    src_y = yy.copy()

    # Head: rotate about the neck, fading out across the chin.
    y0, y1 = HEAD_FADE[0] * k, HEAD_FADE[1] * k
    t = np.clip((y1 - yy) / (y1 - y0), 0, 1)
    wh = t * t * (3 - 2 * t)
    if head_deg or head_nod:
        th = math.radians(-head_deg)
        cx, cy = NECK[0] * k, NECK[1] * k
        dx, dy = xx - cx, yy - cy
        rx = cx + dx * math.cos(th) - dy * math.sin(th)
        ry = cy + dx * math.sin(th) + dy * math.cos(th) - head_nod * k
        src_x += (rx - xx) * wh
        src_y += (ry - yy) * wh

    # Fists: a lift that falls off smoothly around each one.
    for (fx, fy), lift in zip(FISTS, lifts):
        if not lift:
            continue
        sigma = FIST_REACH * k
        g = np.exp(-(((xx - fx * k) ** 2) + ((yy - fy * k) ** 2)) / (2 * sigma**2))
        src_y += lift * k * g

    # Breathing: stretch upward from the feet.
    if breath:
        feet = FEET_Y * k
        src_y += (feet - yy) * (breath / (1 + breath))

    out = np.empty_like(arr)
    for c in range(4):
        out[..., c] = ndimage.map_coordinates(
            arr[..., c], [src_y, src_x], order=1, mode='constant', cval=0
        )
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), 'RGBA')


def shrink(frame):
    size = (int(frame.width * OUTPUT_SCALE), int(frame.height * OUTPUT_SCALE))
    return frame.resize(size, Image.LANCZOS)


def save(frames, name):
    path = OUT_DIR / name
    frames[0].save(
        path,
        save_all=True,
        append_images=frames[1:],
        duration=int(1000 / FPS),
        loop=0,
        quality=88,
        method=6,
        lossless=False,
    )
    print(f'{path.relative_to(ROOT)}: {len(frames)} frames, '
          f'{path.stat().st_size // 1024} KB')


STILL_WIDTH = 1


def main():
    global STILL_WIDTH
    still = Image.open(SRC).convert('RGBA')
    STILL_WIDTH = still.width

    mouth = feature_mask(still, MOUTH_BOX, 45)
    ys, xs = np.nonzero(mouth)
    mbox = (xs.min(), ys.min(), xs.max() - xs.min() + 1, ys.max() - ys.min() + 1)
    sprite = Image.new('RGBA', still.size, (0, 0, 0, 0))
    sprite.paste(still, (0, 0), soft(mouth, 2, 1.2))
    sprite = sprite.crop((mbox[0], mbox[1], mbox[0] + mbox[2], mbox[1] + mbox[3]))

    no_mouth = still.copy()
    paint_skin(no_mouth, soft(mouth, 6, 3))

    eyes = [feature_mask(still, box, 60) for box in EYE_BOXES]

    # Speaking: syllables of different sizes, never fully shut, a blink
    # partway through so she is not staring while she talks.
    pattern = [0.35, 0.7, 1.0, 0.8, 0.45, 0.3, 0.6, 0.95, 1.05, 0.7,
               0.4, 0.55, 0.85, 0.6, 0.3, 0.5, 0.9, 1.0, 0.75, 0.45,
               0.3, 0.65, 0.9, 0.55, 0.35, 0.3]
    blink_at = {14: 0.5, 15: 1.0, 16: 0.5}
    # The head sways once a loop and nods twice; the hands bob in turn, as if
    # she is talking with them.
    speaking = []
    n = len(pattern)
    for i, openness in enumerate(pattern):
        phase = 2 * math.pi * i / n
        frame = with_mouth(no_mouth, sprite, mbox, openness)
        frame = blink(frame, eyes, blink_at.get(i, 0))
        frame = warp(
            shrink(frame),
            head_deg=3.0 * math.sin(phase),
            head_nod=5.0 * (0.5 - 0.5 * math.cos(2 * phase)),
            lifts=(
                16.0 * (0.5 - 0.5 * math.cos(2 * phase)),
                16.0 * (0.5 - 0.5 * math.cos(2 * phase + math.pi)),
            ),
            breath=0.006 * math.sin(phase),
        )
        speaking.append(frame)
    save(speaking, 'baby_speaking.webp')

    # Idle: breathing over three seconds, one blink near the end.
    count = FPS * 3
    idle_blink = {count - 8: 0.5, count - 7: 1.0, count - 6: 1.0, count - 5: 0.5}
    idle = []
    # The head tilts slowly one way and back; both hands rise with the breath.
    for i in range(count):
        phase = 2 * math.pi * i / count
        breath = 0.5 - 0.5 * math.cos(phase)
        frame = blink(still, eyes, idle_blink.get(i, 0))
        frame = warp(
            shrink(frame),
            head_deg=2.5 * math.sin(phase),
            lifts=(10.0 * breath, 10.0 * breath),
            breath=0.01 * breath,
        )
        idle.append(frame)
    save(idle, 'baby_idle.webp')


if __name__ == '__main__':
    main()
