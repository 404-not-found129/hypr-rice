"""Regenerate omarchy/themes/*/colors.toml from the Aether blueprints.

Run after changing a blueprint:  python3 omarchy/gen-colors.py
"""
import json
from pathlib import Path

repo = Path(__file__).resolve().parent.parent
STOCK = {"gruvbox", "tokyo-night"}  # Omarchy ships these; only wallpapers are added

def mix(a, b, t):
    a, b = a.lstrip("#"), b.lstrip("#")
    return "#" + "".join(f"{round(int(a[i:i+2],16)*(1-t)+int(b[i:i+2],16)*t):02x}" for i in (0, 2, 4))

for bp in sorted((repo / "config/aether/blueprints").glob("*.json")):
    name = bp.stem
    if name in STOCK:
        continue
    p = json.loads(bp.read_text())["palette"]
    c, ext = p["colors"], p.get("extendedColors", {})
    bg, fg = c[0], c[7]
    accent = ext.get("accent", c[4])
    out = {
        "mode": "light" if p.get("lightMode") else "dark",
        "accent": accent,
        "cursor": ext.get("cursor", accent),
        "selection": mix(bg, fg, 0.18),
        "muted": c[8],
        "background": bg,
        "dark_background": mix(bg, "#000000", 0.25),
        "darker_background": mix(bg, "#000000", 0.45),
        "lighter_background": mix(bg, fg, 0.10),
        "foreground": fg,
        "dark_foreground": mix(fg, bg, 0.45),
        "light_foreground": mix(fg, c[15], 0.5),
        "bright_foreground": c[15],
        "selection_foreground": ext.get("selection_foreground", bg),
        "selection_background": ext.get("selection_background", accent),
        "red": c[1], "yellow": c[3], "orange": mix(c[1], c[3], 0.5), "green": c[2],
        "cyan": c[6], "blue": c[4], "magenta": c[5], "brown": mix(c[1], bg, 0.5),
        "bright_red": c[9], "bright_yellow": c[11], "bright_green": c[10],
        "bright_cyan": c[14], "bright_blue": c[12], "bright_magenta": c[13],
    }
    d = repo / "omarchy/themes" / name
    d.mkdir(parents=True, exist_ok=True)
    lines = [f"# {name} -- generated from config/aether/blueprints/{name}.json"]
    for k, v in out.items():
        lines.append(f'{k} = "{v}"')
    (d / "colors.toml").write_text("\n".join(lines) + "\n")
    print(name)
