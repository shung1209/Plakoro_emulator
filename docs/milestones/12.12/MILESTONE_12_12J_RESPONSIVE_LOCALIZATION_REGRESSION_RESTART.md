# Milestone 12.12j — Responsive Localization Regression (Restart R1)

Baseline
--------
This milestone is restarted from the user-confirmed known-good build:
`plakorov-2_m12.12i-ui-cleanup-error-fix(1).zip`.

Important rule
--------------
12.12j regression code must NOT modify production UI layout to satisfy tests.

The observer regression:
- does not resize/reparent production controls
- does not change minimum sizes
- does not move AdvancedToggle
- does not change grow_direction
- does not alter size_flags
- does not toggle Advanced mode
- does not change production `.tscn` / UI scripts

Automated coverage
------------------
Locales:
- en_US
- zh_TW

Logical desktop sizes:
- 1920×1080 (16:9)
- 1920×1200 (16:10)

Surfaces:
- Battle Preparation
- Battle
- Content Studio
- Enerkoro Builder
- Model Weight Generator

Scroll-aware rule
-----------------
A Control inside a ScrollContainer is not required to have a global rectangle fully
inside the viewport. It is instead required to remain inside the expected ScrollContainer.
Only fixed chrome outside scrolling content is asserted against viewport bounds.

Manual visual gate
------------------
At both 16:9 and 16:10, verify in English and Traditional Chinese:
1. Header buttons are not clipped.
2. Main cards/panels do not overlap.
3. Dialog buttons remain readable.
4. No unexpected horizontal page scroll.
5. Enerkoro Builder matches the known-good baseline layout.
6. Advanced closed/open state remains usable.
7. Model Weight Generator remains usable without layout drift.

Regression:
`res://scenes/tests/Milestone1212jObserverOnlyResponsiveLocalizationRegressionTest.tscn`

Restart R2 correction
---------------------
The R1 test compared `Control.get_global_rect()` directly against SubViewport pixel
dimensions. This is invalid when Godot project stretch/content scaling makes logical
canvas coordinates differ from physical viewport pixels. The observed
`LanguageSelector x=3488` at a 1920-wide SubViewport was a test-coordinate-space
false positive, not evidence that the known-good Preparation UI moved.

R2 checks fixed chrome against the instantiated UI root's logical bounds by converting
global rectangles back into root-local coordinates. No production UI files were changed.

Restart R3 correction
---------------------
R2 incorrectly treated every visible `Label.clip_text = true` as a localization
failure. Compact generated controls such as Enerkoro face labels intentionally use
clipping policy even when the full text fits.

R3 measures the text with the Label's actual theme font and font size. A failure is
reported only when:
- the Label is visible and non-empty,
- `clip_text` is enabled,
- autowrap is disabled, and
- measured text width exceeds the available Label width.

No production UI files were changed.
