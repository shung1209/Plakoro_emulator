extends RefCounted


var turn_number: int = 0
var actor_participant_id: StringName = &""
var target_participant_id: StringName = &""

var move_card_id: StringName = &""
var move_name_id: StringName = &""

var had_printed_damage: bool = false
var printed_damage: int = 0

var energy_sufficient: bool = false
var move_executed: bool = false
var outcome_triggered: bool = false

var kyokoro_orientation: StringName = &""
var applied_damage: int = 0


func energy_roll_failed() -> bool:
    return not energy_sufficient


func move_outcome_succeeded(
    expected_move_name_id: StringName = &""
) -> bool:
    if not (
        move_executed
        and outcome_triggered
    ):
        return false

    if expected_move_name_id == &"":
        return true

    return move_name_id == expected_move_name_id
