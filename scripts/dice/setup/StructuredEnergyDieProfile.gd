extends RefCounted


const FACE_DATA: Script = preload(
    "res://scripts/dice/setup/StructuredEnergyDieFaceData.gd"
)


const ORIENTATIONS: Array[StringName] = [
    &"FACE_UP",
    &"FACE_DOWN",
    &"HEAD_UP",
    &"HEAD_DOWN",
    &"HEAD_LEFT",
    &"HEAD_RIGHT"
]


const VALID_ENERGY_TYPES: Array[StringName] = [
    &"grass",
    &"fire",
    &"water",
    &"electric",
    &"psychic",
    &"fighting",
    &"dark",
    &"steel",
    &"flying"
]


var die_id: StringName = &""
var id: StringName = &""
var faces_by_orientation: Dictionary = {}


func get_orientation_ids() -> Array[StringName]:
    return ORIENTATIONS.duplicate()


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


func get_all_faces() -> Array:
    var result: Array = []

    for orientation: StringName in ORIENTATIONS:
        var face_result: Dictionary = get_face_result(
            orientation
        )

        if face_result.is_empty():
            return []

        var face: Variant = FACE_DATA.new()
        face.initialize(
            die_id,
            orientation,
            StringName(
                face_result.get(
                    "kind",
                    ""
                )
            ),
            face_result.get(
                "energies",
                []
            ),
            float(
                face_result.get(
                    "weight",
                    1.0
                )
            )
        )

        result.append(face)

    return result


func validate(
    _reference_data: Variant = null
) -> bool:
    if die_id == &"":
        push_error(
            "StructuredEnergyDieProfile: die_id is empty."
        )
        return false

    id = die_id

    if faces_by_orientation.size() != 6:
        push_error(
            "StructuredEnergyDieProfile: expected exactly six orientations."
        )
        return false

    for orientation: StringName in ORIENTATIONS:
        if not faces_by_orientation.has(orientation):
            push_error(
                "StructuredEnergyDieProfile: missing orientation "
                + String(orientation)
                + "."
            )
            return false

        var raw_face: Variant = (
            faces_by_orientation[orientation]
        )

        if not raw_face is Dictionary:
            push_error(
                "StructuredEnergyDieProfile: invalid face data for "
                + String(orientation)
                + "."
            )
            return false

        var face_data: Dictionary = raw_face
        var energies_value: Variant = face_data.get(
            "energies",
            []
        )

        if not energies_value is Array:
            push_error(
                "StructuredEnergyDieProfile: energies must be an Array for "
                + String(orientation)
                + "."
            )
            return false

        var energies: Array = energies_value
        var expected_count: int = 1

        if (
            orientation == &"HEAD_UP"
            or orientation == &"HEAD_DOWN"
        ):
            expected_count = 2

        if energies.size() != expected_count:
            push_error(
                "StructuredEnergyDieProfile: "
                + String(orientation)
                + " expected "
                + str(expected_count)
                + " energy value(s), got "
                + str(energies.size())
                + "."
            )
            return false

        for raw_energy: Variant in energies:
            var energy_type: StringName = StringName(
                raw_energy
            )

            if not VALID_ENERGY_TYPES.has(
                energy_type
            ):
                push_error(
                    "StructuredEnergyDieProfile: invalid energy "
                    + String(energy_type)
                    + " on "
                    + String(orientation)
                    + "."
                )
                return false

        var weight: float = float(
            face_data.get("weight", 1.0)
        )

        if weight <= 0.0:
            push_error(
                "StructuredEnergyDieProfile: weight must be positive on "
                + String(orientation)
                + "."
            )
            return false

    return true
