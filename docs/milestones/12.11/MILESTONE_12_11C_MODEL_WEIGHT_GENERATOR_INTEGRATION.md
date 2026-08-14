# Milestone 12.11c — Model Weight Generator Integration

Status: **READY FOR TEST**

## Source

Integrated from the provided `plakoro_model_weight_generator` Godot project.

The original generator logic was preserved as the basis for:

- STL runtime import
- OBJ runtime import
- GLB / GLTF runtime import
- mesh information / watertight analysis
- model normalization
- 3D preview and orientation confirmation
- Godot/Jolt throw simulation
- orientation classification
- weighted Charakoro profile generation

## Content Studio integration

Content Studio now has a fourth tab:

`Model Weight Generator`

The generator runs inside Content Studio instead of as a separate project.

When this tab is active:

- the normal Content Library is hidden
- the normal Pokémon / Charakoro / Move authoring footer is hidden
- the generator gets the full editor workspace
- returning to other Content Studio tabs restores the normal authoring UI

## Output

Generated profiles are written directly to:

`user://user_database/kyokoro_profiles/`

The generated JSON retains the existing runtime-compatible fields:

- `schema_version`
- `id`
- `roll_mode`
- `orientation_weights`
- `scene_path`
- `physics_profile`

It also adds non-runtime provenance metadata under `model_analysis`:

- source
- source model filename
- normalized max size in mm
- watertight result
- triangle count

Battle runtime remains decoupled from the generator and only consumes the generated
Charakoro profile.

## Test focus

1. Open Content Studio → Model Weight Generator.
2. Import STL / OBJ / GLB / GLTF.
3. Confirm mesh information appears.
4. Verify 3D preview, drag rotation and X/Y/Z rotation controls.
5. Confirm orientation.
6. Run a small/fast throw simulation first.
7. Confirm JSON is created under `user://user_database/kyokoro_profiles/`.
8. Return to Charakoro Profile Editor and verify the generated profile can be loaded.
9. Confirm normal Pokémon / Move / Charakoro authoring still works after leaving the tool.


## Fix 1 — Content Studio UX

- Model Weight Generator is treated as an independent utility, so entering/leaving it
  does not trigger Content Studio's document `Unsaved Changes` dialog.
- Removed the generator's artificial 980 px minimum height.
- Reduced preview/model-info minimum heights and outer vertical spacing.
- Content Studio disables its outer vertical ScrollContainer while the generator is active.
- Target: ordinary 16:9 and 16:10 desktop layouts should fit without page-level vertical scrolling.

## Fix 2
- removed the duplicated `Model Weight Generator` heading from the integrated panel
- retained the workflow subtitle and supported-format indicator

## Fix 3 — Workspace rearrangement

- removed the duplicated in-tool title
- Orientation Setup is now the upper-left primary workspace
- Model & Charakoro Profile moved to the upper-right
- model/profile text fields are constrained by the right column instead of spanning the page
- Simulation/Result occupies the lower-right remaining space
- reduced panel margins and minimum heights so the normal workflow targets a single
  16:9 / 16:10 page without vertical scrolling or clipped controls

## Fix 4 — Workspace width balance

- changed the main workspace from a heavily left-biased split to approximately 1:1
- right-side Model/Profile and Simulation panels now receive substantially more width
- retained a slight left bias for Orientation controls
- reduced the preview minimum width so the 3D workspace can contract cleanly

## Integration Regression Gate

Test scene:

`res://scenes/tests/Milestone1211cModelWeightIntegrationRegressionTest.tscn`

The gate verifies:

1. Generator output directory is `user://user_database/kyokoro_profiles`.
2. Generator-compatible weighted JSON passes Charakoro authoring validation.
3. Content Studio save/reload preserves `model_analysis` provenance.
4. Runtime `DatabaseService` merges user Charakoro profiles over/alongside built-ins.
5. Runtime `DatabaseService` also merges user Pokémon/Move overrides so authored
   references are usable in Battle.
6. A Pokémon user override can reference a newly generated user Charakoro profile.
7. Runtime Pokémon resolves to the exact generated profile and orientation weights.
8. Temporary test files are restored/removed after the test.

Expected marker:

`=== V2 Milestone 12.11c Model Weight Integration Regression Passed ===`
