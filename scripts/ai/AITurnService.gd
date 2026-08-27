extends RefCounted


const DECISION_ENGINE: Script = preload(
    "res://scripts/ai/AIDecisionEngine.gd"
)
const DICE_ENGINE: Script = preload(
    "res://scripts/dice/DiceEngine.gd"
)
const STATUS_RESOLVER: Script = preload(
    "res://scripts/battle/status/StatusResolver.gd"
)
const SPECIAL_KYOKORO_SEQUENCE: Script = preload(
    "res://scripts/battle/special/SpecialKyokoroSequenceService.gd"
)
const SPECIAL_MOVE_SELECTION: Script = preload(
    "res://scripts/battle/special/SpecialMoveSelectionService.gd"
)
const SPECIAL_OPPONENT_ENERKORO: Script = preload(
    "res://scripts/battle/special/SpecialOpponentEnerkoroService.gd"
)
const ENERGY_RESOLVER: Script = preload(
    "res://scripts/battle/EnergyResolver.gd"
)


var battle_controller: Variant = null
var decision_engine: Variant = null
var dice_engine: Variant = null


func _init(
    source_battle_controller: Variant,
    sample_count: int = 1024,
    random_seed: int = 2026
) -> void:
    battle_controller = source_battle_controller

    decision_engine = DECISION_ENGINE.new(
        battle_controller.database.reference_data,
        sample_count,
        random_seed
    )

    dice_engine = DICE_ENGINE.new(
        battle_controller.database.reference_data,
        random_seed
    )


func execute_ai_turn(
    difficulty: StringName = &"normal",
    selected_move_card_id: StringName = &""
) -> Dictionary:
    var result: Dictionary = {
        "success": false,
        "decision": null,
        "dice_result": null,
        "turn_result": null
    }

    if (
        battle_controller == null
        or battle_controller.state == null
    ):
        return result

    if battle_controller.state.is_finished:
        return result

    var actor: Variant = (
        battle_controller.state
        .get_current_participant()
    )
    var defender: Variant = (
        battle_controller.state
        .get_opponent_participant()
    )

    var decision: Variant = (
        decision_engine.choose_move(
            actor,
            defender,
            difficulty
        )
    )
    if selected_move_card_id != &"":
        if not actor.loadout.has_move_card(selected_move_card_id):
            return result
        var selected_move: Variant = battle_controller.database.get_move_card(
            selected_move_card_id
        )
        if selected_move == null or not actor.can_use_move(
            StringName(selected_move.move_name_id)
        ):
            return result
        decision.selected_move_card_id = selected_move_card_id
        # Local VS supplies the selection, so an AI evaluation is unnecessary;
        # keep the existing result contract valid for the presentation layer.
        decision.selected_evaluation = {}

    result["decision"] = decision

    if not decision.is_valid():
        return result

    var profiles: Array = []

    for die_config: Variant in actor.loadout.energy_dice:
        profiles.append(
            die_config.create_profile()
        )

    var dice_modifier_report: Dictionary = (
        STATUS_RESOLVER
        .consume_energy_dice_modifier_report(
            actor
        )
    )
    var dice_modifier: int = int(
        dice_modifier_report.get(
            "value",
            0
        )
    )
    # Official opening-turn restriction applies equally when the AI or local
    # Player 2 wins the coin toss and acts first.
    if battle_controller.state.turn_number == 1:
        dice_modifier -= 1
    result["status_lifecycle"] = (
        dice_modifier_report
    )

    var kyokoro_disable_report: Dictionary = (
        STATUS_RESOLVER
        .consume_kyokoro_disable_report(
            actor
        )
    )
    result["kyokoro_disable_lifecycle"] = (
        kyokoro_disable_report
    )
    var kyokoro_enabled: bool = not bool(
        kyokoro_disable_report.get(
            "consumed",
            false
        )
    )

    var forced_orientation: StringName = &""
    if kyokoro_enabled:
        forced_orientation = STATUS_RESOLVER.consume_forced_kyokoro_orientation(actor)

    var dice_result: Variant = (
        dice_engine.roll_battle_dice(
            profiles,
            actor.pokemon_data.kyokoro_profile,
            dice_modifier,
            kyokoro_enabled,
            forced_orientation
        )
    )

    result["dice_result"] = dice_result
    result["energy_profiles"] = profiles

    var roll_history: Array = (
        dice_engine.get_history()
    )

    if not roll_history.is_empty():
        result["roll_record"] = (
            roll_history.back()
        )

    if dice_result == null:
        return result

    var selected_move: Variant = (
        battle_controller.database.get_move_card(
            decision.selected_move_card_id
        )
    )

    var initial_energy_sufficient: bool = (
        ENERGY_RESOLVER.can_pay_cost(
            selected_move,
            dice_result
        )
    )
    result["initial_energy_sufficient"] = (
        initial_energy_sufficient
    )

    var special_rolls: Dictionary = {
        "generated": false
    }
    var opponent_roll: Dictionary = {
        "generated": false
    }

    if initial_energy_sufficient:
        special_rolls = (
            SPECIAL_KYOKORO_SEQUENCE
            .populate_additional_rolls(
                selected_move,
                dice_result,
                dice_engine,
                actor.pokemon_data.kyokoro_profile
            )
        )

        opponent_roll = (
            SPECIAL_KYOKORO_SEQUENCE
            .populate_opponent_roll(
                selected_move,
                dice_result,
                dice_engine,
                defender.pokemon_data.kyokoro_profile
            )
        )

    result["special_kyokoro_rolls"] = (
        special_rolls
    )
    result["opponent_kyokoro_roll"] = (
        opponent_roll
    )

    var opponent_enerkoro_profiles: Array = []

    for die_config: Variant in defender.loadout.energy_dice:
        opponent_enerkoro_profiles.append(
            die_config.create_profile()
        )

    var opponent_enerkoro_roll: Dictionary = {
        "generated": false
    }

    if initial_energy_sufficient:
        opponent_enerkoro_roll = (
            SPECIAL_OPPONENT_ENERKORO.populate_roll(
                selected_move,
                dice_result,
                dice_engine,
                opponent_enerkoro_profiles
            )
        )
    result["opponent_enerkoro_roll"] = (
        opponent_enerkoro_roll
    )
    result["opponent_enerkoro_profiles"] = (
        opponent_enerkoro_profiles
    )

    if (
        initial_energy_sufficient
        and SPECIAL_MOVE_SELECTION.requires_selection(
            selected_move,
            dice_result
        )
    ):
        dice_result.selected_opponent_move_name_id = (
            SPECIAL_MOVE_SELECTION.choose_ai_target(
                defender
            )
        )

    var turn_result: Variant = (
        battle_controller.execute_turn(
            decision.selected_move_card_id,
            dice_result
        )
    )

    result["turn_result"] = turn_result
    result["success"] = bool(
        turn_result.success
    )

    return result
