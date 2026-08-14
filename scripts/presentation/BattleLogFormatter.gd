extends RefCounted


const PLAYER_COLOR: String = "#58C7FF"
const ENEMY_COLOR: String = "#FF9B54"
const DAMAGE_COLOR: String = "#FF6868"
const HEAL_COLOR: String = "#63D985"
const STATUS_COLOR: String = "#D29BFF"
const ENERGY_COLOR: String = "#FFD85A"
const SYSTEM_COLOR: String = "#AAB3C5"
const RESULT_COLOR: String = "#FFFFFF"


static func format_event(
	event: Variant,
	database: Node
) -> String:
	if event == null:
		return ""

	var event_type: StringName = StringName(
		event.event_type
	)
	var payload: Dictionary = event.payload

	match event_type:
		&"battle_started":
			return _system_line(
                "Battle started."
			)

		&"move_selected":
			var actor_name: String = _participant_name(
				StringName(
					event.source_participant_id
				)
			)
			var move_name: String = String(
				payload.get("move_card_id", "")
			)
			var card: Variant = database.get_move_card(
				StringName(
					payload.get("move_card_id", "")
				)
			)

			if card != null:
				move_name = String(card.display_name)

			return "%s used [b]%s[/b]." % [
				_actor_tag(
					StringName(
						event.source_participant_id
					),
					actor_name
				),
				_escape_bbcode(move_name)
			]

		&"energy_checked":
			var success: bool = bool(
				payload.get("success", false)
			)

			if success:
				return (
                    "[color=%s]Energy check passed.[/color]"
					% ENERGY_COLOR
				)

			return (
                "[color=%s]Energy check failed.[/color]"
				% DAMAGE_COLOR
			)

		&"outcome_triggered":
			return (
                "[color=%s]Charakoro outcome:[/color] [b]%s[/b]"
				% [
					ENERGY_COLOR,
					_escape_bbcode(
						String(
							payload.get(
								"orientation",
                                ""
							)
						)
					)
				]
			)

		&"damage_applied":
			return "%s took [color=%s][b]%d damage[/b][/color] — HP %d." % [
				_actor_tag(
					StringName(
						event.target_participant_id
					),
					_participant_name(
						StringName(
							event.target_participant_id
						)
					)
				),
				DAMAGE_COLOR,
				int(
					payload.get(
						"applied_amount",
						0
					)
				),
				int(
					payload.get(
						"remaining_hp",
						0
					)
				)
			]

		&"hp_restored":
			return "%s restored [color=%s][b]%d HP[/b][/color] — HP %d." % [
				_actor_tag(
					StringName(
						event.target_participant_id
					),
					_participant_name(
						StringName(
							event.target_participant_id
						)
					)
				),
				HEAL_COLOR,
				int(payload.get("amount", 0)),
				int(
					payload.get(
						"remaining_hp",
						0
					)
				)
			]

		&"status_added":
			return "%s gained [color=%s][b]%s[/b] (%d)[/color]." % [
				_actor_tag(
					StringName(
						event.target_participant_id
					),
					_participant_name(
						StringName(
							event.target_participant_id
						)
					)
				),
				STATUS_COLOR,
				_escape_bbcode(
					String(
						payload.get(
							"status_type",
                            ""
						)
					)
				),
				int(payload.get("value", 0))
			]

		&"turn_changed":
			var current_id: StringName = StringName(
				payload.get(
					"current_participant_id",
					event.source_participant_id
				)
			)

			return (
                "[color=%s]Next turn:[/color] %s"
				% [
					SYSTEM_COLOR,
					_actor_tag(
						current_id,
						_participant_name(current_id)
					)
				]
			)

		&"battle_finished":
			var winner_id: StringName = StringName(
				payload.get(
					"winner_participant_id",
					event.source_participant_id
				)
			)

			return (
                "[color=%s][b]Battle finished — Winner: %s[/b][/color]"
				% [
					RESULT_COLOR,
					_actor_tag(
						winner_id,
						_participant_name(winner_id)
					)
				]
			)

		_:
			return ""


static func _actor_tag(
	participant_id: StringName,
	display_name: String
) -> String:
	var color: String = ENEMY_COLOR
	var prefix: String = "AI"

	if participant_id == &"player":
		color = PLAYER_COLOR
		prefix = "YOU"

	return "[color=%s][b][%s] %s[/b][/color]" % [
		color,
		prefix,
		_escape_bbcode(display_name)
	]


static func _participant_name(
	participant_id: StringName
) -> String:
	if participant_id == &"player":
		return "Player"

	if participant_id == &"enemy":
		return "Enemy"

	return String(participant_id)


static func _system_line(
	text: String
) -> String:
	return "[color=%s]%s[/color]" % [
		SYSTEM_COLOR,
		_escape_bbcode(text)
	]


static func _escape_bbcode(
	text: String
) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")
