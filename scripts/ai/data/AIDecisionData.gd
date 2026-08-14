extends RefCounted


var selected_move_card_id: StringName = &""
var selected_evaluation: Variant = null
var evaluations: Array = []

var random_seed: int = 0
var difficulty: StringName = &"normal"


func is_valid() -> bool:
    return (
        selected_move_card_id != &""
        and selected_evaluation != null
    )


func get_ranked_evaluations() -> Array:
    return evaluations.duplicate()
