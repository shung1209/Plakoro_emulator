# Milestone 12.12h — Locale-aware Formatting

Status: **READY FOR TEST**

Added centralized formatting APIs:
- `format_integer()`
- `format_decimal()`
- `format_percent()`
- `format_signed_integer()`
- `format_count()`

Formatting templates now live in each UI language pack, including:
- percent placement
- English singular/plural vs Traditional Chinese classifiers
- label/value colon punctuation
- Move / throw / triangle / vertex / Pokémon counts

High-impact Preparation, Battle, Enerkoro, Content Studio, and Model Weight
numeric/count displays were routed through the formatting layer.

This milestone intentionally does not introduce date/time formatting because the
current gameplay/editor surfaces do not expose a player-facing date/time value.

Remaining static/technical formatting candidates: **25**
See `docs/audit/M12_12H_LOCALE_FORMAT_REMAINING.csv`.

Regression:
`res://scenes/tests/Milestone1212hLocaleAwareFormattingRegressionTest.tscn`

Expected:
`=== V2 Milestone 12.12h Locale-aware Formatting Regression Passed ===`
