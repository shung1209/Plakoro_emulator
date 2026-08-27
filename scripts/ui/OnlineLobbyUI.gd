extends Control

const PLAKORO_THEME: Script = preload(
	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
)
const MOVE_AUTHORING: Script = preload("res://scripts/content/MoveCardAuthoringService.gd")
const DEFAULT_ONLINE_PLAYER_NAME: String = "Player"
const IOS_WEB_PROMPT_COOLDOWN_MS: int = 750

var _ios_web_input: bool = false
var _last_ios_prompt_ms: int = -IOS_WEB_PROMPT_COOLDOWN_MS

@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var status_label: Label = %StatusLabel
@onready var server_label: Label = %ServerLabel
@onready var server_url_edit: LineEdit = %ServerUrlEdit
@onready var connect_button: Button = %ConnectButton
@onready var create_room_button: Button = %CreateRoomButton
@onready var join_label: Label = %JoinLabel
@onready var room_code_edit: LineEdit = %RoomCodeEdit
@onready var join_room_button: Button = %JoinRoomButton
@onready var room_panel: PanelContainer = %RoomPanel
@onready var room_code_label: Label = %RoomCodeLabel
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
@onready var back_button: Button = %BackButton
@onready var leave_room_button: Button = %LeaveRoomButton


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)
	_ios_web_input = _is_ios_web_browser()
	server_url_edit.text = OnlineBattleService.get_default_server_url()
	connect_button.pressed.connect(_toggle_connection)
	create_room_button.pressed.connect(_create_room)
	join_room_button.pressed.connect(_join_room)
	leave_room_button.pressed.connect(OnlineBattleService.leave_room)
	repeat_fixed_energy_toggle.toggled.connect(_on_repeat_fixed_energy_toggled)
	configure_button.pressed.connect(GameFlow.open_online_loadout_setup)
	submit_move_button.pressed.connect(_submit_selected_move)
	back_button.pressed.connect(_go_back)
	room_code_edit.text_changed.connect(_normalize_room_code)
	room_code_edit.gui_input.connect(_on_room_code_gui_input)
	room_code_edit.virtual_keyboard_enabled = true
	room_code_edit.virtual_keyboard_show_on_focus = true
	room_code_edit.focus_mode = Control.FOCUS_ALL
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
	join_room_button.text = LocalizationService.tr_key("online.join", "JOIN")
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


func _on_room_code_gui_input(event: InputEvent) -> void:
	# Web exports receive an iPhone tap through the canvas before LineEdit can
	# reliably acquire focus. Grabbing it during that same user gesture lets
	# Godot's hidden Web input open the iOS virtual keyboard.
	var pressed: bool = (
		(event is InputEventScreenTouch and event.pressed)
		or (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		)
	)
	if pressed and _ios_web_input:
		_open_ios_room_code_prompt()
		accept_event()
		return
	if pressed and not room_code_edit.has_focus():
		room_code_edit.grab_focus()
	if pressed and DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_show(
			room_code_edit.text,
			room_code_edit.get_global_rect(),
			DisplayServer.KEYBOARD_TYPE_DEFAULT,
			room_code_edit.max_length,
			room_code_edit.caret_column,
			room_code_edit.caret_column
		)


func _is_ios_web_browser() -> bool:
	if not OS.has_feature("web"):
		return false
	var detected: Variant = JavaScriptBridge.eval(
		"/iPhone|iPad|iPod/.test(navigator.userAgent) || "
		+ "(navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)",
		true
	)
	return bool(detected)


func _open_ios_room_code_prompt() -> void:
	# All iOS browsers use WebKit. Some versions do not expose Godot's hidden
	# canvas input to the keyboard, so use a native prompt from the tap event.
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_ios_prompt_ms < IOS_WEB_PROMPT_COOLDOWN_MS:
		return
	_last_ios_prompt_ms = now_ms
	var prompt_text: String = LocalizationService.tr_key(
		"online.enter_room_code", "Enter the six-character room code."
	)
	var script: String = "window.prompt(%s, %s)" % [
		JSON.stringify(prompt_text),
		JSON.stringify(room_code_edit.text),
	]
	var entered_value: Variant = JavaScriptBridge.eval(script, true)
	if entered_value == null:
		return
	var entered: String = String(entered_value).strip_edges().to_upper()
	var cleaned: String = ""
	for character: String in entered:
		if character.is_valid_identifier() or character.is_valid_int():
			cleaned += character
	room_code_edit.text = cleaned.left(6)
	room_code_edit.caret_column = room_code_edit.text.length()


func _on_connection_state_changed(_state: StringName) -> void:
	var connected: bool = OnlineBattleService.connection_state == &"connected"
	var connecting: bool = OnlineBattleService.connection_state == &"connecting"
	server_url_edit.editable = not connected and not connecting
	connect_button.disabled = connecting
	create_room_button.disabled = not connected
	join_room_button.disabled = not connected
	_refresh_connection_text()


func _refresh_connection_text() -> void:
	match OnlineBattleService.connection_state:
		&"connected":
			status_label.text = LocalizationService.tr_key("online.connected", "CONNECTED")
			connect_button.text = LocalizationService.tr_key("online.disconnect", "DISCONNECT")
		&"connecting":
			status_label.text = LocalizationService.tr_key("online.connecting", "CONNECTING...")
			connect_button.text = LocalizationService.tr_key("online.connect", "CONNECT")
		_:
			status_label.text = LocalizationService.tr_key("online.disconnected", "DISCONNECTED")
			connect_button.text = LocalizationService.tr_key("online.connect", "CONNECT")


func _on_room_changed(room: Dictionary) -> void:
	room_panel.visible = not room.is_empty()
	leave_room_button.visible = not room.is_empty()
	create_room_button.visible = room.is_empty()
	join_label.visible = room.is_empty()
	room_code_edit.get_parent().visible = room.is_empty()
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
	OnlineBattleService.disconnect_from_server()
	if GameFlow.phone_mode:
		GameFlow.open_phone_mode_menu()
	else:
		GameFlow.exit_phone_mode()


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
