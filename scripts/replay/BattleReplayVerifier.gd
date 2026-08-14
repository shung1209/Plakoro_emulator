extends RefCounted


const DICE_RESULT_DATA: Script = preload(
    "res://scripts/battle/data/DiceRollResultData.gd"
)


static func verify(
    replay: Variant,
    battle_controller: Variant
) -> Dictionary:
    var result: Dictionary = {
        "success": true,
        "verified_turns": 0,
        "errors": []
    }

    for replay_turn: Variant in replay.turns:
        var dice_result: Variant = (
            DICE_RESULT_DATA.new()
        )
        dice_result.energy_counts = (
            replay_turn.energy_counts.duplicate(true)
        )
        dice_result.kyokoro_orientation = (
            replay_turn.kyokoro_orientation
        )

        var turn_result: Variant = (
            battle_controller.execute_turn(
                replay_turn.move_card_id,
                dice_result
            )
        )

        var state: Variant = battle_controller.state

        _compare(
            result,
            bool(turn_result.success)
            == bool(replay_turn.expected_success),
            "Turn %d success mismatch."
            % replay_turn.turn_number
        )

        _compare(
            result,
            bool(turn_result.energy_sufficient)
            == bool(
                replay_turn.expected_energy_sufficient
            ),
            "Turn %d energy result mismatch."
            % replay_turn.turn_number
        )

        _compare(
            result,
            int(turn_result.applied_damage)
            == int(
                replay_turn.expected_applied_damage
            ),
            "Turn %d damage mismatch."
            % replay_turn.turn_number
        )

        _compare(
            result,
            int(state.player.current_hp)
            == int(replay_turn.expected_player_hp),
            "Turn %d player HP mismatch."
            % replay_turn.turn_number
        )

        _compare(
            result,
            int(state.enemy.current_hp)
            == int(replay_turn.expected_enemy_hp),
            "Turn %d enemy HP mismatch."
            % replay_turn.turn_number
        )

        _compare(
            result,
            StringName(state.current_participant_id)
            == StringName(
                replay_turn.expected_next_participant_id
            ),
            "Turn %d next participant mismatch."
            % replay_turn.turn_number
        )

        result["verified_turns"] = int(
            result["verified_turns"]
        ) + 1

    return result


static func _compare(
    result: Dictionary,
    condition: bool,
    message: String
) -> void:
    if condition:
        return

    result["success"] = false
    var errors: Array = result["errors"]
    errors.append(message)
