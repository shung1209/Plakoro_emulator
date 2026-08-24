extends Control


const PLAKORO_THEME: Script = preload(
	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
)
const ENCOUNTER_CATALOG: Script = preload(
	"res://scripts/game/EncounterCatalog.gd"
)
const ICONS: Script = preload(
	"res://scripts/presentation/PlakoroIconService.gd"
)


@onready var result_title: Label = %ResultTitle
@onready var matchup_label: Label = %MatchupLabel
@onready var report_brand: Label = %ReportBrand
@onready var turns_label: Label = %TurnsLabel
@onready var damage_dealt_label: Label = %DamageDealtLabel
@onready var damage_taken_label: Label = %DamageTakenLabel
@onready var turn_value: Label = %TurnValue
@onready var damage_dealt_value: Label = %DamageDealtValue
@onready var damage_taken_value: Label = %DamageTakenValue
@onready var player_hp_label: Label = %PlayerHpLabel
@onready var enemy_hp_label: Label = %EnemyHpLabel
@onready var career_title: Label = %CareerTitle
@onready var career_panel: PanelContainer = (
	career_title.get_parent().get_parent() as PanelContainer
)
@onready var career_record_label: Label = %CareerRecordLabel
@onready var streak_label: Label = %StreakLabel
@onready var milestone_label: Label = %MilestoneLabel
@onready var encounter_unlock_label: Label = %EncounterUnlockLabel
@onready var collection_reward_label: Label = %CollectionRewardLabel
@onready var energy_reward_panel: PanelContainer = %EnergyRewardPanel
@onready var energy_reward_label: Label = %EnergyRewardLabel
@onready var energy_reward_choices: HBoxContainer = %EnergyRewardChoices
@onready var save_warning_label: Label = %SaveWarningLabel
@onready var rematch_button: Button = %RematchButton
@onready var preparation_button: Button = %PreparationButton
@onready var encounters_button: Button = %EncountersButton
@onready var main_menu_button: Button = %MainMenuButton


var outcome: Variant = null
var advance_to_next_opponent: bool = false


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)
	rematch_button.pressed.connect(GameFlow.open_battle)
	preparation_button.pressed.connect(GameFlow.open_preparation)
	encounters_button.pressed.connect(GameFlow.open_encounter_select)
	main_menu_button.pressed.connect(GameFlow.open_main_menu)
	LocalizationService.locale_changed.connect(_on_locale_changed)
	outcome = GameFlow.get_battle_outcome()
	advance_to_next_opponent = GameFlow.should_advance_after_battle_result()
	_apply_localized_text()
	_refresh_energy_choice()
	rematch_button.grab_focus()
	_continue_to_next_opponent_if_ready.call_deferred()


func _apply_localized_text() -> void:
	report_brand.text = LocalizationService.tr_key(
		"battle_result.report",
		"PLAKORO  |  BATTLE REPORT"
	)
	turns_label.text = LocalizationService.tr_key(
		"battle_result.turns",
		"TURNS"
	)
	damage_dealt_label.text = LocalizationService.tr_key(
		"battle_result.damage_dealt",
		"DAMAGE DEALT"
	)
	damage_taken_label.text = LocalizationService.tr_key(
		"battle_result.damage_taken",
		"DAMAGE TAKEN"
	)
	career_title.text = LocalizationService.tr_key(
		"battle_result.career",
		"CAREER RECORD"
	)
	rematch_button.text = LocalizationService.tr_key(
		"battle_result.rematch",
		"Rematch"
	)
	preparation_button.text = LocalizationService.tr_key(
		"battle_result.preparation",
		"Change Loadout"
	)
	encounters_button.text = LocalizationService.tr_key(
		"battle_result.encounters",
		"Choose Encounter"
	)
	main_menu_button.text = LocalizationService.tr_key(
		"common.main_menu",
		"Main Menu"
	)

	if outcome == null or not outcome.has_method("is_valid") or not outcome.is_valid():
		_show_missing_outcome()
		return

	result_title.text = LocalizationService.tr_key(
		"battle.victory" if outcome.player_won() else "battle.defeat",
		"VICTORY" if outcome.player_won() else "DEFEAT"
	)
	result_title.add_theme_color_override(
		"font_color",
		Color(0.36, 0.92, 0.56, 1.0)
		if outcome.player_won()
		else Color(0.96, 0.40, 0.40, 1.0)
	)
	matchup_label.text = LocalizationService.tr_format(
		"battle_result.matchup",
		{
			"player": outcome.player_name,
			"enemy": outcome.enemy_name
		},
		"{player}  VS  {enemy}"
	)
	turn_value.text = str(outcome.turn_count)
	damage_dealt_value.text = str(outcome.player_damage_dealt)
	damage_taken_value.text = str(outcome.enemy_damage_dealt)
	player_hp_label.text = LocalizationService.tr_format(
		"battle_result.player_hp",
		{
			"current": outcome.player_hp,
			"maximum": outcome.player_max_hp
		},
		"YOUR HP  {current} / {maximum}"
	)
	enemy_hp_label.text = LocalizationService.tr_format(
		"battle_result.enemy_hp",
		{
			"current": outcome.enemy_hp,
			"maximum": outcome.enemy_max_hp
		},
		"OPPONENT HP  {current} / {maximum}"
	)
	_apply_progress_text()


func _apply_progress_text() -> void:
	if GameFlow.free_mode:
		career_panel.visible = false
		milestone_label.visible = false
		encounter_unlock_label.visible = false
		collection_reward_label.visible = false
		save_warning_label.visible = false
		encounters_button.visible = false
		return
	career_panel.visible = true
	encounters_button.visible = true
	var progress: Variant = PlayerProgress.get_progress()
	var update: Dictionary = PlayerProgress.get_last_update()
	career_record_label.text = LocalizationService.tr_format(
		"battle_result.career_record",
		{
			"battles": progress.total_battles,
			"wins": progress.wins,
			"losses": progress.losses
		},
		"{battles} Battles   |   {wins} Wins   |   {losses} Losses"
	)
	streak_label.text = LocalizationService.tr_format(
		"battle_result.streak_record",
		{
			"current": progress.current_win_streak,
			"best": progress.best_win_streak
		},
		"Current Streak: {current}   |   Best: {best}"
	)
	var newly_unlocked: Array = update.get("newly_unlocked", []) as Array
	milestone_label.visible = newly_unlocked.has("first_victory")
	milestone_label.text = LocalizationService.tr_key(
		"battle_result.first_victory",
		"NEW MILESTONE  |  FIRST VICTORY"
	)
	var newly_completed: Array = update.get(
		"newly_completed_encounters",
		[]
	) as Array
	encounter_unlock_label.visible = not newly_completed.is_empty()
	encounter_unlock_label.text = LocalizationService.tr_key(
		"battle_result.all_encounters_complete"
		if progress.completed_encounter_ids.size() >= ENCOUNTER_CATALOG.get_all(progress.starter_pokemon_id).size()
		else "battle_result.encounter_unlocked",
		"ALL ENCOUNTERS COMPLETE"
		if progress.completed_encounter_ids.size() >= ENCOUNTER_CATALOG.get_all(progress.starter_pokemon_id).size()
		else "NEXT ENCOUNTER UNLOCKED"
	)
	var newly_unlocked_pokemon: Array = update.get(
		"newly_unlocked_pokemon",
		[]
	) as Array
	collection_reward_label.visible = not newly_unlocked_pokemon.is_empty()
	if collection_reward_label.visible:
		var encounter: Dictionary = EncounterSession.current_encounter
		var pokemon_name: String = GameContentLocalizationService.text(
			"pokemon",
			String(encounter.get("species_id", "")),
			"name",
			String(encounter.get("display_name", outcome.enemy_name))
		)
		var variant_label: String = String(encounter.get("variant_label", ""))
		if not variant_label.is_empty():
			pokemon_name += " " + variant_label
		collection_reward_label.text = LocalizationService.tr_format(
			"battle_result.collection_reward",
			{
				"pokemon": pokemon_name,
				"moves": outcome.reward_move_card_ids.size()
			},
			"COLLECTION UPDATED  |  {pokemon} + {moves} Moves + 6 Energy"
		)
	save_warning_label.visible = update.has("saved") and not bool(update["saved"])
	save_warning_label.text = LocalizationService.tr_key(
		"battle_result.save_failed",
		"Progress could not be saved."
	)


func _refresh_energy_choice() -> void:
	for child: Node in energy_reward_choices.get_children():
		child.queue_free()
	if GameFlow.free_mode:
		energy_reward_panel.visible = false
		_set_navigation_enabled(true)
		return
	var progress: Variant = PlayerProgress.get_progress()
	var choices: Array = progress.pending_energy_choices
	energy_reward_panel.visible = not choices.is_empty()
	_set_navigation_enabled(choices.is_empty())
	if choices.is_empty():
		return
	var choice: Dictionary = choices[0]
	var pokemon_id: String = String(choice.get("pokemon_id", ""))
	var level: int = int(choice.get("level", 1))
	var species_id: String = pokemon_id.get_slice("_", 0)
	var pokemon_name: String = GameContentLocalizationService.text(
		"pokemon", species_id, "name", species_id.capitalize()
	)
	energy_reward_label.text = LocalizationService.tr_format(
		"battle_result.energy_choice",
		{"pokemon": pokemon_name, "level": level},
		"LEVEL UP REWARD\n{pokemon} reached LV{level} - Choose 1 Energy to add"
	)
	var first_button: Button = null
	for raw_energy: Variant in choice.get("options", []):
		var energy: StringName = StringName(raw_energy)
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0, 72)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = GameContentLocalizationService.localize_type(energy)
		button.icon = ICONS.load_energy_icon(energy)
		button.expand_icon = false
		button.add_theme_constant_override("icon_max_width", 36)
		button.add_theme_font_size_override("font_size", 20)
		_style_energy_choice_button(button)
		button.pressed.connect(
			_claim_energy.bind(StringName(pokemon_id), level, energy)
		)
		energy_reward_choices.add_child(button)
		if first_button == null:
			first_button = button
	if first_button != null:
		first_button.grab_focus.call_deferred()


func _style_energy_choice_button(button: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = (
		Color("e1d9c7") if PLAKORO_THEME.is_warm_theme()
		else Color(0.055, 0.085, 0.12, 1.0)
	)
	normal.border_color = Color(1.0, 0.72, 0.18, 0.95)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 18.0
	normal.content_margin_right = 18.0
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = (
		Color("d7cdaf") if PLAKORO_THEME.is_warm_theme()
		else Color(0.12, 0.18, 0.24, 1.0)
	)
	hover.border_color = Color(1.0, 0.86, 0.36, 1.0)
	hover.set_border_width_all(3)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = (
		Color("cbbd98") if PLAKORO_THEME.is_warm_theme()
		else Color(0.18, 0.24, 0.28, 1.0)
	)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)


func _claim_energy(
	pokemon_id: StringName,
	level: int,
	energy_type: StringName
) -> void:
	if not PlayerProgress.claim_energy_choice(pokemon_id, level, energy_type):
		save_warning_label.visible = true
		return
	_refresh_energy_choice()
	_continue_to_next_opponent_if_ready()


func _continue_to_next_opponent_if_ready() -> void:
	if GameFlow.free_mode:
		return
	if not advance_to_next_opponent:
		return
	if not PlayerProgress.get_progress().pending_energy_choices.is_empty():
		return
	advance_to_next_opponent = false
	GameFlow.open_encounter_select()


func _set_navigation_enabled(enabled: bool) -> void:
	for button: Button in [
		rematch_button, preparation_button, encounters_button, main_menu_button
	]:
		button.disabled = not enabled


func _show_missing_outcome() -> void:
	result_title.text = LocalizationService.tr_key(
		"battle_result.unavailable",
		"NO BATTLE RESULT"
	)
	result_title.add_theme_color_override(
		"font_color",
		Color(0.82, 0.86, 0.9, 1.0)
	)
	matchup_label.text = LocalizationService.tr_key(
		"battle_result.unavailable_hint",
		"Complete a battle to view its report."
	)
	turn_value.text = "-"
	damage_dealt_value.text = "-"
	damage_taken_value.text = "-"
	player_hp_label.text = "-"
	enemy_hp_label.text = "-"
	career_record_label.text = "-"
	streak_label.text = "-"
	milestone_label.visible = false
	encounter_unlock_label.visible = false
	collection_reward_label.visible = false
	save_warning_label.visible = false
	rematch_button.disabled = true


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
