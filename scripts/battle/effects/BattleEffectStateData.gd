extends RefCounted


var id: StringName = &""
var effect_type: StringName = &""

var source_participant_id: StringName = &""
var target_participant_id: StringName = &""
var source_move_id: StringName = &""
var target_move_id: StringName = &""

var value: int = 0
var state: StringName = &"active"

# Generic lifecycle fields.
# remaining_uses < 0 means unlimited until another expiration rule removes it.
var remaining_uses: int = 1
var duration_turns: int = 0
var duration_scope: StringName = &""
var consume_timing: StringName = &""
var created_turn_number: int = 0
var activate_after_turn_number: int = 0

# Human-facing / rule-specific metadata without hard-coding Pokémon or Move names.
var display_text: String = ""
var metadata: Dictionary = {}


func is_active() -> bool:
    return state == &"active" and not is_expired()


func can_activate_in_turn(
    turn_number: int
) -> bool:
    if not is_active():
        return false

    if activate_after_turn_number <= 0:
        return true

    return turn_number > activate_after_turn_number


func is_expired() -> bool:
    if state == &"consumed" or state == &"expired":
        return true

    if remaining_uses == 0:
        return true

    if (
        duration_scope != &""
        and duration_turns <= 0
    ):
        return true

    return false


func consume_once() -> bool:
    if not is_active():
        return false

    if remaining_uses > 0:
        remaining_uses -= 1

    if remaining_uses == 0:
        state = &"consumed"

    return true


func expire() -> void:
    state = &"expired"


func tick_owner_turn(
    completed_turn_number: int
) -> bool:
    if duration_scope != &"owner_turn":
        return false

    if (
        created_turn_number > 0
        and created_turn_number == completed_turn_number
    ):
        return false

    if duration_turns <= 0:
        return false

    duration_turns -= 1

    if duration_turns <= 0:
        state = &"expired"

    return true
