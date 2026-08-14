# Milestone 12.12f — Dynamic Text / Parameter Formatting

Status: **READY FOR TEST**

This pass audits player/editor-facing dynamic strings across Preparation, Battle,
Content Studio, Enerkoro, Model Weight, Battle Outcome, and Timeline presentation.

Converted high-impact concatenations include:
- Preparation Move availability/count, weakness fragments, AI loadout name, rating summary, Energy usage lines
- Battle Move buttons, Energy cost chips, Enerkoro modifier feedback, target-Move labels
- Content Studio assignment/reference status, effect previews, navigation/load failures,
  runtime compatibility status, new-content checklist, authoring session/dependencies,
  missing references, ID-change warnings, and library tooltips

Remaining candidates are exported to:
`docs/audit/M12_12F_DYNAMIC_TEXT_REMAINING.csv`

The remaining scan contains **123** candidates; technical/data-construction
strings are intentionally not forced through localization.

Regression:
`res://scenes/tests/Milestone1212fDynamicTextFormattingRegressionTest.tscn`

Expected:
`=== V2 Milestone 12.12f Dynamic Text Formatting Regression Passed ===`
