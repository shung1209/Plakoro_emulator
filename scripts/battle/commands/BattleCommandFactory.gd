extends RefCounted


const COMMAND_DATA: Script = preload(
    "res://scripts/battle/commands/BattleCommandData.gd"
)


static func create_damage_command(
    source_id: StringName,
    target_id: StringName,
    amount: int,
    damage_type: StringName,
    reason: StringName = &"attack"
) -> Variant:
    return COMMAND_DATA.new(
        &"damage.apply",
        source_id,
        target_id,
        {
            "amount": amount,
            "damage_type": damage_type,
            "reason": reason
        }
    )


static func create_heal_command(
    source_id: StringName,
    target_id: StringName,
    amount: int
) -> Variant:
    return COMMAND_DATA.new(
        &"hp.restore",
        source_id,
        target_id,
        {
            "amount": amount
        }
    )


static func create_add_status_command(
    source_id: StringName,
    target_id: StringName,
    status_payload: Dictionary
) -> Variant:
    return COMMAND_DATA.new(
        &"status.add",
        source_id,
        target_id,
        status_payload
    )


static func create_persistent_status_command(
    source_id: StringName,
    target_id: StringName,
    status_type: StringName,
    value: int,
    duration_turns: int,
    timing: StringName = &"",
    stack_mode: StringName = &"add",
    remaining_uses: int = -1,
    parameters: Dictionary = {}
) -> Variant:
    return create_add_status_command(
        source_id,
        target_id,
        {
            "status_type": status_type,
            "value": value,
            "stack_mode": stack_mode,
            "remaining_uses": remaining_uses,
            "duration_turns": max(
                duration_turns,
                0
            ),
            "duration_scope": "owner_turn",
            "timing": timing,
            "parameters": parameters.duplicate(
                true
            )
        }
    )


static func create_modify_energy_dice_command(
    source_id: StringName,
    target_id: StringName,
    amount: int,
    duration_turns: int = 0,
    remaining_uses: int = 1
) -> Variant:
    return create_add_status_command(
        source_id,
        target_id,
        {
            "status_type": "energy_dice_modifier",
            "value": amount,
            "stack_mode": "add",
            "remaining_uses": (
                remaining_uses
                if duration_turns <= 0
                else -1
            ),
            "duration_turns": max(
                duration_turns,
                0
            ),
            "duration_scope": "owner_turn",
            "timing": "next_owner_turn"
        }
    )


static func create_modify_incoming_damage_command(
    source_id: StringName,
    target_id: StringName,
    amount: int,
    duration_turns: int = 0,
    remaining_uses: int = 1
) -> Variant:
    return create_add_status_command(
        source_id,
        target_id,
        {
            "status_type": "incoming_damage_modifier",
            "value": amount,
            "stack_mode": "add",
            "remaining_uses": (
                remaining_uses
                if duration_turns <= 0
                else -1
            ),
            "duration_turns": max(
                duration_turns,
                0
            ),
            "duration_scope": "owner_turn",
            "timing": "next_incoming_attack"
        }
    )


static func create_attack_damage_immunity_command(
    source_id: StringName,
    target_id: StringName,
    duration_turns: int = 1
) -> Variant:
    return create_add_status_command(
        source_id,
        target_id,
        {
            "status_type": "attack_damage_immunity",
            "stack_mode": "replace",
            "remaining_uses": -1,
            "duration_turns": max(
                duration_turns,
                1
            ),
            "duration_scope": "owner_turn",
            "timing": "next_incoming_attack"
        }
    )


static func create_move_lock_command(
    source_id: StringName,
    target_id: StringName,
    move_name_id: StringName,
    duration_turns: int = 1
) -> Variant:
    return create_add_status_command(
        source_id,
        target_id,
        {
            "status_type": "move_lock",
            "stack_mode": "add",
            "remaining_uses": -1,
            "duration_turns": max(
                duration_turns,
                1
            ),
            "duration_scope": "owner_turn",
            "timing": "next_owner_turn",
            "parameters": {
                "move_name_id": move_name_id
            }
        }
    )


static func create_repeat_permission_command(
    source_id: StringName,
    target_id: StringName,
    move_name_id: StringName
) -> Variant:
    return create_add_status_command(
        source_id,
        target_id,
        {
            "status_type": "repeat_move_permission",
            "stack_mode": "add",
            "remaining_uses": 1,
            "timing": "next_owner_turn",
            "parameters": {
                "move_name_id": move_name_id
            }
        }
    )


static func create_disable_weakness_command(
    source_id: StringName,
    target_id: StringName
) -> Variant:
    return create_add_status_command(
        source_id,
        target_id,
        {
            "status_type": "weakness_disable",
            "stack_mode": "add",
            "remaining_uses": 1,
            "timing": "next_owner_move"
        }
    )
