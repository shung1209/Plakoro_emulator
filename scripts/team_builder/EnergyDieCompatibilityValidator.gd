extends RefCounted


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


static func validate_energy_dice(
    energy_dice: Array
) -> Dictionary:
    var result: Dictionary = {
        "success": true,
        "errors": []
    }

    if energy_dice.size() != 3:
        _add_error(
            result,
            "Exactly three energy dice are required."
        )
        return result

    for index: int in range(energy_dice.size()):
        var die_config: Variant = energy_dice[index]

        if die_config == null:
            _add_error(
                result,
                "Energy die "
                + str(index + 1)
                + " is null."
            )
            continue

        if _is_structured_die(die_config):
            _validate_structured_die(
                result,
                die_config,
                index
            )
        else:
            _validate_legacy_die(
                result,
                die_config,
                index
            )

    return result


static func _is_structured_die(
    die_config: Variant
) -> bool:
    if die_config == null:
        return false

    if die_config.has_method(
        "is_structured_energy_die"
    ):
        return bool(
            die_config.is_structured_energy_die()
        )

    return (
        "faces_by_orientation" in die_config
        and die_config.faces_by_orientation is Dictionary
    )


static func _validate_structured_die(
    result: Dictionary,
    die_config: Variant,
    index: int
) -> void:
    var faces: Dictionary = (
        die_config.faces_by_orientation
    )

    var required_orientations: Array[StringName] = [
        &"FACE_UP",
        &"FACE_DOWN",
        &"HEAD_UP",
        &"HEAD_DOWN",
        &"HEAD_LEFT",
        &"HEAD_RIGHT"
    ]

    for orientation: StringName in required_orientations:
        if not faces.has(orientation):
            _add_error(
                result,
                "Energy die "
                + str(index + 1)
                + " is missing orientation "
                + String(orientation)
                + "."
            )
            continue

        var face_data: Variant = faces[orientation]

        if not face_data is Dictionary:
            _add_error(
                result,
                "Energy die "
                + str(index + 1)
                + " orientation "
                + String(orientation)
                + " is invalid."
            )
            continue

        var energies: Variant = (
            face_data as Dictionary
        ).get("energies", [])

        if not energies is Array:
            _add_error(
                result,
                "Energy die "
                + str(index + 1)
                + " orientation "
                + String(orientation)
                + " has invalid energies."
            )
            continue

        var expected_count: int = 1

        if (
            orientation == &"HEAD_UP"
            or orientation == &"HEAD_DOWN"
        ):
            expected_count = 2

        if energies.size() != expected_count:
            _add_error(
                result,
                "Energy die "
                + str(index + 1)
                + " orientation "
                + String(orientation)
                + " must contain "
                + str(expected_count)
                + " energy value(s)."
            )

        for raw_energy: Variant in energies:
            var energy_type: StringName = StringName(
                raw_energy
            )

            if not VALID_ENERGY_TYPES.has(
                energy_type
            ):
                _add_error(
                    result,
                    "Energy die "
                    + str(index + 1)
                    + " uses invalid energy "
                    + String(energy_type)
                    + "."
                )


static func _validate_legacy_die(
    result: Dictionary,
    die_config: Variant,
    index: int
) -> void:
    # Keep legacy Milestone tests usable.
    # A legacy die is accepted if it can still create a runtime profile.
    if die_config.has_method("create_profile"):
        var profile: Variant = die_config.create_profile()

        if profile != null:
            return

    _add_error(
        result,
        "Energy die "
        + str(index + 1)
        + " is neither a structured die nor a valid legacy die."
    )


static func _add_error(
    result: Dictionary,
    message: String
) -> void:
    result["success"] = false

    var errors: Array = result["errors"]
    errors.append(message)
