# PLAKORO Emulator --- V1

**PLAKORO Emulator** is a fan-made PC recreation and sandbox inspired by
Bandai's Pokémon PLAKORO dice game.

Roll your Pokémon, roll your Enerkoro, use different moves, and battle
against an AI opponent while experimenting with different dice
configurations.

The goal of the project is not only to emulate the PLAKORO battle
experience, but also to provide tools for players to customize,
experiment with, and create their own setups.

> **V1 is the first official stable baseline of PLAKORO Emulator.**

------------------------------------------------------------------------

## Features

-   **Pokémon Dice Battles** --- Play PLAKORO-style battles against an
    AI opponent.
-   **Enerkoro System** --- Configure and experiment with different
    Energy combinations.
-   **Battle Preparation** --- Configure Pokémon, Moves, Enerkoro,
    loadouts, AI difficulty, and battle settings.
-   **Content Studio** --- Create and modify Pokémon, Moves, Charakoro
    profiles, and supported game content.
-   **Dice Weight Customization** --- Adjust Charakoro face weights and
    experiment with roll probabilities.
-   **Model Weight Generator** --- Use compatible 3D models to help
    generate model-weight information for custom Charakoro
    configurations.
-   **Custom Loadouts** --- Select Pokémon, Moves, and Enerkoro setups
    for battle.
-   **AI Battles** --- Test your configurations against the built-in AI
    opponent.
-   **Custom Content** --- Extend or modify supplied game data through
    your personal user database.
-   **Multiple Languages** --- English, Traditional Chinese, Spanish
    (Spain), and Japanese.
-   **Sandbox Focus** --- Experiment with PLAKORO content and
    configurations however you like.

------------------------------------------------------------------------

## Getting Started

1.  Download and extract the game.
2.  Start **PLAKORO Emulator**.
3.  On first launch, the game prepares your personal `user_database`.
4.  Use **Battle Preparation** to select your Pokémon, Moves, Enerkoro,
    and battle settings.
5.  Start a battle and test your setup against the AI.
6.  Use **Content Studio**, **Enerkoro Builder**, and **Model Weight
    Generator** to create or customize content.

------------------------------------------------------------------------

## Your `user_database`

When PLAKORO Emulator is launched for the first time, it automatically
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

## Content Studio

**Content Studio** is the main interface for editing supported PLAKORO
content.

You can use it to work with Pokémon / Charakoro information, Moves,
effects, profiles, and other editable database content without manually
editing JSON files.

For most users, Content Studio is the recommended way to customize the
game. Advanced users can also inspect the JSON data inside the user
database directly.

------------------------------------------------------------------------

## Enerkoro Builder

The **Enerkoro Builder** allows you to create and modify Enerkoro
configurations.

Customize Energy faces, save different configurations, and use your
saved setup when preparing a battle.

This is useful for experimenting with how different Energy distributions
affect available Moves and battle behavior.

------------------------------------------------------------------------

## Model Weight Generator

The **Model Weight Generator** is provided for users experimenting with
custom Charakoro / Pokémon 3D models.

It can analyze supported model information and assist with generating
model-weight data for use by the project.

Because custom models may come from unofficial sources and may differ in
geometry, scale, mesh quality, or watertightness, generated values
should be treated as an aid for experimentation rather than an exact
recreation of a physical manufactured die.

------------------------------------------------------------------------

## Languages

PLAKORO Emulator V1 includes:

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

## V1 Status

V1 establishes the first official base version of PLAKORO Emulator.

The core flow is:

``` text
Content Studio
    ↓
Save / Reload
    ↓
Battle Preparation
    ↓
Battle
    ↓
Result
    ↓
Rematch / Preparation
```

V1 also establishes the localization, custom-content, Enerkoro,
model-weight, and user-database foundations that future versions can
build upon.

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

PLAKORO Emulator is an **unofficial, fan-made project** created for
experimentation, preservation, and enjoyment of the PLAKORO game system.

This project is not affiliated with, endorsed by, or sponsored by
Nintendo, The Pokémon Company, Game Freak, Creatures Inc., Bandai, or
their respective affiliates.

Pokémon, PLAKORO, and related names, characters, trademarks, and
intellectual property belong to their respective owners. No ownership of
those properties is claimed by this project.

------------------------------------------------------------------------

## Have Fun!

Experiment with different Pokémon, Moves, Enerkoro configurations,
weights, and custom content.

**Play PLAKORO your way.**
