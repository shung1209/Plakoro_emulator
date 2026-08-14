extends RefCounted


const BATTLE_REPLAY_DATA: Script = preload(
    "res://scripts/replay/data/BattleReplayData.gd"
)
const REPLAY_TURN_DATA: Script = preload(
    "res://scripts/replay/data/ReplayTurnData.gd"
)


var replay: Variant = null


func start_recording(
    player_loadout: Variant,
    enemy_loadout: Variant,
    random_seed: int = 0
) -> Variant:
    replay = BATTLE_REPLAY_DATA.new()
    replay.random_seed = random_seed

    replay.player_pokemon_id = StringName(
        player_loadout.pokemon_id
    )
    replay.enemy_pokemon_id = StringName(
        enemy_loadout.pokemon_id
    )

    for card_id: StringName in (
        player_loadout.selected_move_card_ids
    ):
        replay.player_move_card_ids.append(
            String(card_id)
        )

    for card_id: StringName in (
        enemy_loadout.selected_move_card_ids
    ):
        replay.enemy_move_card_ids.append(
            String(card_id)
        )

    return replay


func record_turn(
    turn_number: int,
    actor_participant_id: StringName,
    move_card_id: StringName,
    dice_result: Variant,
    turn_result: Variant,
    battle_state: Variant
) -> void:
    if replay == null:
        push_error(
            "BattleReplayRecorder: recording has not started."
        )
        return

    var turn: Variant = REPLAY_TURN_DATA.new()

    turn.turn_number = turn_number
    turn.actor_participant_id = (
        actor_participant_id
    )
    turn.move_card_id = move_card_id
    turn.energy_counts = (
        dice_result.energy_counts.duplicate(true)
    )
    turn.kyokoro_orientation = (
        dice_result.kyokoro_orientation
    )

    turn.expected_success = bool(
        turn_result.success
    )
    turn.expected_energy_sufficient = bool(
        turn_result.energy_sufficient
    )
    turn.expected_applied_damage = int(
        turn_result.applied_damage
    )

    turn.expected_player_hp = int(
        battle_state.player.current_hp
    )
    turn.expected_enemy_hp = int(
        battle_state.enemy.current_hp
    )
    turn.expected_next_participant_id = StringName(
        battle_state.current_participant_id
    )

    turn.command_count = int(
        turn_result.commands_generated
    )
    turn.event_count = int(
        turn_result.events_generated
    )

    replay.turns.append(turn)


func finish_recording(
    battle_state: Variant
) -> Variant:
    if replay == null:
        return null

    replay.final_player_hp = int(
        battle_state.player.current_hp
    )
    replay.final_enemy_hp = int(
        battle_state.enemy.current_hp
    )
    replay.winner_participant_id = StringName(
        battle_state.winner_participant_id
    )

    return replay
