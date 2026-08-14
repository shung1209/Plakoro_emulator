# 12.12i Terminology / Brand Cleanup

- Traditional Chinese player-visible `Energy` terminology is standardized to `能量`.
- Player-visible PlaKoro / Plakoro branding is standardized to `PLAKORO`.
- Technical identifiers, script/class names, JSON keys, opcodes and file paths are unchanged.
- Remaining audit candidates: 2.
- Audit: `docs/audit/M12_12I_TERMINOLOGY_BRAND_REMAINING.csv`

Regression:
`res://scenes/tests/Milestone1212iTerminologyBrandRegressionTest.tscn`

## Fix 1 — MoveConditionEditor constant-expression parser fix

`CONDITION_TYPES` is compile-time data again. Localization keys are stored as plain
string metadata and resolved only when the OptionButton is populated at runtime.
This avoids calling `LocalizationService.tr_key()` inside a `const` expression.
