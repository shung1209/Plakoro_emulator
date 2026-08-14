# 12.12i Charakoro Effect Localization Coverage

Root cause:
- All 105 Move Cards had translated outcome-rule entries, but Battle runtime feedback
  still consumed raw `MoveKyokoroEffectPresentationService` text.
- Cards implemented through `special_effects` rather than `outcome_rules` had no
  indexed `effect_0` entry after the previous dedup normalization.

Fix:
- `GameContentLocalizationService.localize_effect_text()` now prefers card-specific
  `move_card.<card_id>.effect_N` before generic Move fallback.
- `CharakoroBattleFeedbackService` localizes each matched group by its group index.
- Battle feedback orientation names are localized.
- `PlakoroMoveButton` hover uses the same card-specific helper.
- Added 7 special-effect translations for cards without outcome rules.
- Full static audit unresolved runtime groups: 0.
