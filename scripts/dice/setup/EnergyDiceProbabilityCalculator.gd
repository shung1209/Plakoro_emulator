extends RefCounted


const ENERGY_COST_MATCHER: Script = preload(
    "res://scripts/battle/EnergyCostMatcher.gd"
)


static func get_expected_energy_per_roll(
    setup: Variant
) -> Dictionary:
    var result: Dictionary = {}

    if setup == null:
        return result

    for die_data: Variant in setup.dice:
        var die_expected: Dictionary = (
            die_data.get_expected_energy_counts()
        )

        for raw_energy: Variant in die_expected.keys():
            var energy_type: StringName = StringName(
                raw_energy
            )

            result[energy_type] = (
                float(result.get(energy_type, 0.0))
                + float(die_expected[raw_energy])
            )

    return result


static func get_at_least_one_probability(
    setup: Variant,
    energy_type: StringName
) -> float:
    if setup == null:
        return 0.0

    var miss_probability: float = 1.0

    for die_data: Variant in setup.dice:
        var matching_faces: int = 0
        var faces: Dictionary = (
            die_data.get_faces_by_orientation()
        )

        for face_data: Dictionary in faces.values():
            var energies: Array = face_data.get(
                "energies",
                []
            )

            if energies.has(energy_type):
                matching_faces += 1

        miss_probability *= (
            1.0 - float(matching_faces) / 6.0
        )

    return 1.0 - miss_probability


static func get_move_success_probability(
    setup: Variant,
    move_card: Variant
) -> float:
    if setup == null or move_card == null:
        return 0.0

    var all_results: Array = _enumerate_rolls(setup)

    if all_results.is_empty():
        return 0.0

    var success_count: int = 0

    for energy_counts: Dictionary in all_results:
        if _can_pay_cost(
            move_card.energy_costs,
            energy_counts
        ):
            success_count += 1

    return (
        float(success_count)
        / float(all_results.size())
    )


static func _enumerate_rolls(
    setup: Variant
) -> Array:
    if setup.dice.size() != 3:
        return []

    var die_faces: Array = []

    for die_data: Variant in setup.dice:
        var face_results: Array = []

        for face_data: Dictionary in (
            die_data.get_faces_by_orientation().values()
        ):
            var counts: Dictionary = {}

            for raw_energy: Variant in face_data.get(
                "energies",
                []
            ):
                var energy_type: StringName = StringName(
                    raw_energy
                )
                counts[energy_type] = int(
                    counts.get(energy_type, 0)
                ) + 1

            face_results.append(counts)

        die_faces.append(face_results)

    var results: Array = []

    for face_1: Dictionary in die_faces[0]:
        for face_2: Dictionary in die_faces[1]:
            for face_3: Dictionary in die_faces[2]:
                var combined: Dictionary = {}

                _merge_counts(combined, face_1)
                _merge_counts(combined, face_2)
                _merge_counts(combined, face_3)

                results.append(combined)

    return results


static func _merge_counts(
    target: Dictionary,
    source: Dictionary
) -> void:
    for raw_energy: Variant in source.keys():
        target[raw_energy] = (
            int(target.get(raw_energy, 0))
            + int(source[raw_energy])
        )


static func _can_pay_cost(
    costs: Array,
    energy_counts: Dictionary
) -> bool:
    return ENERGY_COST_MATCHER.can_pay_cost(
        costs,
        energy_counts
    )
