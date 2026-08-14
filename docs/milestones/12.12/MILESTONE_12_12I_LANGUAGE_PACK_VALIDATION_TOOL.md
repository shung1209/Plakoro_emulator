# Milestone 12.12i — Language Pack Validation Tool

Status: **READY FOR TEST**

A dedicated `LanguagePackValidator` now validates UI and game-content language packs
separately.

Checks:
- schema_version
- locale
- display_name
- fallback cannot point to the same locale
- missing keys
- empty/non-string values
- unknown/extra keys
- placeholder parity (`{damage}`, `{turn}`, `{pokemon}`, etc.)
- built-in packs are strict about missing reference keys
- user packs may be partial because the runtime merge/fallback layer supplies omitted keys

Content Studio now has a `Validate Language Packs` action beside database validation.
The result is shown in the existing Database Integrity dialog without writing or
modifying user language files.

Static bundled-pack audit:
`docs/audit/M12_12I_LANGUAGE_PACK_VALIDATION.csv`

Regression:
`res://scenes/tests/Milestone1212iLanguagePackValidationRegressionTest.tscn`

Expected:
`=== V2 Milestone 12.12i Language Pack Validation Regression Passed ===`

## Built-in fallback policy

A built-in pack may intentionally be partial when it declares a valid fallback locale.
This is used by `language/content/zh_TW.json`: verified Traditional Chinese game-content
entries are translated, while unverified Move names/effect text fall back to `en_US`.
The validator reports these omissions as warnings, not failures.

The bundled zh_TW UI placeholder mismatch found during implementation was corrected.
