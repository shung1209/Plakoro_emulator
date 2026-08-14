extends RefCounted


var die_id: StringName = &""
var id: StringName = &""

var faces_by_orientation: Dictionary = {}


var fixed_energy_a: StringName:
    get:
        return _get_first_energy(&"FACE_UP")


var fixed_energy_b: StringName:
    get:
        return _get_first_energy(&"FACE_DOWN")


func initialize(
    source_die_id: StringName,
    source_faces_by_orientation: Dictionary
) -> void:
    die_id = source_die_id
    id = source_die_id
    faces_by_orientation = (
        source_faces_by_orientation.duplicate(true)
    )


func create_profile() -> Variant:
    var profile_script: Script = preload(
        "res://scripts/dice/setup/StructuredEnergyDieProfile.gd"
    )

    var profile: Variant = profile_script.new()
    profile.die_id = die_id
    profile.faces_by_orientation = (
        faces_by_orientation.duplicate(true)
    )

    return profile


func get_face_result(
    orientation: StringName
) -> Dictionary:
    var raw_face: Variant = faces_by_orientation.get(
        orientation,
        {}
    )

    if not raw_face is Dictionary:
        return {}

    return (
        raw_face as Dictionary
    ).duplicate(true)


func get_fixed_energies() -> Array[StringName]:
    return [
        fixed_energy_a,
        fixed_energy_b
    ]


func get_all_energy_types() -> Array[StringName]:
    var result: Array[StringName] = []

    for raw_face: Variant in faces_by_orientation.values():
        if not raw_face is Dictionary:
            continue

        var face_data: Dictionary = raw_face
        var energies: Variant = face_data.get(
            "energies",
            []
        )

        if not energies is Array:
            continue

        for raw_energy: Variant in energies:
            var energy_type: StringName = StringName(
                raw_energy
            )

            if (
                energy_type != &""
                and not result.has(energy_type)
            ):
                result.append(energy_type)

    return result


func is_structured_energy_die() -> bool:
    return (
        not faces_by_orientation.is_empty()
        and faces_by_orientation.has(&"FACE_UP")
        and faces_by_orientation.has(&"FACE_DOWN")
        and faces_by_orientation.has(&"HEAD_UP")
        and faces_by_orientation.has(&"HEAD_DOWN")
        and faces_by_orientation.has(&"HEAD_LEFT")
        and faces_by_orientation.has(&"HEAD_RIGHT")
    )


func _get_first_energy(
    orientation: StringName
) -> StringName:
    var face_data: Dictionary = get_face_result(
        orientation
    )

    var energies: Variant = face_data.get(
        "energies",
        []
    )

    if not energies is Array:
        return &""

    if energies.is_empty():
        return &""

    return StringName(energies[0])


func to_dictionary() -> Dictionary:
    var serialized_faces: Dictionary = {}

    for raw_orientation: Variant in (
        faces_by_orientation.keys()
    ):
        var orientation: StringName = StringName(
            raw_orientation
        )
        var face_data: Dictionary = (
            faces_by_orientation[raw_orientation]
            as Dictionary
        )

        var serialized_energies: Array[String] = []

        for raw_energy: Variant in face_data.get(
            "energies",
            []
        ):
            serialized_energies.append(
                String(raw_energy)
            )

        serialized_faces[String(orientation)] = {
            "kind": String(
                face_data.get("kind", "")
            ),
            "energies": serialized_energies
        }

    return {
        "id": String(id),
        "die_id": String(die_id),
        "fixed_energy_a": String(fixed_energy_a),
        "fixed_energy_b": String(fixed_energy_b),
        "faces_by_orientation": serialized_faces
    }
