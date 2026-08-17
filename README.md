# PLAKORO — Adventure-Driven Game V2

**PLAKORO** is an unofficial, fan-made adventure-driven PC game inspired
by Bandai's Pokémon PLAKORO dice game.

Choose a partner, build an Enerkoro pool, unlock new Plakoro and Moves,
and progress through a fixed sequence of opponents. Battles retain the
physical-dice character of PLAKORO while adding progression, rewards,
save files, and a clearer game-focused interface.

This version is built on the **12.12k release-clean Official V1 Base**.
V1 remains the stable emulator and content-tool foundation; Game V2
develops that foundation into a guided adventure rather than a pure
sandbox simulation.

------------------------------------------------------------------------

## Features

-   **Adventure Progression** --- Defeat opponents in order and unlock
    the next encounter.
-   **Starter Save File** --- Begin with Charmander, Squirtle, or
    Bulbasaur and keep progress between sessions.
-   **Collection Growth** --- Winning unlocks the defeated Plakoro, its
    available Moves, and additional Energy.
-   **Level-Based Energy Rewards** --- Plakoro can reach LV5 and gain a
    player-selected Energy at each level.
-   **Enerkoro Inventory** --- Build three Enerkoro using only the Energy
    currently owned by the player.
-   **PLAKORO Dice Battles** --- Roll Charakoro and Enerkoro, meet Move
    requirements, trigger orientation effects, and fight an AI opponent.
-   **Weighted Charakoro Profiles** --- Supported models use their custom
    roll-weight profiles; other Plakoro use an equal-weight profile.
-   **Multiple Languages** --- English, Traditional Chinese, Spanish
    (Spain), and Japanese.
-   **Advanced Creation Tools** --- The V1 Content Studio and custom
    content systems remain available for advanced use, but are kept out
    of the normal adventure flow.

------------------------------------------------------------------------

## Getting Started

1.  Download and extract the game.
2.  Start **PLAKORO** and create a save file.
3.  Choose Charmander, Squirtle, or Bulbasaur as your first partner.
4.  Choose a starting Energy distribution and enter the adventure.
5.  Select the first available encounter and prepare your Loadout.
6.  Win battles to unlock the next opponent, new Plakoro, Moves, and
    Energy.

------------------------------------------------------------------------

## Interface Overview

### Main Menu and Save File

The Main Menu continues an existing adventure or starts a new save. A
save records completed encounters, unlocked Plakoro and Moves, levels,
Energy inventory, and the active player Loadout. Save files can also be
deleted from the Main Menu.

### Encounter Select

The adventure map presents a fixed sequence of opponents. Only the next
valid encounter is available, and the player cannot battle the same
Plakoro currently equipped in their Loadout.

### Battle Preparation

Battle Preparation summarizes both combatants, the player's selected
Moves, the three Enerkoro, and Move coverage probabilities. Use the
Loadout window to choose one unlocked Plakoro and four unlocked Moves.
The current player Enerkoro setup is applied automatically.

### Enerkoro Builder

Click a face on any of the three Enerkoro to replace or remove its
Energy. Every configuration is checked against the player's owned
Energy inventory; incomplete or over-budget setups cannot be used.
**Save & Use** stores the setup and returns to Battle Preparation.

### Battle

The Battle screen combines the playmat, both Plakoro, HP, rolled Energy,
Charakoro orientation, available Moves, action feedback, and a technical
timeline. Click the opponent Charakoro to inspect its revealed Moves in
a separate window without reducing the main battle space.

### Battle Report

When a battle ends, the game moves directly to the Battle Report. It
shows the result, damage, remaining HP, career record, unlocks, and
collection rewards. Level-up Energy must be selected before navigation
buttons become available, ensuring rewards are saved before the next
action.

------------------------------------------------------------------------

## Your `user_database`

When PLAKORO is launched for the first time, it automatically
creates a writable personal database under Godot's `user://` storage:

``` text
user://user_database/
```

This database is separate from the packaged game content and is intended
to store your editable PLAKORO content, including:

-   Pokémon / Charakoro data
-   Moves and Move effects
-   Move loadouts
-   Enerkoro configurations
-   Charakoro profiles and weight data
-   User-editable database content
-   Language/localization overrides

The game copies required starter data into the user database when
necessary, allowing the packaged game files to remain read-only.

### Accessing the database

The game provides a `user_database_link` so you can conveniently reach
the actual user database from your PLAKORO installation.

Use this location when you want to inspect, back up, or manually work
with your custom files.

### Important

**Do not edit the packaged game database just to create custom
content.**

Use the generated `user_database` instead. This keeps your personal
content separate from the distributed game files and makes updating the
emulator safer.

------------------------------------------------------------------------

## Enerkoro Builder

The **Enerkoro Builder** modifies the player's active three-die setup.
Energy faces may be replaced or removed, but the final setup must fill
all required faces without exceeding the player's inventory. The Move
readiness analysis helps show how a distribution changes the chance of
using each selected Move.

------------------------------------------------------------------------

## Languages

PLAKORO currently includes:

  Language              Locale
  --------------------- ---------
  English               `en_US`
  Traditional Chinese   `zh_TW`
  Spanish (Spain)       `es_ES`
  Japanese              `ja_JP`

The localization system also supports user-side language data through
the user database.

------------------------------------------------------------------------

## Backing Up Your Content

If you create custom Pokémon, Moves, Enerkoro configurations, Charakoro
profiles, or other content, periodically back up your:

``` text
user_database
```

When upgrading PLAKORO Emulator, keep your existing user database unless
the release notes for a future version specifically instruct you to
migrate or replace it.

------------------------------------------------------------------------

## Project Foundation

The **12.12k release-clean Official V1 Base** established the stable
battle engine, localization, user database, custom content, Enerkoro,
and model-weight systems.

The adventure-driven version builds the following game loop on top of
that base:

``` text
Create / Continue Save
    ↓
Choose Encounter
    ↓
Prepare Plakoro, Moves, and Enerkoro
    ↓
Battle
    ↓
Battle Report and Rewards
    ↓
Unlock the Next Opponent
```

------------------------------------------------------------------------

## Special Thanks

Thanks to everyone who contributed information, resources, testing
material, and translation references for the project.

-   **InvestigatorFew7899 from Reddit** --- for allowing the project to
    use their STL files for development and testing of the 3D model and
    dice systems.
-   **Jollto** --- for providing a translation database used as a
    localization reference.
-   **PLAKORO Chinese website** --- for providing valuable PLAKORO
    information and reference material.

And thanks to the PLAKORO community for preserving information about
this unusual piece of Pokémon history.

------------------------------------------------------------------------

## Disclaimer

PLAKORO is an **unofficial, fan-made project** created for
experimentation, preservation, and enjoyment of the PLAKORO game system.

This project is not affiliated with, endorsed by, or sponsored by
Nintendo, The Pokémon Company, Game Freak, Creatures Inc., Bandai, or
their respective affiliates.

Pokémon, PLAKORO, and related names, characters, trademarks, and
intellectual property belong to their respective owners. No ownership of
those properties is claimed by this project.

------------------------------------------------------------------------

## Have Fun!

Build your collection, refine your Enerkoro, and find a Loadout that can
complete the adventure.

**Roll forward into the PLAKORO adventure.**
