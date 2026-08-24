# Card-specific Move localization fix

The UI now resolves a Move description by exact `move_card.<card_id>.description` first, then falls back to the shared `move.<move_name_id>.description`.

Corrected EN/ES card-specific descriptions:

- `charmander_flamethrower_stw02_003`: +20 damage / next-turn Enekoro -1
- `moltres_flamethrower_ebw01_013`: +40 damage / next-turn Enekoro -2
- `pikachu_thunder_shock_stw04_002`: +20 damage
- `zapdos_thunder_shock_ebw01_032`: +10 damage

`localize_effect_text()` already preferred card-specific effect keys, so the same exact-card data is now supplied for effect rows as well. Shared duplicates with identical effects (Fly, Iron Tail) remain on shared localization keys.
