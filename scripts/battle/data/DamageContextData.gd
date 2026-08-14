extends RefCounted


var source_participant_id: StringName = &""
var target_participant_id: StringName = &""
var move_card_id: StringName = &""
var attack_type: StringName = &""

var base_damage: int = 0
var weakness_bonus: int = 0
var outcome_bonus: int = 0
var other_modifiers: int = 0
var defender_reduction: int = 0
var damage_multiplier: float = 1.0
var ignore_weakness: bool = false

var final_damage: int = 0


func calculate_final_damage() -> int:
    # Printed Move damage and Charakoro / other attack modifiers form the
    # attack subtotal first. Weakness is applied only after that subtotal
    # has finished its attack-side multiplier calculation.
    var attack_subtotal: int = max(
        base_damage
        + outcome_bonus
        + other_modifiers,
        0
    )

    var modified_attack_damage: int = max(
        int(
            round(
                float(
                    attack_subtotal
                )
                * max(
                    damage_multiplier,
                    0.0
                )
            )
        ),
        0
    )

    var damage_with_weakness: int = max(
        modified_attack_damage
        + weakness_bonus,
        0
    )

    final_damage = max(
        damage_with_weakness
        - defender_reduction,
        0
    )

    return final_damage
