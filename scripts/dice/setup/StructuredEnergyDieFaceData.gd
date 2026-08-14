extends RefCounted


var id: StringName = &""
var orientation: StringName = &""
var kind: StringName = &""
var weight: float = 1.0
var energies: Array[StringName] = []


func initialize(
    source_die_id: StringName,
    source_orientation: StringName,
    source_kind: StringName,
    source_energies: Array,
    source_weight: float = 1.0
) -> void:
    orientation = source_orientation
    kind = source_kind
    weight = source_weight

    id = StringName(
        String(source_die_id)
        + "_"
        + String(source_orientation).to_lower()
    )

    energies.clear()

    for raw_energy: Variant in source_energies:
        energies.append(
            StringName(raw_energy)
        )


func get_energy_counts() -> Dictionary:
    var result: Dictionary = {}

    for energy_type: StringName in energies:
        result[energy_type] = (
            int(result.get(energy_type, 0)) + 1
        )

    return result


func to_dictionary() -> Dictionary:
    var serialized_energies: Array[String] = []

    for energy_type: StringName in energies:
        serialized_energies.append(
            String(energy_type)
        )

    return {
        "id": String(id),
        "orientation": String(orientation),
        "kind": String(kind),
        "weight": weight,
        "energies": serialized_energies
    }
