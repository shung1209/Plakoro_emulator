# 12.12i Preparation / Quit / Regression Fix

- Removed redundant player and AI `Loadout: ...` labels from the main Battle Preparation summary.
  Loadout details remain available in the Battle Loadout dialog.
- Global quit confirmation is fully localized and refreshes on locale changes.
- Battle quit confirmation body uses the same localized message.
- Fixed Charakoro localization regression test to instantiate/load DatabaseService rather than
  incorrectly invoking an instance method statically.
