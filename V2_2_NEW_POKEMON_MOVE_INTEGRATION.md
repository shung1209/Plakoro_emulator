# v2.2 New Pokémon / Move Integration

Added Gengar ST07, Metagross ST08, and Lucario ST09 move-card JSON from the supplied workbook rows 127-148.

- 21 move cards added (7 per Pokémon).
- Existing PNGs are used: gengar_standard.png, metagross_standard.png, lucario_standard.png.
- Pokémon records and default Enekoro files are added so the sets are selectable. HP/weakness and standard-equal Charakoro profile are provisional until final character-card / measured dice data is supplied.
- Effects with no existing runtime opcode are preserved in `special_effects` and flagged `needs_manual_review`.
- Source move pages provided by user are dynamic; workbook is treated as the authoritative orientation/effect mapping for the newly revealed cards.
