extends Node

signal connection_state_changed(state: StringName)
signal room_changed(room: Dictionary)
signal matchmaking_state_changed(searching: bool)
signal server_capabilities_changed(capabilities: Array[String])
signal match_ready(players: Array)
signal battle_session_started(session: Dictionary)
signal turn_resolved(result: Dictionary)
signal match_ended(result: Dictionary)
signal server_error(code: String, message: String)

const DEFAULT_LOCAL_URL: String = "ws://127.0.0.1:10000/ws"
const SERVER_SETTING: String = "online/server_url"
const HEARTBEAT_INTERVAL_MSEC: int = 20000
const RECONNECT_DELAYS_MSEC: Array[int] = [500, 1500, 3000, 5000]

var socket: WebSocketPeer = WebSocketPeer.new()
var connection_state: StringName = &"disconnected"
var player_id: String = ""
var current_room: Dictionary = {}
var revealed_players: Array = []
var battle_session: Dictionary = {}
var server_url: String = ""
var last_heartbeat_msec: int = 0
var reconnect_token: String = ""
var resume_token: String = ""
var reconnect_attempt: int = 0
var reconnect_at_msec: int = 0
var intentional_disconnect: bool = false
var matchmaking_searching: bool = false
var server_capabilities: Array[String] = []


func _ready() -> void:
	set_process(false)


func get_default_server_url() -> String:
	return String(ProjectSettings.get_setting(SERVER_SETTING, DEFAULT_LOCAL_URL))


func connect_to_server(url: String = "") -> Error:
	if connection_state != &"disconnected":
		disconnect_from_server()
	server_url = url.strip_edges() if not url.strip_edges().is_empty() else get_default_server_url()
	intentional_disconnect = false
	resume_token = ""
	reconnect_attempt = 0
	return _open_socket()


func _open_socket() -> Error:
	socket = WebSocketPeer.new()
	var error: Error = socket.connect_to_url(server_url)
	if error != OK:
		if not resume_token.is_empty() and reconnect_attempt < RECONNECT_DELAYS_MSEC.size():
			reconnect_at_msec = (
				Time.get_ticks_msec()
				+ RECONNECT_DELAYS_MSEC[reconnect_attempt]
			)
			reconnect_attempt += 1
			_set_state(&"reconnecting")
			set_process(true)
			return error
		_set_state(&"disconnected")
		server_error.emit("connect_failed", error_string(error))
		return error
	_set_state(&"connecting")
	set_process(true)
	return OK


func disconnect_from_server() -> void:
	intentional_disconnect = true
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		socket.close(1000, "Client closed")
	current_room.clear()
	revealed_players.clear()
	battle_session.clear()
	player_id = ""
	reconnect_token = ""
	resume_token = ""
	reconnect_attempt = 0
	_set_matchmaking_searching(false)
	set_process(false)
	_set_state(&"disconnected")


func create_room(player_name: String) -> void:
	_send({"type": "create_room", "player_name": player_name})


func join_room(room_code: String, player_name: String) -> void:
	_send({
		"type": "join_room",
		"room_code": room_code.strip_edges().to_upper(),
		"player_name": player_name
	})


func join_random_queue(player_name: String) -> void:
	if not supports_capability("random_matchmaking"):
		server_error.emit(
			"random_matchmaking_unavailable",
			"Random VS requires the latest Online server deployment."
		)
		return
	_send({"type": "join_random_queue", "player_name": player_name})


func supports_capability(capability: String) -> bool:
	return server_capabilities.has(capability)


func leave_random_queue() -> void:
	_send({"type": "leave_random_queue"})
	_set_matchmaking_searching(false)


func leave_room() -> void:
	_send({"type": "leave_room"})
	current_room.clear()
	revealed_players.clear()
	battle_session.clear()
	room_changed.emit(current_room)


func submit_loadout(loadout: Dictionary) -> void:
	_send({"type": "submit_loadout", "loadout": loadout})


func set_room_rules(allow_repeated_fixed_energy: bool) -> void:
	_send({
		"type": "set_room_rules",
		"rules": {
			"allow_repeated_fixed_energy": allow_repeated_fixed_energy
		}
	})


func choose_move(move_id: String) -> void:
	_send({"type": "choose_move", "move_id": move_id})


func forfeit_match() -> void:
	_send({"type": "forfeit"})


func _process(_delta: float) -> void:
	if connection_state == &"reconnecting":
		if Time.get_ticks_msec() >= reconnect_at_msec:
			_open_socket()
		return
	socket.poll()
	var ready_state: WebSocketPeer.State = socket.get_ready_state()
	if ready_state == WebSocketPeer.STATE_OPEN:
		if connection_state != &"connected" and resume_token.is_empty():
			_set_state(&"connected")
		while socket.get_available_packet_count() > 0:
			_receive_packet(socket.get_packet())
		var now_msec: int = Time.get_ticks_msec()
		if now_msec - last_heartbeat_msec >= HEARTBEAT_INTERVAL_MSEC:
			last_heartbeat_msec = now_msec
			_send({"type": "ping", "sent_at": now_msec})
	elif ready_state == WebSocketPeer.STATE_CLOSED:
		var close_code: int = socket.get_close_code()
		var close_reason: String = socket.get_close_reason()
		if (
			not intentional_disconnect
			and not reconnect_token.is_empty()
			and not current_room.is_empty()
			and reconnect_attempt < RECONNECT_DELAYS_MSEC.size()
		):
			resume_token = reconnect_token
			reconnect_at_msec = (
				Time.get_ticks_msec()
				+ RECONNECT_DELAYS_MSEC[reconnect_attempt]
			)
			reconnect_attempt += 1
			_set_state(&"reconnecting")
			return
		_clear_online_session()
		set_process(false)
		_set_state(&"disconnected")
		if close_code != 1000 and close_code != -1:
			server_error.emit("connection_closed", close_reason)


func _receive_packet(packet: PackedByteArray) -> void:
	var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
	if not parsed is Dictionary:
		server_error.emit("invalid_message", "Server returned invalid JSON.")
		return
	var message: Dictionary = parsed
	match String(message.get("type", "")):
		"connected":
			player_id = String(message.get("player_id", ""))
			reconnect_token = String(message.get("reconnect_token", ""))
			_set_server_capabilities(Array(message.get("capabilities", [])))
			if not resume_token.is_empty():
				_send({
					"type": "resume_session",
					"reconnect_token": resume_token
				})
		"session_resumed":
			player_id = String(message.get("player_id", ""))
			reconnect_token = String(message.get("reconnect_token", resume_token))
			resume_token = ""
			reconnect_attempt = 0
			_set_server_capabilities(Array(message.get("capabilities", [])))
			_set_state(&"connected")
		"room_joined", "room_updated":
			_set_matchmaking_searching(false)
			current_room = Dictionary(message.get("room", {})).duplicate(true)
			room_changed.emit(current_room)
		"matchmaking_status":
			_set_matchmaking_searching(String(message.get("state", "idle")) == "searching")
		"room_left":
			_clear_room_state()
			room_changed.emit(current_room)
		"room_expired":
			_clear_room_state()
			room_changed.emit(current_room)
			server_error.emit(
				"room_expired",
				"The Online room expired after being inactive."
			)
		"match_ready":
			revealed_players = Array(message.get("players", [])).duplicate(true)
			match_ready.emit(revealed_players)
		"match_started":
			battle_session = Dictionary(message.get("match", {})).duplicate(true)
			battle_session["room_code"] = String(message.get("room_code", ""))
			battle_session["players"] = Array(message.get("players", [])).duplicate(true)
			battle_session_started.emit(battle_session)
		"turn_resolved":
			var previous_players: Array = Array(battle_session.get("players", [])).duplicate(true)
			battle_session = Dictionary(message.get("match", {})).duplicate(true)
			battle_session["room_code"] = String(message.get("room_code", ""))
			battle_session["players"] = previous_players
			turn_resolved.emit(Dictionary(message).duplicate(true))
		"match_ended":
			var previous_players: Array = Array(battle_session.get("players", [])).duplicate(true)
			battle_session = Dictionary(message.get("match", {})).duplicate(true)
			battle_session["room_code"] = String(message.get("room_code", ""))
			battle_session["players"] = previous_players
			match_ended.emit(Dictionary(message).duplicate(true))
		"opponent_reconnecting", "opponent_reconnected":
			server_error.emit(
				String(message.get("type", "online_notice")),
				String(message.get("message", ""))
			)
		"error":
			if (
				String(message.get("code", "")) == "unknown_message"
				and matchmaking_searching
			):
				_set_matchmaking_searching(false)
				server_error.emit(
					"random_matchmaking_unavailable",
					"Random VS requires the latest Online server deployment."
				)
				return
			if String(message.get("code", "")) == "resume_failed":
				_clear_online_session()
			server_error.emit(
				String(message.get("code", "server_error")),
				String(message.get("message", "Server error."))
			)


func _send(message: Dictionary) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		server_error.emit("not_connected", "Connect to the server first.")
		return
	socket.send_text(JSON.stringify(message))


func _set_state(next_state: StringName) -> void:
	if connection_state == next_state:
		return
	connection_state = next_state
	connection_state_changed.emit(connection_state)


func _set_matchmaking_searching(searching: bool) -> void:
	if matchmaking_searching == searching:
		return
	matchmaking_searching = searching
	matchmaking_state_changed.emit(matchmaking_searching)


func _set_server_capabilities(raw_capabilities: Array) -> void:
	var next_capabilities: Array[String] = []
	for raw_capability: Variant in raw_capabilities:
		var capability: String = String(raw_capability)
		if not capability.is_empty() and not next_capabilities.has(capability):
			next_capabilities.append(capability)
	if server_capabilities == next_capabilities:
		return
	server_capabilities = next_capabilities
	server_capabilities_changed.emit(server_capabilities.duplicate())


func _clear_room_state() -> void:
	current_room.clear()
	revealed_players.clear()
	battle_session.clear()


func _clear_online_session() -> void:
	_clear_room_state()
	_set_matchmaking_searching(false)
	_set_server_capabilities([])
	player_id = ""
	reconnect_token = ""
	resume_token = ""
	reconnect_attempt = 0
	room_changed.emit(current_room)
