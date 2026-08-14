# Production Resource Audit

This is a **manual-review list, not a deletion list**.

These files have no direct inbound `res://...` reference in the cleaned project.
That alone does not prove they are unused: Godot can use `class_name`, runtime
construction, dynamic loading, or external tooling.

No production resource below was deleted automatically.

## Script candidates

- `scripts/presentation/BattleResolutionPresentationPolicy.gd`
- `scripts/presentation/BattlePresenter.gd`
- `scripts/presentation/BattleLogFormatter.gd`
- `scripts/replay/BattleReplaySerializer.gd`
- `scripts/replay/BattleReplayVerifier.gd`
- `scripts/replay/BattleReplayRecorder.gd`
- `scripts/replay/EnergyDiceSetupReplaySerializer.gd`
- `scripts/content/EnergyDiceDatabasePathService.gd`
- `scripts/content/MoveEditorContextService.gd`
- `scripts/battle/ActionEngine.gd`
- `scripts/runtime/CanonicalRuntimeCompletionAuditService.gd`
- `scripts/runtime/KyokoroEffectDisplayAuditService.gd`
- `scripts/loadout/PlayerBattleLoadoutBootstrap.gd`
- `scripts/session/BattleLaunchConfigData.gd`
- `scripts/session/BattleSession.gd`
- `scripts/dice/StructuredEnergyDiceRoller.gd`
- `scripts/dice/DiceStatistics.gd`
- `scripts/team_builder/AITeamBuilder.gd`
- `scripts/ui/workflow/BattleContentWorkflowPolicy.gd`
- `scripts/battle/rules/RuleAttachmentLoader.gd`

## Scene candidates

- `scenes/ui/PreBattleDiceSetupUI.tscn`
- `scenes/ui/EnergyDiceSetupView.tscn`
- `scenes/ui/components/StatusBadge.tscn`
- `scenes/ui/components/SectionCard.tscn`
- `scenes/ui/components/HeroPlakoroCard.tscn`

## Recommendation

Keep these for now. Review a candidate when its subsystem is next changed, or verify
runtime/export dependencies before deleting it.
