extends RefCounted

const RESULT_DATA: Script = preload(
    "res://scripts/analysis/MoveCoverageResultData.gd"
)
const PROBABILITY: Script = preload(
    "res://scripts/dice/setup/EnergyDiceProbabilityCalculator.gd"
)
const ENERGY_COST_MATCHER: Script = preload(
    "res://scripts/battle/EnergyCostMatcher.gd"
)

static func analyze_move(setup: Variant, move_card: Variant) -> Variant:
    if setup == null or move_card == null:
        return null
    var result: Variant = RESULT_DATA.new()
    result.move_card_id = StringName(move_card.id)
    result.move_name = String(move_card.display_name)
    result.move_name_id = StringName(move_card.move_name_id)
    result.required_energy = _build_required_energy(move_card.energy_costs)
    result.success_probability = PROBABILITY.get_move_success_probability(setup, move_card)
    var shortfall: Dictionary = _calculate_shortfall_summary(
        setup,
        move_card.energy_costs
    )
    result.most_missing_energy = StringName(shortfall.get("most_missing_energy", ""))
    result.average_shortfall = float(shortfall.get("average_shortfall", 0.0))
    return result

static func analyze_moves(setup: Variant, move_cards: Array) -> Array:
    var results: Array = []
    for move_card: Variant in move_cards:
        var result: Variant = analyze_move(setup, move_card)
        if result != null:
            results.append(result)
    return results

static func _build_required_energy(costs: Array) -> Dictionary:
    var result: Dictionary = {}
    for cost: Variant in costs:
        var energy_type: StringName = StringName(cost.energy_type)
        result[energy_type] = int(result.get(energy_type, 0)) + int(cost.count)
    return result

static func _calculate_shortfall_summary(
    setup: Variant,
    costs: Array
) -> Dictionary:
    if costs.is_empty():
        return {
            "most_missing_energy": "",
            "average_shortfall": 0.0
        }

    var roll_results: Array = _enumerate_rolls(
        setup
    )

    if roll_results.is_empty():
        return {
            "most_missing_energy": "",
            "average_shortfall": 0.0
        }

    var missing_totals: Dictionary = {}
    var total_shortfall: float = 0.0

    for roll_counts: Dictionary in roll_results:
        var analysis: Dictionary = (
            ENERGY_COST_MATCHER.analyze_cost(
                costs,
                roll_counts
            )
        )

        var missing: Dictionary = analysis.get(
            "missing",
            {}
        )

        for raw_energy: Variant in missing.keys():
            missing_totals[raw_energy] = (
                int(
                    missing_totals.get(
                        raw_energy,
                        0
                    )
                )
                + int(
                    missing[raw_energy]
                )
            )

        total_shortfall += float(
            analysis.get(
                "total_shortfall",
                0
            )
        )

    var most_missing_energy: StringName = &""
    var most_missing_count: int = -1

    for raw_energy: Variant in missing_totals.keys():
        var count: int = int(
            missing_totals[raw_energy]
        )

        if count > most_missing_count:
            most_missing_count = count
            most_missing_energy = StringName(
                raw_energy
            )

    return {
        "most_missing_energy": most_missing_energy,
        "average_shortfall": (
            total_shortfall
            / float(
                roll_results.size()
            )
        )
    }


static func _enumerate_rolls(setup: Variant) -> Array:
    if setup == null or setup.dice.size() != 3:
        return []
    var die_faces: Array = []
    for die_data: Variant in setup.dice:
        var face_results: Array = []
        var faces: Dictionary = die_data.get_faces_by_orientation()
        for raw_orientation: Variant in faces.keys():
            var face_data: Dictionary = faces[raw_orientation]
            var counts: Dictionary = {}
            for raw_energy: Variant in face_data.get("energies", []):
                var energy_type: StringName = StringName(raw_energy)
                counts[energy_type] = int(counts.get(energy_type, 0)) + 1
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

static func _merge_counts(target: Dictionary, source: Dictionary) -> void:
    for raw_energy: Variant in source.keys():
        target[raw_energy] = int(target.get(raw_energy, 0)) + int(source[raw_energy])
