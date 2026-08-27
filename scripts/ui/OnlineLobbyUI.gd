extends Control

const PLAKORO_THEME: Script = preload(
	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
)
const MOVE_AUTHORING: Script = preload("res://scripts/content/MoveCardAuthoringService.gd")
const ICONS: Script = preload("res://scripts/presentation/PlakoroIconService.gd")
const DEFAULT_ONLINE_PLAYER_NAME: String = "Player"
const ENERGY_CODES: Dictionary = {
	"A": &"grass", "B": &"fire", "C": &"water",
	"D": &"electric", "E": &"psychic", "F": &"fighting",
	"G": &"dark", "H": &"steel", "I": &"flying",
}

var _join_code_entry_visible: bool = false

@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var status_label: Label = %StatusLabel
@onready var server_label: Label = %ServerLabel
@onready var server_url_edit: LineEdit = %ServerUrlEdit
@onready var connect_button: Button = %ConnectButton
@onready var create_room_button: Button = %CreateRoomButton
@onready var join_label: Label = %JoinLabel
@onready var open_join_button: Button = %OpenJoinButton
@onready var join_row: VBoxContainer = %JoinRow
@onready var room_code_edit: LineEdit = %RoomCodeEdit
@onready var code_selection_label: Label = %CodeSelectionLabel
@onready var code_display: HBoxContainer = %CodeDisplay
@onready var energy_choice_label: Label = %EnergyChoiceLabel
@onready var energy_palette: GridContainer = %EnergyPalette
@onready var code_back_button: Button = %CodeBackButton
@onready var code_clear_button: Button = %CodeClearButton
@onready var join_room_button: Button = %JoinRoomButton
@onready var room_panel: PanelContainer = %RoomPanel
@onready var room_code_label: Label = %RoomCodeLabel
@onready var room_energy_code: HBoxContainer = %RoomEnergyCode
@onready var players_label: Label = %PlayersLabel
@onready var first_turn_label: Label = %FirstTurnLabel
@onready var repeat_fixed_energy_toggle: CheckButton = %RepeatFixedEnergyToggle
@onready var configure_button: Button = %ConfigureButton
@onready var turn_panel: PanelContainer = %TurnPanel
@onready var turn_label: Label = %TurnLabel
@onready var move_option: OptionButton = %MoveOption
@onready var submit_move_button: Button = %SubmitMoveButton
@onready var turn_result_label: Label = %TurnResultLabel
@onready var foundation_label: Label = %FoundationLabel
@onready var bottom_row: HBoxContainer = %BottomRow
@onready var back_button: Button = %BackButton
@onready var leave_room_button: Button = %LeaveRoomButton


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)
	server_url_edit.text = OnlineBattleService.get_default_server_url()
	connect_button.pressed.connect(_toggle_connection)
	create_room_button.pressed.connect(_create_room)
	open_join_button.pressed.connect(_open_join_code_entry)
	join_room_button.pressed.connect(_join_room)
	code_back_button.pressed.connect(_remove_code_energy)
	code_clear_button.pressed.connect(_clear_code)
	leave_room_button.pressed.connect(OnlineBattleService.leave_room)
	repeat_fixed_energy_toggle.toggled.connect(_on_repeat_fixed_energy_toggled)
	configure_button.pressed.connect(GameFlow.open_online_loadout_setup)
	submit_move_button.pressed.connect(_submit_selected_move)
	back_button.pressed.connect(_go_back)
	room_code_edit.text_changed.connect(_normalize_room_code)
	_build_energy_palette()
	_refresh_energy_code_display()
	OnlineBattleService.connection_state_changed.connect(_on_connection_state_changed)
	OnlineBattleService.room_changed.connect(_on_room_changed)
	OnlineBattleService.server_error.connect(_on_server_error)
	OnlineBattleService.match_ready.connect(_on_match_ready)
	OnlineBattleService.battle_session_started.connect(_on_battle_session_started)
	OnlineBattleService.turn_resolved.connect(_on_turn_resolved)
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_localized_text()
	_on_connection_state_changed(OnlineBattleService.connection_state)
	_on_room_changed(OnlineBattleService.current_room)
	if not OnlineBattleService.revealed_players.is_empty():
		_on_match_ready(OnlineBattleService.revealed_players)
	if not OnlineBattleService.battle_session.is_empty():
		_on_battle_session_started(OnlineBattleService.battle_session)


func _exit_tree() -> void:
	if OnlineBattleService.connection_state_changed.is_connected(_on_connection_state_changed):
		OnlineBattleService.connection_state_changed.disconnect(_on_connection_state_changed)
	if OnlineBattleService.room_changed.is_connected(_on_room_changed):
		OnlineBattleService.room_changed.disconnect(_on_room_changed)
	if OnlineBattleService.server_error.is_connected(_on_server_error):
		OnlineBattleService.server_error.disconnect(_on_server_error)
	if OnlineBattleService.match_ready.is_connected(_on_match_ready):
		OnlineBattleService.match_ready.disconnect(_on_match_ready)
	if OnlineBattleService.battle_session_started.is_connected(_on_battle_session_started):
		OnlineBattleService.battle_session_started.disconnect(_on_battle_session_started)
	if OnlineBattleService.turn_resolved.is_connected(_on_turn_resolved):
		OnlineBattleService.turn_resolved.disconnect(_on_turn_resolved)


func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var portrait: bool = GameFlow.phone_mode or viewport_size.x < 700.0
	panel.custom_minimum_size = Vector2(
		minf(700.0, viewport_size.x - 32.0),
		minf(720.0, viewport_size.y - 32.0)
	)
	energy_palette.columns = 3 if portrait else 9
	server_url_edit.custom_minimum_size.y = 58.0 if portrait else 52.0


func _apply_localized_text() -> void:
	title_label.text = LocalizationService.tr_key("online.title", "ONLINE VS")
	subtitle_label.text = LocalizationService.tr_key(
		"online.subtitle", "Create a private room or join with a room code."
	)
	server_label.text = LocalizationService.tr_key("online.server", "Server")
	create_room_button.text = LocalizationService.tr_key(
		"online.create_room", "CREATE PRIVATE ROOM"
	)
	join_label.text = LocalizationService.tr_key("online.join_room", "Join Room")
	open_join_button.text = LocalizationService.tr_key("online.join_room", "JOIN ROOM")
	code_selection_label.text = LocalizationService.tr_key(
		"online.selected_energy_code", "SELECTED ROOM CODE"
	)
	energy_choice_label.text = LocalizationService.tr_key(
		"online.choose_code_energy", "CHOOSE AN ENERGY"
	)
	join_room_button.text = LocalizationService.tr_key("online.join", "JOIN")
	code_back_button.text = LocalizationService.tr_key("common.delete_short", "DEL")
	code_clear_button.text = LocalizationService.tr_key("common.clear", "CLEAR")
	leave_room_button.text = LocalizationService.tr_key("online.leave", "LEAVE ROOM")
	configure_button.text = LocalizationService.tr_key(
		"online.configure", "CONFIGURE MY LOADOUT"
	)
	repeat_fixed_energy_toggle.text = LocalizationService.tr_key(
		"online.allow_repeated_fixed_energy", "ALLOW REPEATED FIXED ENERGY"
	)
	submit_move_button.text = LocalizationService.tr_key("online.submit_move", "USE MOVE")
	back_button.text = LocalizationService.tr_key("common.back", "BACK")
	foundation_label.text = LocalizationService.tr_key(
		"online.foundation_notice", "LOADOUT SYNC READY • ONLINE BATTLE START COMING NEXT"
	)
	_refresh_connection_text()
	_refresh_room_text()


func _toggle_connection() -> void:
	if OnlineBattleService.connection_state == &"disconnected":
		OnlineBattleService.connect_to_server(server_url_edit.text)
	else:
		OnlineBattleService.disconnect_from_server()


func _create_room() -> void:
	OnlineBattleService.create_room(DEFAULT_ONLINE_PLAYER_NAME)


func _open_join_code_entry() -> void:
	_join_code_entry_visible = true
	_apply_lobby_page_visibility(OnlineBattleService.current_room)


func _close_join_code_entry() -> void:
	_join_code_entry_visible = false
	_apply_lobby_page_visibility(OnlineBattleService.current_room)


func _join_room() -> void:
	if room_code_edit.text.length() != 6:
		_on_server_error("invalid_room_code", LocalizationService.tr_key(
			"online.invalid_code", "Enter a six-character room code."
		))
		return
	OnlineBattleService.join_room(
		room_code_edit.text,
		DEFAULT_ONLINE_PLAYER_NAME
	)


func _normalize_room_code(value: String) -> void:
	var normalized: String = value.to_upper()
	if normalized != value:
		room_code_edit.text = normalized
		room_code_edit.caret_column = normalized.length()
	_refresh_energy_code_display()


func _build_energy_palette() -> void:
	for code: String in ENERGY_CODES:
		var energy: StringName = ENERGY_CODES[code]
		var button := Button.new()
		button.custom_minimum_size = Vector2(54, 54)
		button.icon = ICONS.load_energy_icon(energy)
		button.expand_icon = true
		button.tooltip_text = String(energy).capitalize()
		button.pressed.connect(_append_code_energy.bind(code))
		energy_palette.add_child(button)


func _append_code_energy(code: String) -> void:
	if room_code_edit.text.length() >= 6:
		return
	room_code_edit.text += code
	_refresh_energy_code_display()


func _remove_code_energy() -> void:
	room_code_edit.text = room_code_edit.text.left(maxi(0, room_code_edit.text.length() - 1))
	_refresh_energy_code_display()


func _clear_code() -> void:
	room_code_edit.text = ""
	_refresh_energy_code_display()


func _refresh_energy_code_display() -> void:
	_render_energy_code(code_display, room_code_edit.text, true)
	join_room_button.disabled = (
		OnlineBattleService.connection_state != &"connected"
		or room_code_edit.text.length() != 6
	)


func _render_energy_code(container: HBoxContainer, code: String, show_empty: bool) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
	for index: int in 6:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(54, 54)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.focus_mode = Control.FOCUS_NONE
		slot.expand_icon = true
		var code_character: String = code.substr(index, 1) if index < code.length() else ""
		if ENERGY_CODES.has(code_character):
			var energy: StringName = ENERGY_CODES[code_character]
			slot.icon = ICONS.load_energy_icon(energy)
			slot.tooltip_text = String(energy).capitalize()
		elif show_empty:
			slot.text = str(index + 1)
			slot.modulate = Color(1.0, 1.0, 1.0, 0.58)
		else:
			slot.visible = false
		container.add_child(slot)


func _on_connection_state_changed(_state: StringName) -> void:
	var connected: bool = OnlineBattleService.connection_state == &"connected"
	var connecting: bool = OnlineBattleService.connection_state == &"connecting"
	server_url_edit.editable = not connected and not connecting
	connect_button.disabled = connecting
	create_room_button.disabled = not connected
	open_join_button.disabled = not connected
	join_room_button.disabled = not connected or room_code_edit.text.length() != 6
	_refresh_connection_text()
	_apply_lobby_page_visibility(OnlineBattleService.current_room)


func _refresh_connection_text() -> void:
	match OnlineBattleService.connection_state:
		&"connected":
			status_label.text = LocalizationService.tr_key("online.connected", "CONNECTED")
			connect_button.text = LocalizationService.tr_key("online.disconnect", "DISCONNECT")
		&"connecting":
			status_label.text = LocalizationService.tr_key("online.connecting", "CONNECTING...")
			connect_button.text = LocalizationService.tr_key("online.connect", "CONNECT")
		&"reconnecting":
			status_label.text = LocalizationService.tr_key("online.reconnecting", "RECONNECTING...")
			connect_button.text = LocalizationService.tr_key("online.disconnect", "DISCONNECT")
		_:
			status_label.text = LocalizationService.tr_key("online.disconnected", "DISCONNECTED")
			connect_button.text = LocalizationService.tr_key("online.connect", "CONNECT")


func _on_room_changed(room: Dictionary) -> void:
	if not room.is_empty():
		_join_code_entry_visible = false
	room_panel.visible = not room.is_empty()
	leave_room_button.visible = not room.is_empty()
	_apply_lobby_page_visibility(room)
	_refresh_configure_button(room)
	var rules: Dictionary = Dictionary(room.get("rules", {}))
	var allow_repeated: bool = bool(rules.get("allow_repeated_fixed_energy", false))
	GameFlow.free_mode_allow_repeated_fixed_energy = allow_repeated
	repeat_fixed_energy_toggle.set_pressed_no_signal(allow_repeated)
	repeat_fixed_energy_toggle.visible = not room.is_empty()
	repeat_fixed_energy_toggle.disabled = (
		room.is_empty()
		or String(room.get("host_id", "")) != OnlineBattleService.player_id
		or bool(room.get("match_started", false))
	)
	_refresh_room_text()


func _apply_lobby_page_visibility(room: Dictionary) -> void:
	var room_empty: bool = room.is_empty()
	var show_actions: bool = room_empty and not _join_code_entry_visible
	var show_server_controls: bool = (
		show_actions
		and OnlineBattleService.connection_state != &"connected"
	)
	var back_parent: Container = join_row if room_empty and _join_code_entry_visible else bottom_row
	if back_button.get_parent() != back_parent:
		back_button.reparent(back_parent)
		if back_parent == bottom_row:
			bottom_row.move_child(back_button, 0)
	status_label.get_parent().visible = show_actions
	server_label.visible = show_server_controls
	server_url_edit.get_parent().visible = show_server_controls
	create_room_button.visible = show_actions
	open_join_button.visible = show_actions
	join_label.visible = room_empty and _join_code_entry_visible
	join_row.visible = room_empty and _join_code_entry_visible
	foundation_label.visible = false


func _on_repeat_fixed_energy_toggled(enabled: bool) -> void:
	OnlineBattleService.set_room_rules(enabled)


func _refresh_configure_button(room: Dictionary) -> void:
	configure_button.visible = false
	if room.is_empty() or Array(room.get("players", [])).size() < 2:
		return
	for player_value: Variant in Array(room.get("players", [])):
		var player: Dictionary = Dictionary(player_value)
		if String(player.get("id", "")) != OnlineBattleService.player_id:
			continue
		configure_button.visible = true
		configure_button.disabled = bool(player.get("ready", false))
		if configure_button.disabled:
			configure_button.text = LocalizationService.tr_key(
				"online.ready_waiting", "READY • WAITING FOR OPPONENT"
			)
		return


func _refresh_room_text() -> void:
	var room: Dictionary = OnlineBattleService.current_room
	if room.is_empty():
		return
	room_code_label.text = LocalizationService.tr_format(
		"online.room_code", {"code": String(room.get("code", "------"))}, "ROOM: {code}"
	)
	room_code_label.visible = false
	_render_energy_code(room_energy_code, String(room.get("code", "")), false)
	var names: PackedStringArray = []
	for player_value: Variant in Array(room.get("players", [])):
		var player: Dictionary = Dictionary(player_value)
		names.append(String(player.get("name", "Player")))
	players_label.text = "  VS  ".join(names) if names.size() == 2 else LocalizationService.tr_key(
		"online.waiting_player", "Waiting for Player 2..."
	)


func _on_match_ready(players: Array) -> void:
	var pokemon_names: PackedStringArray = []
	for player_value: Variant in players:
		var player: Dictionary = Dictionary(player_value)
		var loadout: Dictionary = Dictionary(player.get("loadout", {}))
		pokemon_names.append("%s: %s" % [
			String(player.get("name", "Player")),
			String(loadout.get("pokemon_id", "?"))
		])
	status_label.text = LocalizationService.tr_key(
		"online.both_ready", "BOTH PLAYERS READY • LOADOUTS SYNCHRONIZED"
	)
	players_label.text = "  VS  ".join(pokemon_names)
	configure_button.visible = false


func _on_battle_session_started(session: Dictionary) -> void:
	var first_player_id: String = String(session.get("current_player_id", ""))
	var first_player_name: String = "Player"
	for player_value: Variant in Array(session.get("players", [])):
		var player: Dictionary = Dictionary(player_value)
		if String(player.get("id", "")) == first_player_id:
			first_player_name = String(player.get("name", "Player"))
			break
	first_turn_label.visible = true
	first_turn_label.text = LocalizationService.tr_format(
		"online.first_turn",
		{"player": first_player_name},
		"{player} GOES FIRST"
	)
	foundation_label.text = LocalizationService.tr_format(
		"online.session_ready",
		{"match": String(session.get("id", "")).left(8).to_upper()},
		"ONLINE BATTLE SESSION {match} READY"
	)
	turn_panel.visible = false
	GameFlow.open_battle.call_deferred()


func _populate_move_options() -> void:
	move_option.clear()
	var loadout: Dictionary = _local_loadout()
	for move_id_value: Variant in Array(loadout.get("move_card_ids", [])):
		var move_id: String = String(move_id_value)
		var move: Dictionary = MOVE_AUTHORING.load_by_id(move_id)
		var name_id: String = String(move.get("move_name_id", move_id))
		var fallback: String = String(move.get("display_name", move_id))
		move_option.add_item(GameContentLocalizationService.text("move", name_id, "name", fallback))
		move_option.set_item_metadata(move_option.item_count - 1, move_id)


func _local_loadout() -> Dictionary:
	for player_value: Variant in OnlineBattleService.revealed_players:
		var player: Dictionary = Dictionary(player_value)
		if String(player.get("id", "")) == OnlineBattleService.player_id:
			return Dictionary(player.get("loadout", {}))
	return {}


func _refresh_turn_controls() -> void:
	var session: Dictionary = OnlineBattleService.battle_session
	if session.is_empty():
		turn_panel.visible = false
		return
	var finished: bool = String(session.get("phase", "")) == "finished"
	var my_turn: bool = String(session.get("current_player_id", "")) == OnlineBattleService.player_id
	move_option.disabled = finished or not my_turn
	submit_move_button.disabled = finished or not my_turn or move_option.item_count == 0
	if finished:
		var won: bool = String(session.get("winner_id", "")) == OnlineBattleService.player_id
		turn_label.text = LocalizationService.tr_key(
			"online.you_win" if won else "online.you_lose", "YOU WIN" if won else "YOU LOSE"
		)
	elif my_turn:
		turn_label.text = LocalizationService.tr_key("online.your_turn", "YOUR TURN • CHOOSE A MOVE")
	else:
		turn_label.text = LocalizationService.tr_key("online.opponent_turn", "OPPONENT'S TURN • WAITING")


func _submit_selected_move() -> void:
	if move_option.selected < 0:
		return
	submit_move_button.disabled = true
	OnlineBattleService.choose_move(String(move_option.get_item_metadata(move_option.selected)))


func _on_turn_resolved(result: Dictionary) -> void:
	var lines: PackedStringArray = []
	var move_id: String = String(result.get("move_id", ""))
	var move: Dictionary = MOVE_AUTHORING.load_by_id(move_id)
	var name_id: String = String(move.get("move_name_id", result.get("move_name_id", move_id)))
	var move_name: String = GameContentLocalizationService.text(
		"move", name_id, "name", String(move.get("display_name", move_id))
	)
	lines.append(LocalizationService.tr_format(
		"online.used_move", {"move": move_name}, "USED {move}"
	))
	if not bool(result.get("energy_met", false)):
		lines.append(LocalizationService.tr_key("online.energy_failed", "ENERKORO ENERGY FAILED • ATTACK FAILED"))
	else:
		lines.append(LocalizationService.tr_key("online.energy_ok", "ENERKORO ENERGY CONFIRMED"))
		lines.append(LocalizationService.tr_format(
			"online.charakoro_result",
			{"result": String(result.get("charakoro_orientation", "")), "bonus": int(result.get("charakoro_bonus", 0))},
			"CHARAKORO {result} • +{bonus}"
		))
		var weakness_bonus: int = int(result.get("weakness_bonus", 0))
		if weakness_bonus > 0:
			lines.append(LocalizationService.tr_format(
				"online.weakness_bonus", {"bonus": weakness_bonus}, "WEAKNESS • +{bonus}"
			))
		lines.append(LocalizationService.tr_format(
			"online.damage_result", {"damage": int(result.get("damage", 0))}, "ATTACK DEALT {damage} DAMAGE"
		))
	turn_result_label.text = "\n".join(lines)
	_refresh_turn_controls()


func _on_server_error(_code: String, message: String) -> void:
	status_label.text = message


func _go_back() -> void:
	if _join_code_entry_visible and OnlineBattleService.current_room.is_empty():
		_close_join_code_entry()
		return
	OnlineBattleService.disconnect_from_server()
	if GameFlow.phone_mode:
		GameFlow.open_phone_mode_menu()
	else:
		GameFlow.exit_phone_mode()


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
