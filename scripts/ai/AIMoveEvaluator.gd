extends RefCounted


const EVALUATION_DATA: Script = preload(
    "res://scripts/ai/data/AIMoveEvaluationData.gd"
)
const DICE_ENGINE: Script = preload(
    "res://scripts/dice/DiceEngine.gd"
)
const ENERGY_RESOLVER: Script = preload(
    "res://scripts/battle/EnergyResolver.gd"
)
const EFFECT_ESTIMATOR: Script = preload(
    "res://scripts/ai/AIEffectEstimator.gd"
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
    sample_count = max(
        evaluation_sample_count,
        1
    )
    random_seed = initial_random_seed


func evaluate_move(
    actor: Variant,
    defender: Variant,
    move_card: Variant,
    energy_die_profiles: Array,
    difficulty: StringName = &"normal"
) -> Variant:
    var evaluation: Variant = EVALUATION_DATA.new()

    evaluation.move_card_id = StringName(
        move_card.id
    )
    evaluation.move_name_id = StringName(
        move_card.move_name_id
    )
    evaluation.display_name = String(
        move_card.display_name
    )
    evaluation.sample_count = sample_count

    if not actor.can_use_move(
        evaluation.move_name_id
    ):
        evaluation.legal = false
        evaluation.rejection_reason = (
            "Move cooldown prevents reuse."
        )
        return evaluation

    var weakness_bonus: int = int(
        defender.pokemon_data.get_weakness_bonus(
            StringName(move_card.attack_type)
        )
    )

    var dice_modifier: int = 0

    if actor.status_container != null:
        dice_modifier = (
            actor.status_container
            .get_additive_value(
                &"energy_dice_modifier"
            )
        )

    var dice_engine: Variant = DICE_ENGINE.new(
        reference_data,
        _derive_move_seed(
            evaluation.move_card_id
        )
    )

    var total_damage: float = 0.0
    var total_heal: float = 0.0
    var total_status_utility: float = 0.0

    for _sample_index: int in range(
        sample_count
    ):
        var dice_result: Variant = (
            dice_engine.roll_battle_dice(
                energy_die_profiles,
                actor.pokemon_data.kyokoro_profile,
                dice_modifier
            )
        )

        if dice_result == null:
            evaluation.legal = false
            evaluation.rejection_reason = (
                "Dice simulation failed."
            )
            return evaluation

        if not ENERGY_RESOLVER.can_pay_cost(
            move_card,
            dice_result
        ):
            continue

        evaluation.successful_energy_samples += 1

        var estimated_damage: int = (
            EFFECT_ESTIMATOR.estimate_damage(
                move_card,
                dice_result.kyokoro_orientation,
                weakness_bonus
            )
        )

        var estimated_heal: int = (
            EFFECT_ESTIMATOR.estimate_self_heal(
                move_card,
                dice_result.kyokoro_orientation
            )
        )

        var status_utility: float = (
            EFFECT_ESTIMATOR
            .estimate_status_utility(
                move_card,
                dice_result.kyokoro_orientation
            )
        )

        total_damage += float(estimated_damage)
        total_heal += float(estimated_heal)
        total_status_utility += status_utility

        if estimated_damage >= defender.current_hp:
            evaluation.knockout_samples += 1

    evaluation.success_probability = (
        float(evaluation.successful_energy_samples)
        / float(sample_count)
    )
    evaluation.knockout_probability = (
        float(evaluation.knockout_samples)
        / float(sample_count)
    )
    evaluation.expected_damage = (
        total_damage / float(sample_count)
    )
    evaluation.expected_self_heal = (
        total_heal / float(sample_count)
    )
    evaluation.expected_status_utility = (
        total_status_utility
        / float(sample_count)
    )

    evaluation.score = _calculate_score(
        evaluation,
        actor,
        defender,
        difficulty
    )

    return evaluation


func _calculate_score(
    evaluation: Variant,
    actor: Variant,
    defender: Variant,
    difficulty: StringName
) -> float:
    var score: float = 0.0

    match difficulty:
        &"easy":
            score = (
                evaluation.expected_damage
                + evaluation.success_probability * 2.0
            )

        &"normal":
            score = (
                evaluation.expected_damage
                + evaluation.expected_self_heal * 0.45
                + evaluation.expected_status_utility
                + evaluation.success_probability * 5.0
                + evaluation.knockout_probability * 100.0
            )

        &"hard":
            var missing_hp: int = max(
                actor.max_hp - actor.current_hp,
                0
            )
            var useful_heal: float = min(
                evaluation.expected_self_heal,
                float(missing_hp)
            )

            score = (
                evaluation.expected_damage
                + useful_heal * 0.7
                + evaluation.expected_status_utility * 1.2
                + evaluation.success_probability * 8.0
                + evaluation.knockout_probability * 160.0
            )

            if (
                evaluation.expected_damage
                >= float(defender.current_hp)
            ):
                score += 25.0

        _:
            score = evaluation.expected_damage

    return score


func _derive_move_seed(
    move_card_id: StringName
) -> int:
    var derived: int = random_seed

    for character_code: int in String(
        move_card_id
    ).to_utf8_buffer():
        derived = (
            (derived * 31 + character_code)
            & 0x7fffffff
        )

    return derived
