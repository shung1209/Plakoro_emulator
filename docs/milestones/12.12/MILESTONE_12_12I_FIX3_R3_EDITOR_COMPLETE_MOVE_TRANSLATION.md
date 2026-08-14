# Milestone 12.12i Fix 3-r3

- Audited the visible Pokémon, Charakoro Profile, Move and Battle Preparation editor paths reported in r2.
- Localized Default Enerkoro explanatory text, Charakoro orientation captions, total weight,
  Pokémon assignment status, and Move lifecycle editor labels/options/validation.
- Expanded zh_TW move localization to all 100 unique move-name IDs represented by 105 built-in Move Cards.
- Added card-specific `move_card.<card_id>.description/effect_N` entries so variants sharing one
  move_name_id can still have different translated effects.
- Battle Preparation now prefers card-specific effect/description localization before generic Move fallback.
