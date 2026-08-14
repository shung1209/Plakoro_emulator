extends RefCounted


const DECISION_DATA: Script = preload(
    "res://scripts/ai/data/AIDecisionData.gd"
)
const MOVE_EVALUATOR: Script = preload(
    "res://scripts/ai/AIMoveEvaluator.gd"
)


var reference_data: Variant = null
var sample_count: int = 1024
var random_seed: int = 2026


func _init(
    source_reference_data: Variant,
    evaluation_sample_count: int = 1024,
    initial_random_seed: int = 2026
) -> void:
    reference_data = source_reference_data
    sample_count = evaluation_sample_count
    random_seed = initial_random_seed


func choose_move(
    actor: Variant,
    defender: Variant,
    difficulty: StringName = &"normal"
) -> Variant:
    var decision: Variant = DECISION_DATA.new()
    decision.random_seed = random_seed
    decision.difficulty = difficulty

    var profiles: Array = (
        _create_energy_die_profiles(
            actor.loadout
        )
    )

    var evaluator: Variant = MOVE_EVALUATOR.new(
        reference_data,
        sample_count,
        random_seed
    )

    for move_card: Variant in (
        actor.loadout.selected_move_cards
    ):
        var evaluation: Variant = (
            evaluator.evaluate_move(
                actor,
                defender,
                move_card,
                profiles,
                difficulty
            )
        )

        decision.evaluations.append(evaluation)

    decision.evaluations.sort_custom(
        func(a: Variant, b: Variant) -> bool:
            if bool(a.legal) != bool(b.legal):
                return bool(a.legal)

            if is_equal_approx(
                float(a.score),
                float(b.score)
            ):
                return (
                    String(a.move_card_id)
                    < String(b.move_card_id)
                )

            return float(a.score) > float(b.score)
    )

    for evaluation: Variant in decision.evaluations:
        if not evaluation.legal:
            continue

        decision.selected_evaluation = evaluation
        decision.selected_move_card_id = StringName(
            evaluation.move_card_id
        )
        break

    return decision


func _create_energy_die_profiles(
    loadout: Variant
) -> Array:
    var result: Array = []

    for die_config: Variant in loadout.energy_dice:
        result.append(
            die_config.create_profile()
        )

    return result
