# Milestone 12.11a — User Database Shortcut Folder

## Goal

Provide a convenience folder in the project/game root that opens the real Godot
`user://user_database/` directory.

This milestone does **not** move, redirect, copy, or synchronize the user database.

## Authoritative path

All runtime code continues to use:

`user://user_database/`

The convenience path is:

`<project-or-game-root>/user_database_link`

## Platform behavior

### Windows

Creates a directory junction:

`user_database_link → <Godot user://user_database absolute path>`

Implementation uses `mklink /J`.

### Linux / macOS / FreeBSD

Creates a symbolic link using `ln -s`.

## Root selection

- Editor/development run: project `res://` root
- Exported build: directory containing the executable

## Safety

- The target `user://user_database` is created by the existing bootstrap first.
- Existing `user_database_link` paths are never deleted or replaced automatically.
- Shortcut creation failure only produces a warning.
- Game runtime never depends on the shortcut.
- All saves still target `user://user_database`.

## Expected startup behavior

On first successful creation, console shows:

`UserDatabaseBootstrap: user_database_link → <actual user database path>`

On later launches, the existing shortcut is left unchanged.
