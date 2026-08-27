extends Control


const THEME: Script = preload("res://scripts/ui/theme/PlakoroThemeFactory.gd")
const POKEMON_AUTHORING: Script = preload("res://scripts/content/PokemonAuthoringService.gd")
const MOVE_AUTHORING: Script = preload("res://scripts/content/MoveCardAuthoringService.gd")
const CONTENT_PLAYTEST: Script = preload("res://scripts/content/ContentPlaytestBridgeService.gd")
const DICE_CONTEXT: Script = preload("res://scripts/dice/setup/EnergyDiceBuilderContextService.gd")
const MOVE_BUTTON: Script = preload("res://scripts/ui/components/PlakoroMoveButton.gd")
const PORTRAIT: PackedScene = preload("res://scenes/ui/components/PlakoroPortrait.tscn")
const ATTRIBUTE_ICONS: Script = preload("res://scripts/ui/components/PokemonAttributeIconDisplay.gd")
const PLAYER_LOADOUT_PROVIDER: Script = preload(
	"res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
)
const PLAYER_TWO_LOADOUT_PROVIDER: Script = preload(
	"res://scripts/loadout/AIBattleLoadoutProvider.gd"
)

@onready var database: Node = $Database
@onready var setup_panel: PanelContainer = $Center/Panel
@onready var setup_margin: MarginContainer = $Center/Panel/Margin
@onready var title_label: Label = %TitleLabel
@onready var player_label: Label = %PlayerLabel
@onready var ready_panel: PanelContainer = %ReadyPanel
@onready var ready_title: Label = %ReadyTitle
@onready var ready_message: Label = %ReadyMessage
@onready var reveal_cards: BoxContainer = %RevealCards
@onready var ready_actions: BoxContainer = %ReadyActions
@onready var ready_back_button: Button = %ReadyBackButton
@onready var start_battle_button: Button = %StartBattleButton
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
var matchup_reveal_started: bool = false


func _ready() -> void:
	THEME.apply_to(self)
	database.load_all()
	GameFlow.local_battle_mode = true
	if GameFlow.local_battle_setup_phase == &"":
		GameFlow.local_battle_setup_phase = &"player1_pokemon"
	continue_button.pressed.connect(_continue_setup)
	back_button.pressed.connect(_go_back)
	ready_back_button.pressed.connect(_return_to_player_two_setup)
	start_battle_button.pressed.connect(_reveal_matchup_and_start)
	pokemon_option.item_selected.connect(func(_index: int) -> void: _refresh_pokemon_summary())
	LocalizationService.locale_changed.connect(_on_locale_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_populate_pokemon()
	_refresh_pokemon_summary()
	_apply_text()
	_apply_responsive_layout()
	if GameFlow.local_battle_setup_phase == &"player2_pokemon":
		call_deferred("_present_player_two_handoff")
	elif GameFlow.local_battle_setup_phase == &"ready":
		call_deferred("_show_ready_confirmation")


func _on_locale_changed(_locale: String) -> void:
	_apply_text()
	_populate_pokemon()
	_refresh_pokemon_summary()


func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var portrait_layout: bool = GameFlow.phone_mode or viewport_size.x < 760.0
	if portrait_layout:
		ready_actions.vertical = true
		reveal_cards.vertical = true
		setup_panel.custom_minimum_size = Vector2(
			minf(440.0, maxf(320.0, viewport_size.x - 24.0)),
			minf(820.0, maxf(620.0, viewport_size.y - 24.0))
		)
		setup_margin.add_theme_constant_override("margin_left", 18)
		setup_margin.add_theme_constant_override("margin_right", 18)
		setup_margin.add_theme_constant_override("margin_top", 22)
		setup_margin.add_theme_constant_override("margin_bottom", 22)
		move_rows.columns = 1
		move_scroll.custom_minimum_size.y = 480
	else:
		ready_actions.vertical = false
		reveal_cards.vertical = false
		setup_panel.custom_minimum_size = Vector2(880, 820)
		setup_margin.add_theme_constant_override("margin_left", 28)
		setup_margin.add_theme_constant_override("margin_right", 28)
		setup_margin.add_theme_constant_override("margin_top", 42)
		setup_margin.add_theme_constant_override("margin_bottom", 42)
		move_rows.columns = 2
		move_scroll.custom_minimum_size.y = 500


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
		card.custom_minimum_size = Vector2(
			300 if GameFlow.phone_mode else 340,
			200 if GameFlow.phone_mode else 220
		)
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
	get_tree().change_scene_to_file(
		GameFlow.PHONE_ENERKORO_BUILDER_SCENE
		if GameFlow.phone_mode
		else "res://scenes/ui/EnergyDiceVisualBuilderUI.tscn"
	)


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
	if GameFlow.phone_mode:
		GameFlow.open_phone_mode_menu()
	else:
		GameFlow.exit_phone_mode()


func _present_player_two_handoff() -> void:
	var overlay := ColorRect.new()
	overlay.name = "PlayerHandoffOverlay"
	overlay.color = Color(0.018, 0.027, 0.047, 0.98)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(
		minf(520.0, maxf(300.0, get_viewport_rect().size.x - 40.0)),
		340.0
	)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 26)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = LocalizationService.tr_format(
		"battle.local.handoff_title", {"player": 2}, "PASS TO PLAYER {player}"
	)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	box.add_child(heading)

	var hint := Label.new()
	hint.text = LocalizationService.tr_key(
		"battle.local.handoff_hint", "Only the active player should look at the screen."
	)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 18)
	box.add_child(hint)

	var ready_button := Button.new()
	ready_button.text = LocalizationService.tr_format(
		"battle.local.ready", {"player": 2}, "PLAYER {player} READY"
	)
	ready_button.custom_minimum_size = Vector2(0, 68)
	ready_button.add_theme_font_size_override("font_size", 20)
	ready_button.pressed.connect(overlay.queue_free)
	box.add_child(ready_button)
	ready_button.grab_focus()


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
	ready_message.visible = true
	ready_message.text = LocalizationService.tr_key(
		"preparation.local.ready_message",
		"Both players are configured. Start the battle?"
	)
	reveal_cards.visible = false
	ready_back_button.text = LocalizationService.tr_key(
		"common.back", "Back"
	)
	start_battle_button.text = LocalizationService.tr_key(
		"preparation.start_battle", "Start Battle"
	)
	start_battle_button.grab_focus()


func _reveal_matchup_and_start() -> void:
	if matchup_reveal_started:
		return
	matchup_reveal_started = true
	ready_back_button.disabled = true
	start_battle_button.disabled = true
	ready_actions.visible = false
	ready_message.visible = false
	ready_title.text = LocalizationService.tr_key(
		"preparation.local.matchup_reveal",
		"MATCHUP REVEAL"
	)
	_build_reveal_cards()
	reveal_cards.visible = true
	await get_tree().create_timer(3.5).timeout
	GameFlow.open_battle()


func _build_reveal_cards() -> void:
	for child: Node in reveal_cards.get_children():
		child.queue_free()
	var player_one: Variant = PLAYER_LOADOUT_PROVIDER.load_player_loadout()
	var player_two: Variant = PLAYER_TWO_LOADOUT_PROVIDER.load_ai_loadout()
	if player_one == null or player_two == null:
		GameFlow.open_battle()
		return
	reveal_cards.add_child(_create_reveal_card(player_one, 1))
	reveal_cards.add_child(_create_reveal_card(player_two, 2))


func _create_reveal_card(loadout: Variant, player_number: int) -> PanelContainer:
	var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(String(loadout.pokemon_id))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 250)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.082, 0.13, 0.98)
	style.border_color = Color("4baeff") if player_number == 1 else Color("ff557f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	var heading := Label.new()
	heading.text = LocalizationService.tr_format(
		"preparation.local.player_card",
		{"player": player_number},
		"PLAYER {player}"
	)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	content.add_child(heading)

	var identity := HBoxContainer.new()
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override("separation", 14)
	content.add_child(identity)
	var portrait: Control = PORTRAIT.instantiate()
	portrait.custom_minimum_size = Vector2(130, 130)
	identity.add_child(portrait)
	portrait.setup(pokemon, true)
	var details := VBoxContainer.new()
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 7)
	identity.add_child(details)
	var name_label := Label.new()
	name_label.text = _loadout_pokemon_name(loadout)
	name_label.add_theme_font_size_override("font_size", 24)
	details.add_child(name_label)
	var type_icons := HBoxContainer.new()
	details.add_child(type_icons)
	ATTRIBUTE_ICONS.show_type(
		type_icons,
		StringName(String(pokemon.get("pokemon_type", ""))),
		30
	)
	var weakness_icons := HBoxContainer.new()
	details.add_child(weakness_icons)
	ATTRIBUTE_ICONS.show_weaknesses(weakness_icons, pokemon, 30)

	var moves := Label.new()
	moves.text = _loadout_move_names(loadout)
	moves.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	moves.add_theme_font_size_override("font_size", 17)
	content.add_child(moves)
	return panel


func _loadout_pokemon_name(loadout: Variant) -> String:
	var pokemon: Variant = database.get_pokemon(loadout.pokemon_id)
	if pokemon == null:
		return String(loadout.pokemon_id)
	return GameContentLocalizationService.localize_pokemon(pokemon)


func _loadout_move_names(loadout: Variant) -> String:
	var names: Array[String] = []
	for move_id: Variant in loadout.move_card_ids:
		var move_card: Variant = database.get_move_card(StringName(move_id))
		if move_card != null:
			names.append(GameContentLocalizationService.localize_move(move_card))
	return " • ".join(names)


func _return_to_player_two_setup() -> void:
	GameFlow.local_battle_setup_phase = &"player2_pokemon"
	get_tree().reload_current_scene()
