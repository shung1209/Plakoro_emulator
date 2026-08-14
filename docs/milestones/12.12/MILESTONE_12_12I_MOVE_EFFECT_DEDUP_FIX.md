# 12.12i Move Effect Dedup Fix

Root cause had two layers:

1. `zh_TW_moves.json` used an incorrect generated index layout:
   `effect_0` contained the whole description while actual outcome translations
   started at `effect_1`.
2. Battle Preparation rendered the whole localized move description for every
   Charakoro trigger group instead of localizing the matching outcome index.

The language pack is normalized to zero-based outcome indexing and
BattlePreparationUI now uses `localize_effect_text(move_card, group_index, fallback)`.

Normalized entries: 226
Removed stale/off-by-one entries: 205

Additionally deduplicated 98 localized description entries by semantic line while preserving first-occurrence order and labels.
