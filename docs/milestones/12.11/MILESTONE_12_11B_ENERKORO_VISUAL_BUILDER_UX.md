# Milestone 12.11b — Enerkoro Visual Builder UX Polish

Status: READY FOR TEST

## Scope

Presentation-only refinement of the existing Enerkoro Visual Builder.

No Enerkoro schema, probability rules, validation rules, save/load behavior, Battle
logic, or face-to-orientation mapping was changed.

## UX changes

- simplified page title to `Enerkoro Builder`
- grouped current Pokémon/source/save target into a dedicated context panel
- replaced the long introduction with a concise editing hint
- added an `Enerkoro Faces` section header
- made each Enerkoro title larger and centered
- increased face-card and Energy-icon size
- converted technical labels such as `HEAD_LEFT` to `Head Left`
- simplified `[FIXED] / [DOUBLE] / [SINGLE]` to `FIXED / DOUBLE / SINGLE`
- increased Energy Palette button/icon size and capitalized Energy names
- renamed `Live Enerkoro Preview` to `Energy Preview`
- renamed `Move Coverage` to `Move Readiness`
- made validation/probability wording easier to scan
- renamed `Load Pikachu Default` to `Reset to Default`
- renamed `Confirm Setup` to `Save & Use`
- increased dice work-area dimensions to accommodate the larger face cards

## Regression focus

Verify:

1. all three Enerkoro are fully visible
2. all six faces per Enerkoro remain selectable
3. fixed/single/double face editing still works
4. double Energy selection still requires Energy 1 then Energy 2
5. fixed-Energy duplicate restrictions still work
6. Preview, Move Readiness, Validation and Probability still update immediately
7. Save, Save & Use and Back to Preparation retain existing behavior
8. no new clipping at the normal desktop resolution

## Fix 1
- centered each unfolded Enerkoro net
- moved primary Valid / Invalid status to Current Setup upper-right
- Energy Preview, Move Readiness, Energy Output, detailed Validation and Probability are behind one Advanced toggle
- Advanced is collapsed by default

## Fix 2 — Collapsed responsive workspace

- default/collapsed Builder mode disables page-level vertical scrolling
- dice work-area height is reduced responsively for 16:9 and 16:10 desktop layouts
- Advanced mode restores automatic page scrolling because it adds analysis content
- opening/closing Advanced resets the page to the top and recalculates the dice work area
- DiceScroll remains horizontal-only in both modes
