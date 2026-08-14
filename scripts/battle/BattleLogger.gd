extends RefCounted


static func add(
    battle_state: Variant,
    turn_result: Variant,
    message: String
) -> void:
    battle_state.battle_log.append(message)
    turn_result.log_entries.append(message)
    print(message)
