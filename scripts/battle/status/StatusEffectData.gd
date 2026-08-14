extends RefCounted


var id: StringName = &""
var status_type: StringName = &""
var source_participant_id: StringName = &""

var value: int = 0
var stack_mode: StringName = &"add"

# duration_turns is only meaningful when duration_based is true.
# A non-duration status may keep duration_turns at 0 indefinitely.
var duration_turns: int = 0
var duration_based: bool = false
var duration_scope: StringName = &"owner_turn"

# Used to avoid immediately ticking a status created during the owner's
# currently resolving turn.
var created_turn_number: int = 0

# A value below 0 means unlimited uses.
var remaining_uses: int = 1

var timing: StringName = &""
var parameters: Dictionary = {}


func is_expired() -> bool:
    if remaining_uses == 0:
        return true

    if (
        duration_based
        and duration_turns <= 0
    ):
        return true

    return false


func consume_use() -> void:
    if remaining_uses < 0:
        return

    remaining_uses = max(
        remaining_uses - 1,
        0
    )


func tick_owner_turn(
    completed_turn_number: int
) -> bool:
    if not duration_based:
        return false

    if duration_scope != &"owner_turn":
        return false

    # A status created during this same owner turn begins counting from the
    # next owner turn, so "for 2 turns" never loses one turn immediately.
    if (
        created_turn_number > 0
        and created_turn_number == completed_turn_number
    ):
        return false

    if duration_turns <= 0:
        return false

    duration_turns -= 1
    return true


func tick_turn() -> void:
    tick_owner_turn(-1)
