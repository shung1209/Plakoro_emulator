extends RefCounted


const MAPPING_PATH: String = (
    "res://database/kyokoro_orientation_map.json"
)

const ORIENTATION_IDS: Array[String] = [
    "FACE_UP",
    "FACE_DOWN",
    "HEAD_UP",
    "HEAD_DOWN",
    "HEAD_LEFT",
    "HEAD_RIGHT"
]


static func is_valid_orientation(
    orientation: String
) -> bool:
    return ORIENTATION_IDS.has(
        orientation
    )


static func validate_orientations(
    orientations: Variant
) -> Dictionary:
    var errors: Array[String] = []

    if not orientations is Array:
        return {
            "success": false,
            "errors": [
                "orientations must be an Array."
            ]
        }

    var seen: Dictionary = {}

    for raw_orientation: Variant in (
        orientations as Array
    ):
        var orientation: String = String(
            raw_orientation
        )

        if not is_valid_orientation(
            orientation
        ):
            errors.append(
                "Invalid Charakoro orientation: "
                + orientation
            )
            continue

        if seen.has(
            orientation
        ):
            errors.append(
                "Duplicate Charakoro orientation: "
                + orientation
            )

        seen[
            orientation
        ] = true

    return {
        "success": errors.is_empty(),
        "errors": errors
    }


static func load_mapping_document() -> Dictionary:
    if not FileAccess.file_exists(
        MAPPING_PATH
    ):
        return {}

    var file: FileAccess = FileAccess.open(
        MAPPING_PATH,
        FileAccess.READ
    )

    if file == null:
        return {}

    var parsed: Variant = JSON.parse_string(
        file.get_as_text()
    )

    return (
        parsed as Dictionary
        if parsed is Dictionary
        else {}
    )


static func get_confirmed_effect_mappings(
    move_id: String
) -> Array:
    var document: Dictionary = (
        load_mapping_document()
    )
    var mappings: Variant = document.get(
        "confirmed_effect_mappings",
        {}
    )

    if not mappings is Dictionary:
        return []

    var raw: Variant = (
        (mappings as Dictionary).get(
            move_id,
            []
        )
    )

    return (
        (raw as Array).duplicate(
            true
        )
        if raw is Array
        else []
    )


static func get_confirmed_move_mapping(
    move_id: String
) -> Dictionary:
    var effects: Array = (
        get_confirmed_effect_mappings(
            move_id
        )
    )

    if effects.is_empty():
        return {}

    return (
        effects[0] as Dictionary
    ).duplicate(
        true
    )
