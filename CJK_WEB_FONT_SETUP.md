# CJK Web font setup

This project now uses the same font strategy as the known-working Tabletop Companion build:

- Traditional Chinese: `assets/fonts/NotoSansTC/NotoSansTC-Regular.ttf`
- Japanese (and deterministic Latin fallback): `assets/fonts/NotoSansJP/NotoSansJP-Regular.ttf`
- The active locale font is applied as the actual `Theme.default_font`, not only `ThemeDB.fallback_font`.
- Existing custom Plakoro themes are refreshed when the locale changes.
- Web export uses `all_resources`, so installed fonts are exported with the PCK.

Install the user-supplied Noto archive before opening/exporting:

```bash
python tools/install_noto_cjk_fonts.py "/path/to/Noto_Sans_JP,Noto_Sans_TC(1).zip"
```

Then reopen Godot, wait for the font import to finish, and export Web again.
