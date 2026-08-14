extends RefCounted


const MOVE_COVERAGE_ANALYZER: Script = preload(
    "res://scripts/analysis/MoveCoverageAnalyzer.gd"
)


static func analyze_selection(
    energy_dice_setup: Variant,
    selected_move_ids: Array[StringName],
    database: Variant
) -> Dictionary:
    var result: Dictionary = {
        "move_results": [],
        "overall_probability": 0.0,
        "rating": &"none",
        "stars": 0,
        "energy_usage": {}
    }

    if energy_dice_setup == null or database == null:
        return result

    var total_probability: float = 0.0
    var analyzed_count: int = 0
    var move_results: Array = []
    var energy_usage: Dictionary = {}

    for move_card_id: StringName in selected_move_ids:
        var move_card: Variant = database.get_move_card(
            move_card_id
        )

        if move_card == null:
            continue

        var coverage: Variant = (
            MOVE_COVERAGE_ANALYZER.analyze_move(
                energy_dice_setup,
                move_card
            )
        )

        if coverage == null:
            continue

        move_results.append(coverage)
        total_probability += float(
            coverage.success_probability
        )
        analyzed_count += 1

        for cost: Variant in move_card.energy_costs:
            var energy_type: StringName = StringName(
                cost.energy_type
            )

            energy_usage[energy_type] = (
                int(
                    energy_usage.get(
                        energy_type,
                        0
                    )
                )
                + int(cost.count)
            )

    var overall_probability: float = 0.0

    if analyzed_count > 0:
        overall_probability = (
            total_probability
            / float(analyzed_count)
        )

    result["move_results"] = move_results
    result["overall_probability"] = overall_probability
    result["rating"] = _get_rating(
        overall_probability,
        analyzed_count
    )
    result["stars"] = _get_stars(
        overall_probability,
        analyzed_count
    )
    result["energy_usage"] = energy_usage

    return result


static func _get_rating(
    probability: float,
    analyzed_count: int
) -> StringName:
    if analyzed_count == 0:
        return &"none"

    if probability >= 0.90:
        return &"excellent"

    if probability >= 0.75:
        return &"good"

    if probability >= 0.60:
        return &"acceptable"

    return &"poor"


static func _get_stars(
    probability: float,
    analyzed_count: int
) -> int:
    if analyzed_count == 0:
        return 0

    if probability >= 0.90:
        return 5

    if probability >= 0.80:
        return 4

    if probability >= 0.70:
        return 3

    if probability >= 0.55:
        return 2

    return 1
