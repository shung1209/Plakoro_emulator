extends RefCounted


var turn_number: int = 0
var actor_participant_id: StringName = &""
var move_card_id: StringName = &""

var energy_counts: Dictionary = {}
var kyokoro_orientation: StringName = &""

var expected_success: bool = false
var expected_energy_sufficient: bool = false
var expected_applied_damage: int = 0

var expected_player_hp: int = 0
var expected_enemy_hp: int = 0
var expected_next_participant_id: StringName = &""

var command_count: int = 0
var event_count: int = 0


func to_dictionary() -> Dictionary:
    return {
        "turn_number": turn_number,
        "actor_participant_id": String(actor_participant_id),
        "move_card_id": String(move_card_id),
        "energy_counts": energy_counts.duplicate(true),
        "kyokoro_orientation": String(kyokoro_orientation),
        "expected_success": expected_success,
        "expected_energy_sufficient": expected_energy_sufficient,
        "expected_applied_damage": expected_applied_damage,
        "expected_player_hp": expected_player_hp,
        "expected_enemy_hp": expected_enemy_hp,
        "expected_next_participant_id": String(
            expected_next_participant_id
        ),
        "command_count": command_count,
        "event_count": event_count
    }


static func from_dictionary(
    data: Dictionary
) -> Variant:
    var result: Variant = new()

    result.turn_number = int(
        data.get("turn_number", 0)
    )
    result.actor_participant_id = StringName(
        data.get("actor_participant_id", "")
    )
    result.move_card_id = StringName(
        data.get("move_card_id", "")
    )

    var raw_energy_counts: Variant = data.get(
        "energy_counts",
        {}
    )

    if raw_energy_counts is Dictionary:
        result.energy_counts = (
            raw_energy_counts as Dictionary
        ).duplicate(true)

    result.kyokoro_orientation = StringName(
        data.get("kyokoro_orientation", "")
    )
    result.expected_success = bool(
        data.get("expected_success", false)
    )
    result.expected_energy_sufficient = bool(
        data.get(
            "expected_energy_sufficient",
            false
        )
    )
    result.expected_applied_damage = int(
        data.get("expected_applied_damage", 0)
    )
    result.expected_player_hp = int(
        data.get("expected_player_hp", 0)
    )
    result.expected_enemy_hp = int(
        data.get("expected_enemy_hp", 0)
    )
    result.expected_next_participant_id = StringName(
        data.get(
            "expected_next_participant_id",
            ""
        )
    )
    result.command_count = int(
        data.get("command_count", 0)
    )
    result.event_count = int(
        data.get("event_count", 0)
    )

    return result
