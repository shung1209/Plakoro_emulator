extends RefCounted


var success: bool = false
var energy_sufficient: bool = false
var move_executed: bool = false
var outcome_triggered: bool = false
var battle_finished: bool = false

var actor_participant_id: StringName = &""
var target_participant_id: StringName = &""
var move_card_id: StringName = &""
var kyokoro_orientation: StringName = &""
var additional_kyokoro_orientations: Array = []
var special_kyokoro_success_count: int = 0
var opponent_kyokoro_orientation: StringName = &""
var opponent_kyokoro_success: bool = false
var repeated_move_count: int = 0

var damage_context: Variant = null
var applied_damage: int = 0

var commands_generated: int = 0
var events_generated: int = 0

var log_entries: Array[String] = []
var status_lifecycle_entries: Array[String] = []
var effect_lifecycle_entries: Array[Dictionary] = []
var resolution_events: Array[Dictionary] = []
var resolution_damage_atoms: Array[Dictionary] = []
var resolution_self_damage_events: Array[Dictionary] = []
var error_message: String = ""


func add_status_lifecycle_entry(
    message: String
) -> void:
    if message.is_empty():
        return

    status_lifecycle_entries.append(
        message
    )



func add_effect_lifecycle_entry(
    state_name: StringName,
    effect_type: StringName,
    effect_id: StringName,
    message: String
) -> void:
    if message.is_empty():
        return

    effect_lifecycle_entries.append(
        {
            "state": state_name,
            "effect_type": effect_type,
            "effect_id": effect_id,
            "message": message
        }
    )



func add_resolution_damage_atom(
    amount: int,
    stage_name: StringName,
    source_name: String = "Effect Damage"
) -> void:
    if amount <= 0:
        return

    resolution_damage_atoms.append(
        {
            "amount": amount,
            "stage": stage_name,
            "label": source_name
        }
    )



func add_resolution_self_damage_event(
    amount: int,
    reason: StringName = &"recoil"
) -> void:
    if amount <= 0:
        return

    resolution_self_damage_events.append(
        {
            "kind": &"self_damage",
            "label": "Self Damage",
            "amount": amount,
            "reason": reason
        }
    )
