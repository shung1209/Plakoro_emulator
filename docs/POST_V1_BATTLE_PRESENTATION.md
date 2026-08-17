# Post-V1 Battle Presentation

Official V1 base: `official-v1` (`2d60076`, Milestone 12.12k release-clean)

The post-V1 direction is to preserve the proven battle rules while making each
decision and resolution feel like a game event instead of a simulation readout.

## First playable pass

- Promote the arena layout: combatants and dice form the visual stage; Moves,
  battle feedback, and Timeline become the lower command layer.
- Give Player and AI distinct blue/red identities and HP treatments.
- Make the dice result the visual focal point with rolling, staggered stops,
  landed-state highlights, and actor-specific roll headings.
- Keep all existing exact-result reconstruction and battle resolution behavior.
- Retain responsive profiles and the four V1 locales.

## 2P Playseat visual reference

The battle screen adapts the official 2P Playseat's table language rather than
copying it literally: opposing players occupy diagonal far/near ends, the dice
live in the shared circular resolution field, and the player's Moves sit along
the near command edge. All opponent information remains upright for a single
digital display.

## Next experiments

1. Add anticipation and impact beats around Move selection and damage.
2. Evaluate a true 2D/3D dice toss while retaining deterministic final results.
3. Add a compact battle HUD mode that hides technical Timeline detail by default.
4. Add sound and screen feedback only after the visual timing is approved.

The first pass intentionally changes presentation only. Battle rules, probability,
AI decisions, save data, and content schemas remain part of the Official V1 base.
