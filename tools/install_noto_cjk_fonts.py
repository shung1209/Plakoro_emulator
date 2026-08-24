#!/usr/bin/env python3
"""Install the user-supplied Noto Sans JP/TC archive into this Godot project.

Usage:
    python tools/install_noto_cjk_fonts.py "/path/to/Noto_Sans_JP,Noto_Sans_TC.zip"

The layout intentionally matches the known-working Tabletop Companion project.
"""
from pathlib import Path
import sys, zipfile, shutil

ROOT = Path(__file__).resolve().parents[1]
if len(sys.argv) != 2:
    raise SystemExit("Usage: python tools/install_noto_cjk_fonts.py <Noto font zip>")
src = Path(sys.argv[1]).expanduser().resolve()
if not src.is_file():
    raise SystemExit(f"Font archive not found: {src}")

targets = {
    "Noto_Sans_JP/static/NotoSansJP-Regular.ttf": ROOT / "assets/fonts/NotoSansJP/NotoSansJP-Regular.ttf",
    "Noto_Sans_TC/static/NotoSansTC-Regular.ttf": ROOT / "assets/fonts/NotoSansTC/NotoSansTC-Regular.ttf",
    "Noto_Sans_JP/OFL.txt": ROOT / "assets/fonts/NotoSansJP/OFL.txt",
    "Noto_Sans_TC/OFL.txt": ROOT / "assets/fonts/NotoSansTC/OFL.txt",
}
with zipfile.ZipFile(src) as z:
    names=set(z.namelist())
    missing=[n for n in targets if n not in names]
    if missing:
        raise SystemExit("Archive is missing expected entries: " + ", ".join(missing))
    for member,dest in targets.items():
        dest.parent.mkdir(parents=True, exist_ok=True)
        with z.open(member) as r, dest.open('wb') as w:
            shutil.copyfileobj(r,w)
        print(f"Installed {dest.relative_to(ROOT)}")
print("Done. Reopen Godot so the font resources are imported before Web export.")
