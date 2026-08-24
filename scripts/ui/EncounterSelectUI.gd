extends Control


const PLAKORO_THEME: Script = preload(
	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
)
const ENCOUNTER_CATALOG: Script = preload(
	"res://scripts/game/EncounterCatalog.gd"
)
const PLAYER_LOADOUT_PROVIDER: Script = preload(
	"res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
)


@onready var brand_label: Label = $TopBar/Brand
@onready var page_title: Label = %PageTitle
@onready var page_subtitle: Label = %PageSubtitle
@onready var progress_label: Label = %ProgressLabel
@onready var encounter_rows: VBoxContainer = %EncounterRows
@onready var back_button: Button = %BackButton


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)
	back_button.pressed.connect(GameFlow.open_main_menu)
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_apply_localized_text()


func _apply_localized_text() -> void:
	brand_label.text = LocalizationService.tr_key(
		"encounter_select.mode_label",
		"Story Mode"
	)
	page_title.text = LocalizationService.tr_key(
		"encounter_select.title",
		"CHOOSE YOUR NEXT BATTLE"
	)
	page_subtitle.text = LocalizationService.tr_key(
		"encounter_select.subtitle",
		"Win an encounter to unlock the next challenge."
	)
	back_button.text = LocalizationService.tr_key(
		"common.main_menu",
		"Main Menu"
	)
	_rebuild_encounters()


func _rebuild_encounters() -> void:
	for child: Node in encounter_rows.get_children():
		encounter_rows.remove_child(child)
		child.queue_free()

	var progress: Variant = PlayerProgress.get_progress()
	var encounters: Array[Dictionary] = ENCOUNTER_CATALOG.get_all(
		progress.starter_pokemon_id,
		progress.encounter_order_ids
	)
	var player_loadout: Variant = PLAYER_LOADOUT_PROVIDER.load_player_loadout()
	var active_pokemon_id: String = (
		String(player_loadout.pokemon_id) if player_loadout != null else ""
	)
	progress_label.text = LocalizationService.tr_format(
		"encounter_select.progress",
		{
			"completed": progress.completed_encounter_ids.size(),
			"total": encounters.size()
		},
		"Completed: {completed} / {total}"
	)

	var first_available_button: Button = null
	for encounter: Dictionary in encounters:
		var encounter_id: StringName = StringName(encounter.get("id", ""))
		var unlocked: bool = ENCOUNTER_CATALOG.is_unlocked(
			encounter_id,
			progress.completed_encounter_ids,
			progress.starter_pokemon_id,
			progress.encounter_order_ids
		)
		var self_match: bool = active_pokemon_id == String(
			encounter.get("pokemon_id", "")
		)
		var completed: bool = progress.completed_encounter_ids.has(
			String(encounter_id)
		)
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0, 112)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 18)
		button.text = _encounter_button_text(
			encounter,
			unlocked,
			completed,
			self_match
		)
		button.disabled = not unlocked or self_match
		button.pressed.connect(_select_encounter.bind(encounter_id))
		encounter_rows.add_child(button)
		if unlocked and first_available_button == null:
			first_available_button = button

	if first_available_button != null:
		first_available_button.grab_focus()


func _encounter_button_text(
	encounter: Dictionary,
	unlocked: bool,
	completed: bool,
	self_match: bool
) -> String:
	var stage_text: String = LocalizationService.tr_format(
		"encounter_select.stage",
		{"stage": int(encounter.get("stage_number", 0))},
		"STAGE {stage}"
	)
	var opponent: String = GameContentLocalizationService.text(
		"pokemon",
		String(encounter.get("species_id", "")),
		"name",
		String(encounter.get("display_name", ""))
	)
	var variant_label: String = String(encounter.get("variant_label", ""))
	if not variant_label.is_empty():
		opponent += " " + variant_label
	var title: String = LocalizationService.tr_format(
		"encounter_select.challenge",
		{"opponent": opponent},
		"{opponent} Challenge"
	)
	var difficulty_id: String = String(encounter.get("difficulty", "normal"))
	var difficulty: String = LocalizationService.tr_key(
		"preparation.difficulty." + difficulty_id,
		difficulty_id.capitalize()
	)
	var status: String
	if self_match:
		status = LocalizationService.tr_key(
			"encounter_select.self_match",
			"CHANGE PLAKORO  |  You cannot battle yourself"
		)
	elif completed:
		status = LocalizationService.tr_key(
			"encounter_select.completed",
			"COMPLETED"
		)
	elif unlocked:
		status = LocalizationService.tr_key(
			"encounter_select.available",
			"AVAILABLE"
		)
	else:
		status = LocalizationService.tr_key(
			"encounter_select.locked",
			"LOCKED  |  Win the previous encounter"
		)
	return "%s - %s\n%s  |  %s\n%s" % [
		stage_text,
		title,
		opponent,
		difficulty,
		status
	]


func _select_encounter(encounter_id: StringName) -> void:
	if not EncounterSession.select_encounter(encounter_id):
		return
	GameFlow.open_preparation()


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
