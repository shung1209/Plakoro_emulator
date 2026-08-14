extends RefCounted


var id: StringName = &""
var role: StringName = &"single"
var local_axis: StringName = &""
var weight: float = 1.0
var energies: Array = []


func _init(
    face_id: StringName = &"",
    face_role: StringName = &"single",
    axis_id: StringName = &"",
    face_energies: Array = [],
    face_weight: float = 1.0
) -> void:
    id = face_id
    role = face_role
    local_axis = axis_id
    weight = face_weight

    energies.clear()

    for raw_energy: Variant in face_energies:
        energies.append(StringName(raw_energy))


func get_energy_count(
    energy_type: StringName
) -> int:
    var count: int = 0

    for raw_energy: Variant in energies:
        if StringName(raw_energy) == energy_type:
            count += 1

    return count


func is_double_energy_face() -> bool:
    return energies.size() == 2
