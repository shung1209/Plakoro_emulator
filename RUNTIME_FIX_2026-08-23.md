# Runtime / Free Mode / Localization Fix

- Registered `KyokoroForceNextOrientationHandler.gd` in the export-safe `DefaultOpcodeHandlerManifest`, fixing `kyokoro.force_next_orientation` compilation for Metagross Arithmetic and Gengar Headstand.
- Free Mode `Allow repeated Fixed Energy` is now persisted in `user://ui_preferences.cfg` under `[free_mode] allow_repeated_fixed_energy` and restored whenever Free Mode is entered. Story Mode continues to force the runtime flag off without deleting the saved Free Mode preference.
- Completed EN/ES card-specific localization entries for Gengar, Metagross and Lucario move names/descriptions/effect indices. Card-specific entries remain authoritative in `GameContentLocalizationService`.
