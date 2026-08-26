extends Control


const THEME: Script = preload("res://scripts/ui/theme/PlakoroThemeFactory.gd")
const POKEMON_AUTHORING: Script = preload("res://scripts/content/PokemonAuthoringService.gd")
const MOVE_AUTHORING: Script = preload("res://scripts/content/MoveCardAuthoringService.gd")
const CONTENT_PLAYTEST: Script = preload("res://scripts/content/ContentPlaytestBridgeService.gd")
const DICE_CONTEXT: Script = preload("res://scripts/dice/setup/EnergyDiceBuilderContextService.gd")
const MOVE_BUTTON: Script = preload("res://scripts/ui/components/PlakoroMoveButton.gd")
const PORTRAIT: PackedScene = preload("res://scenes/ui/components/PlakoroPortrait.tscn")
const ATTRIBUTE_ICONS: Script = preload("res://scripts/ui/components/PokemonAttributeIconDisplay.gd")

@onready var database: Node = $Database
@onready var title_label: Label = %TitleLabel
@onready var player_label: Label = %PlayerLabel
@onready var ready_panel: PanelContainer = %ReadyPanel
@onready var ready_title: Label = %ReadyTitle
@onready var ready_message: Label = %ReadyMessage
@onready var pokemon_option: OptionButton = %PokemonOption
@onready var pokemon_summary: HBoxContainer = %PokemonSummary
@onready var portrait_slot: CenterContainer = %PortraitSlot
@onready var pokemon_name: Label = %PokemonName
@onready var type_caption: Label = %TypeCaption
@onready var type_row: HBoxContainer = %TypeRow
@onready var weakness_caption: Label = %WeaknessCaption
@onready var weakness_row: HBoxContainer = %WeaknessRow
@onready var pokemon_hp: Label = %PokemonHp
@onready var move_scroll: ScrollContainer = %MoveScroll
@onready var move_rows: GridContainer = %MoveRows
@onready var continue_button: Button = %ContinueButton
@onready var back_button: Button = %BackButton
@onready var status_label: Label = %StatusLabel


var choosing_moves: bool = false
var selected_pokemon_id: String = ""
var move_cards: Array[Button] = []


func _ready() -> void:
	THEME.apply_to(self)
	database.load_all()
	GameFlow.local_battle_mode = true
	if GameFlow.local_battle_setup_phase == &"":
		GameFlow.local_battle_setup_phase = &"player1_pokemon"
	continue_button.pressed.connect(_continue_setup)
	back_button.pressed.connect(_go_back)
	pokemon_option.item_selected.connect(func(_index: int) -> void: _refresh_pokemon_summary())
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_populate_pokemon()
	_refresh_pokemon_summary()
	_apply_text()
	if GameFlow.local_battle_setup_phase == &"player2_pokemon":
		call_deferred("_present_player_two_handoff")
	elif GameFlow.local_battle_setup_phase == &"ready":
		call_deferred("_show_ready_confirmation")


func _on_locale_changed(_locale: String) -> void:
	_apply_text()
	_populate_pokemon()
	_refresh_pokemon_summary()


func _apply_text() -> void:
	title_label.text = LocalizationService.tr_key(
		"main_menu.local_battle", "LOCAL VS"
	)
	var player_number: int = 2 if GameFlow.local_battle_setup_phase == &"player2_pokemon" else 1
	player_label.text = LocalizationService.tr_format(
		"preparation.local.choose_pokemon", {"player": player_number},
		"PLAYER {player}: CHOOSE POKÉMON"
	)
	continue_button.text = LocalizationService.tr_key(
		"preparation.local.continue_energy"
		if choosing_moves
		else "preparation.local.continue_moves",
		"CONTINUE TO ENERKORO" if choosing_moves else "CONTINUE TO MOVES"
	)
	back_button.text = LocalizationService.tr_key(
		"common.back" if choosing_moves else "common.main_menu",
		"Back" if choosing_moves else "Main Menu"
	)
	type_caption.text = LocalizationService.tr_key("pokemon.type", "Type")
	weakness_caption.text = LocalizationService.tr_key("battle.weakness", "Weakness")


func _populate_pokemon() -> void:
	var previous_id: String = ""
	if pokemon_option.item_count > 0 and pokemon_option.selected >= 0:
		previous_id = String(pokemon_option.get_item_metadata(pokemon_option.selected))
	pokemon_option.clear()
	for pokemon_id: String in POKEMON_AUTHORING.list_saved():
		var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(pokemon_id)
		if pokemon.is_empty() or not CONTENT_PLAYTEST.has_pokemon_default_dice(pokemon):
			continue
		var species_id: String = String(pokemon.get("species_id", pokemon_id))
		var name: String = GameContentLocalizationService.text(
			"pokemon", species_id, "name", String(pokemon.get("display_name", pokemon_id))
		)
		pokemon_option.add_item(name)
		pokemon_option.set_item_metadata(pokemon_option.item_count - 1, pokemon_id)
		if pokemon_id == previous_id:
			pokemon_option.select(pokemon_option.item_count - 1)
	continue_button.disabled = pokemon_option.item_count == 0
	_refresh_pokemon_summary()


func _refresh_pokemon_summary() -> void:
	for child: Node in portrait_slot.get_children():
		child.queue_free()
	if pokemon_option.selected < 0:
		pokemon_summary.visible = false
		return
	var pokemon_id: String = String(pokemon_option.get_item_metadata(pokemon_option.selected))
	var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(pokemon_id)
	if pokemon.is_empty():
		pokemon_summary.visible = false
		return
	pokemon_summary.visible = not choosing_moves
	var portrait: Control = PORTRAIT.instantiate()
	portrait.custom_minimum_size = Vector2(230, 230)
	portrait_slot.add_child(portrait)
	portrait.setup(pokemon)
	var species_id: String = String(pokemon.get("species_id", pokemon_id))
	pokemon_name.text = GameContentLocalizationService.text(
		"pokemon", species_id, "name", String(pokemon.get("display_name", pokemon_id))
	)
	ATTRIBUTE_ICONS.show_type(
		type_row, StringName(String(pokemon.get("pokemon_type", ""))), 38
	)
	ATTRIBUTE_ICONS.show_weaknesses(weakness_row, pokemon, 38)
	pokemon_hp.text = "HP %s" % LocalizationService.format_integer(
		int(pokemon.get("max_hp", 0))
	)


func _continue_setup() -> void:
	if not choosing_moves:
		_open_move_selection()
		return
	_finish_player_setup()


func _open_move_selection() -> void:
	if pokemon_option.selected < 0:
		return
	selected_pokemon_id = String(pokemon_option.get_item_metadata(pokemon_option.selected))
	var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(selected_pokemon_id)
	choosing_moves = true
	pokemon_option.visible = false
	pokemon_summary.visible = false
	move_scroll.visible = true
	_build_move_cards(pokemon)
	_apply_text()
	_refresh_move_selection()


func _build_move_cards(pokemon: Dictionary) -> void:
	for child: Node in move_rows.get_children():
		child.queue_free()
	move_cards.clear()
	var selected_names: Dictionary = {}
	for raw_id: Variant in pokemon.get("available_move_card_ids", []):
		var move_id: String = String(raw_id)
		var move_data: Dictionary = MOVE_AUTHORING.load_by_id(move_id)
		if move_data.is_empty():
			continue
		var name_id: String = String(move_data.get("move_name_id", move_id))
		if selected_names.has(name_id):
			continue
		selected_names[name_id] = true
		var move_card: Variant = database.get_move_card(StringName(move_id))
		if move_card == null:
			continue
		var card := Button.new()
		card.set_script(MOVE_BUTTON)
		card.custom_minimum_size = Vector2(340, 220)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.setup_battle_summary(move_card, _format_damage(move_card), "-")
		card.set_battle_availability(true, "", "-")
		card.set_hover_preview_enabled(false)
		card.toggle_mode = true
		card.set_meta("move_id", move_id)
		card.button_pressed = move_cards.size() < 4
		move_rows.add_child(card)
		_add_move_selection_feedback(card)
		move_cards.append(card)


func _refresh_move_selection() -> void:
	var count: int = 0
	for card: Button in move_cards:
		if card.button_pressed:
			count += 1
	for card: Button in move_cards:
		var selection_locked: bool = count >= 4 and not card.button_pressed
		card.disabled = selection_locked
	continue_button.disabled = count != 4
	status_label.text = LocalizationService.tr_format(
		"preparation.local.move_count", {"count": count}, "Selected Moves: {count} / 4"
	)


func _add_move_selection_feedback(card: Button) -> void:
	var outline := Panel.new()
	outline.name = "SelectionOutline"
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outline_style := StyleBoxFlat.new()
	outline_style.bg_color = Color(0, 0, 0, 0)
	outline_style.border_color = Color("ffd447")
	outline_style.set_border_width_all(5)
	outline_style.set_corner_radius_all(14)
	outline.add_theme_stylebox_override("panel", outline_style)
	card.add_child(outline)

	card.toggled.connect(
		func(pressed: bool) -> void:
			outline.visible = pressed
			_refresh_move_selection()
	)
	outline.visible = card.button_pressed


func _finish_player_setup() -> void:
	var pokemon_id: String = selected_pokemon_id
	var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(pokemon_id)
	var move_ids: Array[String] = []
	for card: Button in move_cards:
		if card.button_pressed:
			move_ids.append(String(card.get_meta("move_id", "")))
	if move_ids.size() != 4:
		status_label.text = LocalizationService.tr_key(
			"preparation.local.need_four_moves", "Choose exactly four Moves."
		)
		return
	var player_two: bool = GameFlow.local_battle_setup_phase == &"player2_pokemon"
	var result: Dictionary = (
		CONTENT_PLAYTEST.create_playtest_opponent_loadout(pokemon_id, &"normal", move_ids)
		if player_two
		else CONTENT_PLAYTEST.create_playtest_loadout(pokemon, move_ids, "pokemon_default")
	)
	if not bool(result.get("success", false)):
		status_label.text = "\n".join(result.get("errors", []))
		return
	var target_path: String = CONTENT_PLAYTEST.get_pokemon_default_dice_path(pokemon)
	var species_id: String = String(pokemon.get("species_id", "")).to_lower()
	GameFlow.local_battle_setup_phase = &"ready" if player_two else &"player2_pokemon"
	if not DICE_CONTEXT.set_context(
		"pokemon_default", target_path,
		GameFlow.LOCAL_BATTLE_SETUP_SCENE, pokemon_id, species_id
	):
		status_label.text = "Could not prepare Enerkoro editor context."
		return
	get_tree().change_scene_to_file("res://scenes/ui/EnergyDiceVisualBuilderUI.tscn")


func _go_back() -> void:
	if choosing_moves:
		choosing_moves = false
		selected_pokemon_id = ""
		pokemon_option.visible = true
		pokemon_summary.visible = true
		move_scroll.visible = false
		status_label.text = ""
		continue_button.disabled = pokemon_option.item_count == 0
		_apply_text()
		_refresh_pokemon_summary()
		return
	GameFlow.exit_phone_mode()


func _present_player_two_handoff() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = LocalizationService.tr_format(
		"battle.local.handoff_title", {"player": 2}, "PASS TO PLAYER {player}"
	)
	dialog.dialog_text = LocalizationService.tr_key(
		"battle.local.handoff_hint", "Only the active player should look at the screen."
	)
	dialog.ok_button_text = LocalizationService.tr_format(
		"battle.local.ready", {"player": 2}, "PLAYER {player} READY"
	)
	add_child(dialog)
	dialog.popup_centered(Vector2i(560, 220))


func _format_damage(move_card: Variant) -> String:
	if move_card == null or move_card.printed_damage == null:
		return "-"
	return str(int(move_card.printed_damage))


func _show_ready_confirmation() -> void:
	choosing_moves = false
	player_label.visible = false
	pokemon_option.visible = false
	pokemon_summary.visible = false
	move_scroll.visible = false
	status_label.visible = false
	continue_button.visible = false
	back_button.visible = false
	ready_panel.visible = true
	ready_title.text = LocalizationService.tr_key(
		"preparation.local.ready_title", "LOCAL VS READY"
	)
	ready_message.text = LocalizationService.tr_key(
		"preparation.local.ready_message", "Both players are configured. Start the battle?"
	)
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = LocalizationService.tr_key("preparation.local.ready_title", "LOCAL VS READY")
	dialog.dialog_text = LocalizationService.tr_key(
		"preparation.local.ready_message", "Both players are configured. Start the battle?"
	)
	dialog.ok_button_text = LocalizationService.tr_key("preparation.start_battle", "Start Battle")
	dialog.cancel_button_text = LocalizationService.tr_key("common.cancel", "Cancel")
	add_child(dialog)
	dialog.confirmed.connect(func() -> void: GameFlow.open_battle())
	dialog.canceled.connect(_return_to_player_two_setup)
	dialog.popup_centered(Vector2i(560, 220))


func _return_to_player_two_setup() -> void:
	GameFlow.local_battle_setup_phase = &"player2_pokemon"
	get_tree().reload_current_scene()
