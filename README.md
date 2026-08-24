# PLAKORO Adventures v2.3

**PLAKORO Adventures** is an unofficial, fan-made game inspired by Bandai's
Pokémon PLAKORO dice game. It builds on the stable **12.12k release-clean
Official V1 Base**, turning the original emulator and content tools into an
adventure-driven game with progression, collection building, save files, and
two ways to play.

Choose a Plakoro, build three Enerkoro, select four Moves, roll the dice, and
advance through the arena.

## What's in v2.3

- Story Mode with New Game, Continue, save deletion, sequential encounters,
  battle rewards, collection unlocks, and Plakoro levels up to LV5.
- Free Mode with all playable content available for unrestricted battles and
  expanded Enerkoro rules.
- 21 Pokémon, 126 Move cards, and 9 custom Kyokoro weight profiles.
- New Gengar, Lucario, and Metagross data, Moves, images, and default dice
  setups.
- Three editable Enerkoro built from the player's owned Energy inventory.
- Dynamic Move cards based on the PlakoroDB card background, including full
  Energy costs, Kyokoro faces, effects, damage, and success probability.
- Warm and Dark interface themes with distinct action-button colors.
- Battle presentation improvements, attack feedback, UI motion, clearer dice
  results, and Kyokoro orientation effects.
- Windows, Linux, and Web/itch.io export presets.
- English, Traditional Chinese, Spanish (Spain), and Japanese interfaces.
- Bundled Noto Sans TC and Noto Sans JP fonts for reliable CJK display.

## Game Modes

### Story Mode

Start a new adventure with Charmander, Squirtle, or Bulbasaur, or continue an
existing save. Encounters unlock in a fixed order, and the active Plakoro
cannot battle itself. Victory unlocks the defeated Plakoro, its Moves, and new
Energy. Level rewards must be selected before continuing.

Story Mode saves:

- completed encounters and career record;
- unlocked Plakoro and Moves;
- Plakoro levels and Energy rewards;
- owned Energy and the active Enerkoro setup;
- the current player Loadout.

### Free Mode

Free Mode opens the full roster for immediate play. Choose the player and AI
Plakoro, configure four Moves, edit Enerkoro directly, and battle without Story
Mode progression restrictions. Free Mode also supports repeated Fixed Energy
when enabled in the Enerkoro Builder.

### Content Studio

Content Studio remains hidden during normal play so the main menu stays
game-focused. From the main menu, enter:

```text
↑ ↑ ↓ ↓ ← → ← → B A
```

This reveals Content Studio for the current session. The same code is required
in both Story and Free Mode workflows.

## Interface Guide

### Main Menu

Start or continue Story Mode, enter Free Mode, switch between Warm and Dark
themes, delete a Story save, or quit. Content Studio appears only after the
unlock code is entered.

### Encounter Select

Shows Story Mode progress and the next available opponent. Winning the current
encounter unlocks the next battle.

### Battle Preparation

Displays the player and opponent, the active three-Enerkoro setup, four selected
Move cards, and Loadout coverage. Configure the player Plakoro and Moves, edit
Enerkoro, then start the battle when the Loadout is valid. The opponent's
Loadout remains hidden before combat.

### Enerkoro Builder

Select a face to remove or replace its Energy. The game checks every setup
against the available Energy inventory and prevents incomplete or over-budget
configurations. **Save & Use** applies the setup and returns to Battle
Preparation.

### Battle

The battle screen presents both combatants, HP, dice results, Charakoro
orientation, Move cards, action feedback, and an optional technical timeline.
Select a Move card to attack. Select the opponent Charakoro during battle to
inspect its revealed Moves in a separate window.

### Battle Report

Victory and defeat are resolved on the Battle Report screen. It records turns,
damage, remaining HP, milestones, collection rewards, unlocks, and level-up
Energy before enabling the next navigation action.

## Running the Project

The project currently targets **Godot 4.7.1** with the GL Compatibility
renderer.

1. Clone or download this repository.
2. Open `project.godot` in Godot 4.7.1 or a compatible Godot 4 release.
3. Allow Godot to import the bundled assets and fonts.
4. Run the project from the editor.

The included export presets provide:

- Windows Desktop: `Plakoro_Adventure_v2.3.exe`
- Linux: `Plakoro_Adventure_v2.3.application`
- Web: `web/index.html`

Web export helpers are available in `tools/export_web.sh` and
`tools/export_web.ps1`.

## User Data and Custom Content

On first launch, the game copies the editable starter database into Godot's
`user://user_database/` location. This writable database is separate from the
packaged files and stores custom Pokémon, Moves, Loadouts, Enerkoro setups,
Kyokoro profiles, localization overrides, and other user-created content.

Do not edit packaged database files solely to create personal content. Back up
the user database before replacing an installation or testing major changes.
The local `user_database_link` shortcut is intentionally ignored by Git because
its destination is machine-specific.

## Asset Conventions

- Plakoro portraits use PNG files under `assets/pokemon/images/`; names may use
  a Pokémon ID such as `pikachu_standard.png`.
- Optional 3D models belong under `assets/pokemon/models/`; the resolver accepts
  GLB, GLTF, FBX, a full Pokémon ID, or a species filename.
- Energy icons use the type filenames under `assets/ui/energy/`.
- Kyokoro orientation icons use `face_up`, `face_down`, `head_up`, `head_down`,
  `head_left`, and `head_right` under `assets/ui/kyokoro/`.

## Credits and Attribution

- **Jollto / PlakoroDB** — localization reference and the Move-card background
  template from
  [`database/cards/background.png`](https://github.com/Jollto/PlakoroDB/blob/main/database/cards/background.png).
  PlakoroDB describes its original contributions as licensed under
  [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/). The template
  is used here for non-commercial fan-project presentation; Move content is
  rendered dynamically by Godot.
- **InvestigatorFew7899** — permission to use their STL files for development
  and testing of the 3D model and dice systems.
- **PLAKORO Chinese website** — game information and reference material.
- The PLAKORO community — preservation, testing, and research.

## Disclaimer

PLAKORO Adventures is an unofficial, non-commercial fan project created for
experimentation, preservation, and enjoyment of the PLAKORO game system. It is
not affiliated with, endorsed by, or sponsored by Nintendo, The Pokémon
Company, Game Freak, Creatures Inc., Bandai, or their affiliates.

Pokémon, PLAKORO, the original artwork, logos, card layouts, characters,
trademarks, and related intellectual property belong to their respective
rights holders. No ownership of those properties is claimed by this project.
