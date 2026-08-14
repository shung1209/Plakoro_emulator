# Milestone 12.11d — Localization Foundation

Status: **READY FOR TEST**

## User language directory

Users can add language JSON files under:

`user://user_database/language/`

The existing `user_database_link` therefore also provides direct access to language
files from the game/project root.

## Language JSON schema

```json
{
  "schema_version": "1.0",
  "locale": "zh_TW",
  "display_name": "繁體中文",
  "fallback": "en_US",
  "strings": {
    "common.save": "儲存",
    "battle.your_turn": "你的回合"
  }
}
```

Required fields:

- `schema_version`
- `locale`
- `display_name`
- `strings`

`fallback` is optional. English is always the final fallback.

## Bundled starter languages

- `en_US`
- `zh_TW`

On first run/update they are copied into `user://user_database/language/` only when the
destination file does not already exist. User modifications are never overwritten.

## Runtime behavior

`LocalizationService` is an autoload.

Lookup order:

1. selected user language JSON
2. selected language fallback
3. bundled/user `en_US`
4. supplied default text
5. translation key itself

User JSON overrides a bundled locale with the same locale ID.

The selected locale is persisted in:

`user://user_database/language/_settings.json`

The first selection defaults to Traditional Chinese when the OS locale begins with
`zh`; otherwise English.

## API foundation

```gdscript
LocalizationService.tr_key("battle.your_turn")
LocalizationService.set_locale("zh_TW")
LocalizationService.get_available_languages()
LocalizationService.reload_languages()
```

12.11d establishes the data/runtime foundation only. Full UI string migration and the
Language selector belong to the next localization UX stage.

## Regression scene

`res://scenes/tests/Milestone1211dLocalizationFoundationRegressionTest.tscn`

Expected marker:

`=== V2 Milestone 12.11d Localization Foundation Regression Passed ===`

## Fix 1 — Custom locale filename resolution

The first regression exposed a loader mismatch: language discovery correctly read the
`locale` field inside user JSON, but locale activation still assumed the filename was
exactly `<locale>.json`.

User language filenames are now intentionally independent from locale IDs. The loader
scans `user_database/language/*.json` and resolves the language by its JSON `locale`
field. For example, `m12_test.json` may declare `locale: "m12_TEST"` and loads normally.
