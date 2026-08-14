extends RefCounted

var move_card_id: StringName = &""
var move_name: String = ""
var move_name_id: StringName = &""
var success_probability: float = 0.0
var required_energy: Dictionary = {}
var most_missing_energy: StringName = &""
var average_shortfall: float = 0.0

func get_rating_id() -> StringName:
    if success_probability >= 0.90:
        return &"excellent"
    if success_probability >= 0.60:
        return &"acceptable"
    return &"poor"

func to_dictionary() -> Dictionary:
    return {
        "move_card_id": String(move_card_id),
        "move_name": move_name,
        "move_name_id": String(move_name_id),
        "success_probability": success_probability,
        "required_energy": required_energy.duplicate(true),
        "most_missing_energy": String(most_missing_energy),
        "average_shortfall": average_shortfall,
        "rating": String(get_rating_id())
    }
