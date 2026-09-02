from PIL import Image, ImageDraw, ImageFont
import os
BASE_EMPTY = "baseline/b3-all-herdr-clients-closed.png"
BASE_NOTIF = "baseline/c1-crash-notification.png"
OUT = "mockups"
F = "/usr/share/fonts/truetype/dejavu/"
def font(size, bold=False, mono=False):
    name = "DejaVuSansMono-Bold.ttf" if (mono and bold) else "DejaVuSansMono.ttf" if mono else "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    return ImageFont.truetype(F + name, size)
BG = (26, 27, 38); FG = (169, 177, 214); MUTED = (110, 116, 145); ACCENT = (122, 162, 247); URGENT = (247, 118, 142); OK = (158, 206, 106); BORDER = (54, 58, 82)
BAR_H = 26

def draw_widget(d, x, state, count):
    """Bar widget: a session glyph (three stacked bars) plus a badge. x is the left edge."""
    col = {"urgent": URGENT, "waiting": FG, "muted": MUTED}[state]
    y0 = 7
    for i in range(3):
        d.rounded_rectangle([x, y0 + i*4, x + 12 - i*2, y0 + i*4 + 2], radius=1, fill=col)
    if count:
        d.ellipse([x + 14, 4, x + 30, 20], fill=col)
        d.text((x + 22, 12), str(count), font=font(11, bold=True), fill=BG, anchor="mm")
    return x + (34 if count else 18)

def row(d, x, y, w, name, agent, state, since, branch, owner, kids, lead=False, heuristic=False, state_col=FG):
    fn = font(20, bold=True) if lead else font(15, bold=True)
    fs = font(15) if lead else font(13)
    d.text((x, y), name, font=fn, fill=FG)
    nx = x + d.textlength(name, font=fn) + 12
    d.text((nx, y + (5 if lead else 2)), agent, font=font(12, mono=True), fill=MUTED)
    st = f"{state} · {since}"
    sx = x + w - 16 - d.textlength(st, font=fs)
    d.text((sx, y + (4 if lead else 1)), st, font=fs, fill=state_col)
    if heuristic:
        cx = sx - 14; cy = y + (13 if lead else 9)
        d.ellipse([cx-4, cy-4, cx+4, cy+4], outline=MUTED, width=1)
    meta = f"{branch}   ·   {owner}" + (f"   ·   {kids} child" + ("ren" if kids > 1 else "") if kids else "")
    d.text((x, y + (30 if lead else 22)), meta, font=font(12), fill=MUTED)
    return y + (56 if lead else 46)

def section(d, x, y, w, title):
    d.text((x, y), title.upper(), font=font(11, bold=True), fill=MUTED)
    return y + 20

def panel(im, anchor_x, sessions_hero, rows, notif=None, y0=None):
    d = ImageDraw.Draw(im, "RGBA")
    W = 460; x0 = min(anchor_x - W // 2, im.width - W - 12); y0 = (BAR_H + 8) if y0 is None else y0
    H = 74 + sum(56 if r.get("lead") else 46 for r in rows) + 20 * 3 + 40
    d.rounded_rectangle([x0, y0, x0 + W, y0 + H], radius=8, fill=BG + (245,), outline=BORDER, width=1)
    # hero
    d.text((x0 + 16, y0 + 14), sessions_hero[0], font=font(17, bold=True), fill=sessions_hero[2])
    d.text((x0 + 16, y0 + 40), sessions_hero[1], font=font(12), fill=MUTED)
    y = y0 + 70
    d.line([x0 + 16, y, x0 + W - 16, y], fill=BORDER); y += 12
    cur = None
    for r in rows:
        if r["section"] != cur:
            cur = r["section"]; y = section(d, x0 + 16, y, W - 32, cur)
        y = row(d, x0 + 16, y, W - 32, r["name"], r["agent"], r["state"], r["since"], r["branch"], r["owner"], r.get("kids", 0), r.get("lead", False), r.get("heuristic", False), r.get("col", FG))
    d.text((x0 + 16, y0 + H - 22), "Enter open · s send · x stop · r receipt · Esc close", font=font(11), fill=MUTED)
    return im

def stamp(im, text):
    d = ImageDraw.Draw(im, "RGBA")
    d.rounded_rectangle([12, im.height - 40, 12 + d.textlength(text, font=font(13, bold=True)) + 20, im.height - 12], radius=6, fill=(0, 0, 0, 170))
    d.text((22, im.height - 34), text, font=font(13, bold=True), fill=(255, 210, 120))

# 1. widget at rest: muted glyph, no badge, panel closed
im = Image.open(BASE_EMPTY).convert("RGB"); d = ImageDraw.Draw(im)
draw_widget(d, 1786, "muted", 0)
stamp(im, "PROPOSED · sessions widget at rest, two sessions working · composed over the rig's bar, 2026-09-02")
im.save(f"{OUT}/sessions-panel_proposed_arm-port_2026-09-02_widget-at-rest.png")

# 2. panel open, three sessions across sections
im = Image.open(BASE_EMPTY).convert("RGB"); d = ImageDraw.Draw(im)
wx = draw_widget(d, 1770, "waiting", 1)
rows = [
  {"section": "Needs you", "name": "nav-focus-trap", "agent": "claude", "state": "waiting", "since": "2m", "branch": "session/nav-focus-trap", "owner": "praneet", "lead": True, "col": FG},
  {"section": "Working", "name": "api-refactor", "agent": "codex", "state": "working", "since": "14m", "branch": "session/api-refactor", "owner": "praneet", "kids": 1, "heuristic": True, "col": MUTED},
  {"section": "Done today", "name": "crash bash 15081", "agent": "claude", "state": "done", "since": "11:33", "branch": "no worktree", "owner": "system", "col": OK},
]
panel(im, 1786, ("nav-focus-trap needs you", "1 waiting · 1 working · 1 done today", FG), rows)
stamp(im, "PROPOSED · sessions panel open, one row per section · composed over the rig's bar, 2026-09-02")
im.save(f"{OUT}/sessions-panel_proposed_arm-port_2026-09-02_panel-three-sessions.png")

# 3. blocked: urgent glyph, OS notification (the real crash toast's position and style), panel open with the blocked row leading
im = Image.open(BASE_NOTIF).convert("RGB"); d = ImageDraw.Draw(im, "RGBA")
# repaint the real toast text with the proposed session notification, same box geometry
d.rectangle([1537, 35, 1911, 91], fill=BG)
d.rounded_rectangle([1536, 34, 1912, 92], radius=4, outline=ACCENT, width=2)
d.ellipse([1552, 48, 1584, 80], fill=(60, 64, 90))
for i in range(3):
    d.rounded_rectangle([1560, 56 + i*6, 1576 - i*3, 56 + i*6 + 3], radius=1, fill=URGENT)
d.text((1600, 46), "api-refactor needs approval", font=font(15, bold=True), fill=FG)
d.text((1600, 66), "Claude wants to run: git push origin", font=font(13), fill=MUTED)
wx = draw_widget(d, 1770, "urgent", 1)
rows = [
  {"section": "Needs you", "name": "api-refactor", "agent": "claude", "state": "blocked", "since": "6m", "branch": "session/api-refactor", "owner": "praneet", "lead": True, "col": URGENT},
  {"section": "Working", "name": "nav-focus-trap", "agent": "codex", "state": "working", "since": "1m", "branch": "session/nav-focus-trap", "owner": "praneet", "col": MUTED},
  {"section": "Working", "name": "docs-pass", "agent": "opencode", "state": "idle", "since": "9m", "branch": "session/docs-pass", "owner": "agent:api-refactor", "heuristic": True, "col": MUTED},
]
panel(im, 1786, ("api-refactor needs approval", "1 blocked · 2 working", URGENT), rows, y0=104)
stamp(im, "PROPOSED · blocked session: urgent glyph, notification, panel · composed over the rig's real toast frame, 2026-09-02")
im.save(f"{OUT}/sessions-panel_proposed_arm-port_2026-09-02_blocked-notification.png")
print("ok")
