extends Control


const PLAKORO_THEME: Script = preload(
	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
)
const PROFILE_CREATION: Script = preload(
	"res://scripts/game/ProfileCreationService.gd"
)
const ENERGY_CATALOG: Script = preload(
	"res://scripts/game/EnergyProgressionCatalog.gd"
)


@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var status_label: Label = %StatusLabel
@onready var charmander_button: Button = %CharmanderButton
@onready var squirtle_button: Button = %SquirtleButton
@onready var bulbasaur_button: Button = %BulbasaurButton
@onready var back_button: Button = %BackButton
@onready var energy_choice_label: Label = %EnergyChoiceLabel
@onready var energy_choices: HBoxContainer = %EnergyChoices


var selected_starter_id: StringName = &""


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)
	charmander_button.pressed.connect(
		_choose_starter.bind(&"charmander_standard")
	)
	squirtle_button.pressed.connect(
		_choose_starter.bind(&"squirtle_standard")
	)
	bulbasaur_button.pressed.connect(
		_choose_starter.bind(&"bulbasaur_standard")
	)
	back_button.pressed.connect(GameFlow.open_main_menu)
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_apply_localized_text()
	charmander_button.grab_focus()


func _apply_localized_text() -> void:
	title_label.text = LocalizationService.tr_key(
		"save_creation.title",
		"CHOOSE YOUR FIRST PLAKORO"
	)
	subtitle_label.text = LocalizationService.tr_key(
		"save_creation.subtitle",
		"Your partner and all of its Moves will be added to the new save."
	)
	charmander_button.text = _starter_text(
		"charmander",
		"Charmander",
		"Fire"
	)
	squirtle_button.text = _starter_text("squirtle", "Squirtle", "Water")
	bulbasaur_button.text = _starter_text(
		"bulbasaur",
		"Bulbasaur",
		"Grass"
	)
	back_button.text = LocalizationService.tr_key("common.back", "Back")
	energy_choice_label.text = LocalizationService.tr_key(
		"save_creation.energy_choice",
		"Choose a 9-Energy starting distribution."
	)


func _starter_text(species_id: String, fallback: String, type_fallback: String) -> String:
	var name: String = GameContentLocalizationService.text(
		"pokemon",
		species_id,
		"name",
		fallback
	)
	var type_name: String = GameContentLocalizationService.text(
		"type",
		type_fallback.to_lower(),
		"name",
		type_fallback
	)
	return LocalizationService.tr_format(
		"save_creation.starter",
		{"name": name, "type": type_name},
		"{name}\nType: {type}"
	)


func _choose_starter(starter_pokemon_id: StringName) -> void:
	selected_starter_id = starter_pokemon_id
	for child: Node in energy_choices.get_children():
		child.queue_free()
	var options: Array[String] = ENERGY_CATALOG.get_energy_options(starter_pokemon_id)
	var primary_energy: StringName = StringName(options[0])
	for energy: String in options:
		var button: Button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = (
			LocalizationService.tr_format(
				"save_creation.energy_primary_nine",
				{"primary": GameContentLocalizationService.localize_type(primary_energy)},
				"{primary} ×9"
			)
			if StringName(energy) == primary_energy
			else LocalizationService.tr_format(
				"save_creation.energy_split",
				{
					"primary": GameContentLocalizationService.localize_type(primary_energy),
					"alternate": GameContentLocalizationService.localize_type(StringName(energy))
				},
				"{primary} ×8 + {alternate} ×1"
			)
		)
		button.pressed.connect(_create_save.bind(StringName(energy)))
		energy_choices.add_child(button)
	energy_choice_label.visible = true
	energy_choices.visible = true
	status_label.text = ""


func _create_save(starter_energy: StringName) -> void:
	_set_buttons_disabled(true)
	status_label.text = LocalizationService.tr_key(
		"save_creation.creating",
		"Creating save..."
	)
	var result: Dictionary = PROFILE_CREATION.create_new_save(
		selected_starter_id,
		starter_energy
	)
	if not bool(result.get("success", false)):
		status_label.text = LocalizationService.tr_format(
			"save_creation.failed",
			{"error": String(result.get("error", "Unknown error"))},
			"Could not create save: {error}"
		)
		_set_buttons_disabled(false)
		return
	GameFlow.open_encounter_select()


func _set_buttons_disabled(disabled: bool) -> void:
	for button: Button in [
		charmander_button,
		squirtle_button,
		bulbasaur_button,
		back_button
	]:
		button.disabled = disabled
	for child: Node in energy_choices.get_children():
		if child is Button:
			(child as Button).disabled = disabled


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
	if selected_starter_id != &"":
		_choose_starter(selected_starter_id)
