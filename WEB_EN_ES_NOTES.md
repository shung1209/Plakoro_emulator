# Web localization: EN / ES / zh-TW / ja-JP

The Web language selector now exposes four locales:

- English (`en_US`)
- Español (España) (`es_ES`)
- 繁體中文 (`zh_TW`)
- 日本語 (`ja_JP`)

Web CJK rendering no longer depends on `SystemFont` or a CDN. The project expects the user-provided Noto Sans Regular fonts at:

- `res://assets/fonts/NotoSansJP-Regular.ttf`
- `res://assets/fonts/NotoSansTC-Regular.ttf`

Use `tools/install_noto_cjk_fonts.py` with the supplied Noto Sans ZIP before Web export. `zh_TW` uses TC as primary with JP fallback; `ja_JP` uses JP as primary with TC fallback.
