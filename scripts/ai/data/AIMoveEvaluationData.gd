extends RefCounted


var move_card_id: StringName = &""
var move_name_id: StringName = &""
var display_name: String = ""

var sample_count: int = 0
var successful_energy_samples: int = 0
var knockout_samples: int = 0

var success_probability: float = 0.0
var knockout_probability: float = 0.0

var expected_damage: float = 0.0
var expected_self_heal: float = 0.0
var expected_status_utility: float = 0.0

var score: float = -INF
var legal: bool = true
var rejection_reason: String = ""


func to_dictionary() -> Dictionary:
    return {
        "move_card_id": String(move_card_id),
        "move_name_id": String(move_name_id),
        "display_name": display_name,
        "sample_count": sample_count,
        "successful_energy_samples": successful_energy_samples,
        "knockout_samples": knockout_samples,
        "success_probability": success_probability,
        "knockout_probability": knockout_probability,
        "expected_damage": expected_damage,
        "expected_self_heal": expected_self_heal,
        "expected_status_utility": expected_status_utility,
        "score": score,
        "legal": legal,
        "rejection_reason": rejection_reason
    }
