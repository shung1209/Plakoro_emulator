extends RefCounted


const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")


const SCHEMA_VERSION: String = "2.0"

const MOVE_DIRECTORY: String = (
    "res://database/move_cards"
)

const USER_MOVE_DIRECTORY: String = (
    "user://user_database/move_cards"
)

const VALID_CATEGORIES: Array[String] = [
    "attack",
    "defense",
    "support",
    "hybrid"
]

const VALID_TYPES: Array[String] = [
    "normal",
    "grass",
    "fire",
    "water",
    "electric",
    "psychic",
    "fighting",
    "dark",
    "steel",
    "flying"
]

const RUNTIME_COMPATIBILITY: Script = preload(
    "res://scripts/runtime/MoveRuntimeCompatibilityService.gd"
)
const KYOKORO_MAPPING: Script = preload(
    "res://scripts/runtime/KyokoroOrientationMappingService.gd"
)

const VALID_ENERGY_TYPES: Array[String] = [
    "normal",
    "grass",
    "fire",
    "water",
    "electric",
    "psychic",
    "fighting",
    "dark",
    "steel",
    "flying"
]


static func create_default() -> Dictionary:
    return {
        "schema_version": SCHEMA_VERSION,
        "id": "",
        "move_name_id": "",
        "owner_id": "",
        "display_name": "",
        "move_category": "attack",
        "attack_type": "normal",
        "energy_cost": [],
        "printed_damage": null,
        "base_actions": [],
        "outcome_rules": [],
        "special_effects": [],
        "resolution": {
            "outcome_match_mode": "zero_or_one",
            "action_execution_mode": "sequential"
        },
        "source": {
            "document": "",
            "page": 0,
            "card_code": "",
            "raw_text": ""
        },
        "review": {
            "status": "draft",
            "orientation_mapping_confirmed": false,
            "needs_manual_review": true,
            "notes": []
        }
    }


static func validate_basic(
    data: Dictionary
) -> Dictionary:
    var errors: Array[String] = []

    if String(
        data.get(
            "schema_version",
            ""
        )
    ) != SCHEMA_VERSION:
        errors.append(
            "schema_version must be "
            + SCHEMA_VERSION
            + "."
        )

    for field_name: String in [
        "id",
        "move_name_id",
        "owner_id",
        "display_name"
    ]:
        var value: String = String(
            data.get(
                field_name,
                ""
            )
        ).strip_edges()

        if value.is_empty():
            errors.append(
                field_name
                + " is required."
            )

    for id_field: String in [
        "id",
        "move_name_id",
        "owner_id"
    ]:
        var value: String = String(
            data.get(
                id_field,
                ""
            )
        ).strip_edges()

        if (
            not value.is_empty()
            and not _is_safe_id(
                value
            )
        ):
            errors.append(
                id_field
                + " may only use a-z, 0-9 and underscore."
            )

    var category: String = String(
        data.get(
            "move_category",
            ""
        )
    ).to_lower()

    if not VALID_CATEGORIES.has(
        category
    ):
        errors.append(
            "move_category is invalid."
        )

    var attack_type: String = String(
        data.get(
            "attack_type",
            ""
        )
    ).to_lower()

    if not VALID_TYPES.has(
        attack_type
    ):
        errors.append(
            "attack_type is invalid."
        )

    var damage: Variant = data.get(
        "printed_damage",
        null
    )

    if (
        damage != null
        and int(damage) < 0
    ):
        errors.append(
            "printed_damage cannot be negative."
        )

    for array_field: String in [
        "energy_cost",
        "base_actions",
        "outcome_rules",
        "special_effects"
    ]:
        if not (
            data.get(
                array_field,
                []
            )
            is Array
        ):
            errors.append(
                array_field
                + " must be an array."
            )

    var energy_cost: Variant = data.get(
        "energy_cost",
        []
    )

    if energy_cost is Array:
        var seen_energy_types: Dictionary = {}

        for raw_cost: Variant in energy_cost:
            if not raw_cost is Dictionary:
                errors.append(
                    "Each energy_cost entry must be an object."
                )
                continue

            var cost: Dictionary = (
                raw_cost as Dictionary
            )

            var energy_type: String = String(
                cost.get(
                    "energy_type",
                    ""
                )
            ).to_lower()

            if not VALID_ENERGY_TYPES.has(
                energy_type
            ):
                errors.append(
                    "Invalid energy_cost type: "
                    + energy_type
                )
                continue

            if seen_energy_types.has(
                energy_type
            ):
                errors.append(
                    "Duplicate energy_cost type: "
                    + energy_type
                )

            seen_energy_types[
                energy_type
            ] = true

            if int(
                cost.get(
                    "count",
                    0
                )
            ) <= 0:
                errors.append(
                    "energy_cost count must be greater than 0 for "
                    + energy_type
                    + "."
                )


    var base_actions: Variant = data.get(
        "base_actions",
        []
    )

    if base_actions is Array:
        for raw_action: Variant in base_actions:
            if not _is_valid_action(
                raw_action
            ):
                errors.append(
                    "base_actions contains an invalid action."
                )

    var outcome_rules: Variant = data.get(
        "outcome_rules",
        []
    )

    if outcome_rules is Array:
        for raw_rule: Variant in outcome_rules:
            if not raw_rule is Dictionary:
                errors.append(
                    "Each outcome_rules entry must be an object."
                )
                continue

            var rule: Dictionary = (
                raw_rule as Dictionary
            )

            var condition: Variant = rule.get(
                "condition",
                {}
            )

            if not condition is Dictionary:
                errors.append(
                    "Outcome rule condition must be an object."
                )
                continue

            var condition_dict: Dictionary = (
                condition as Dictionary
            )

            if String(
                condition_dict.get(
                    "type",
                    ""
                )
            ) != "kyokoro_orientation_any":
                errors.append(
                    "10.1c outcome condition type must be kyokoro_orientation_any."
                )

            var orientations: Variant = (
                condition_dict.get(
                    "orientations",
                    []
                )
            )

            if (
                not orientations is Array
                or (
                    orientations as Array
                ).is_empty()
            ):
                errors.append(
                    "Each outcome rule must select at least one Charakoro orientation."
                )
            elif orientations is Array:
                for raw_orientation: Variant in (
                    orientations as Array
                ):
                    if not KYOKORO_MAPPING.is_valid_orientation(
                        String(
                            raw_orientation
                        )
                    ):
                        errors.append(
                            "Invalid Charakoro orientation: "
                            + String(
                                raw_orientation
                            )
                        )

            var actions: Variant = rule.get(
                "actions",
                []
            )

            if not actions is Array:
                errors.append(
                    "Outcome rule actions must be an array."
                )
            else:
                for raw_action: Variant in actions:
                    if not _is_valid_action(
                        raw_action
                    ):
                        errors.append(
                            "outcome_rules contains an invalid action."
                        )

    var resolution_data: Variant = data.get(
        "resolution",
        {}
    )

    if not resolution_data is Dictionary:
        errors.append(
            "resolution must be an object."
        )
    else:
        var outcome_match_mode: String = String(
            (resolution_data as Dictionary).get(
                "outcome_match_mode",
                "zero_or_one"
            )
        )

        if (
            outcome_match_mode == "zero_or_one"
            and outcome_rules is Array
        ):
            var orientation_owners: Dictionary = {}

            for rule_index: int in range(
                (outcome_rules as Array).size()
            ):
                var raw_rule: Variant = (
                    outcome_rules as Array
                )[rule_index]

                if not raw_rule is Dictionary:
                    continue

                var condition: Variant = (
                    raw_rule as Dictionary
                ).get(
                    "condition",
                    {}
                )

                if not condition is Dictionary:
                    continue

                var orientations: Variant = (
                    condition as Dictionary
                ).get(
                    "orientations",
                    []
                )

                if not orientations is Array:
                    continue

                for raw_orientation: Variant in (
                    orientations as Array
                ):
                    var orientation: String = String(
                        raw_orientation
                    )

                    if orientation_owners.has(
                        orientation
                    ):
                        errors.append(
                            "Multiple outcome rules match "
                            + orientation
                            + " while resolution.outcome_match_mode is zero_or_one "
                            + "(rules "
                            + str(
                                int(
                                    orientation_owners[
                                        orientation
                                    ]
                                )
                                + 1
                            )
                            + " and "
                            + str(rule_index + 1)
                            + ")."
                        )
                    else:
                        orientation_owners[
                            orientation
                        ] = rule_index

    if not (
        data.get(
            "source",
            {}
        )
        is Dictionary
    ):
        errors.append(
            "source must be an object."
        )

    if not (
        data.get(
            "review",
            {}
        )
        is Dictionary
    ):
        errors.append(
            "review must be an object."
        )

    var runtime_report: Dictionary = (
        RUNTIME_COMPATIBILITY.inspect_move_document(data)
    )
    if not bool(runtime_report.get("success", false)):
        for raw_error: Variant in runtime_report.get("errors", []):
            errors.append(String(raw_error))

    return {
        "success": errors.is_empty(),
        "errors": errors
    }


static func list_saved() -> Array[String]:
    var result: Array[String] = BUILTIN_MANIFEST.ids_for("move_cards")
    var directory: DirAccess = DirAccess.open(USER_MOVE_DIRECTORY)
    if directory != null:
        directory.list_dir_begin()
        while true:
            var file_name: String = directory.get_next()
            if file_name.is_empty():
                break
            if directory.current_is_dir() or not file_name.ends_with(".json"):
                continue
            var move_id: String = file_name.trim_suffix(".json")
            if not result.has(move_id):
                result.append(move_id)
        directory.list_dir_end()
    result.sort()
    return result


static func load_by_id(
    move_id: String
) -> Dictionary:
    var safe_id: String = (
        move_id.strip_edges().to_lower()
    )

    if safe_id.is_empty():
        return {}

    var path: String = USER_MOVE_DIRECTORY + "/" + safe_id + ".json"
    if not FileAccess.file_exists(path):
        path = MOVE_DIRECTORY + "/" + safe_id + ".json"
    if not FileAccess.file_exists(path):
        return {}

    var file: FileAccess = FileAccess.open(
        path,
        FileAccess.READ
    )

    if file == null:
        return {}

    var parsed: Variant = JSON.parse_string(
        file.get_as_text()
    )

    if parsed is Dictionary:
        return parsed

    return {}


static func save_basic_preserving_complex(
    data: Dictionary
) -> Dictionary:
    var validation: Dictionary = (
        validate_basic(
            data
        )
    )

    if not bool(
        validation["success"]
    ):
        return validation

    var directory_error: Error = (
        DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(
                USER_MOVE_DIRECTORY
            )
        )
    )

    if (
        directory_error != OK
        and directory_error != ERR_ALREADY_EXISTS
    ):
        return {
            "success": false,
            "errors": [
                "Could not create user://user_database/move_cards."
            ]
        }

    var move_id: String = String(
        data["id"]
    ).strip_edges().to_lower()

    var path: String = (
        USER_MOVE_DIRECTORY
        + "/"
        + move_id
        + ".json"
    )

    var file: FileAccess = FileAccess.open(
        path,
        FileAccess.WRITE
    )

    if file == null:
        return {
            "success": false,
            "errors": [
                "Could not write "
                + path
                + "."
            ]
        }

    file.store_string(
        JSON.stringify(
            _ordered_document(
                data
            ),
            "  "
        )
    )

    return {
        "success": true,
        "errors": [],
        "path": path
    }


static func energy_cost_summary(
    data: Dictionary
) -> String:
    var energy_cost: Variant = data.get(
        "energy_cost",
        []
    )

    if not energy_cost is Array:
        return "Invalid energy_cost."

    var lines: Array[String] = []

    for raw_cost: Variant in energy_cost:
        if not raw_cost is Dictionary:
            continue

        var cost: Dictionary = (
            raw_cost as Dictionary
        )

        lines.append(
            String(
                cost.get(
                    "energy_type",
                    "?"
                )
            )
            + " × "
            + str(
                int(
                    cost.get(
                        "count",
                        0
                    )
                )
            )
        )

    return (
        "None"
        if lines.is_empty()
        else "\n".join(
            lines
        )
    )


static func _ordered_document(
    source: Dictionary
) -> Dictionary:
    # Keep the current Move Card V2 envelope and preserve the complex blocks
    # exactly until their dedicated editors arrive in later 10.1 milestones.
    var result: Dictionary = {
        "schema_version": SCHEMA_VERSION,
        "id": String(
            source.get(
                "id",
                ""
            )
        ),
        "move_name_id": String(
            source.get(
                "move_name_id",
                ""
            )
        ),
        "owner_id": String(
            source.get(
                "owner_id",
                ""
            )
        ),
        "display_name": String(
            source.get(
                "display_name",
                ""
            )
        ),
        "move_category": String(
            source.get(
                "move_category",
                "attack"
            )
        ),
        "attack_type": String(
            source.get(
                "attack_type",
                "normal"
            )
        ),
        "energy_cost": source.get(
            "energy_cost",
            []
        ),
        "printed_damage": source.get(
            "printed_damage",
            null
        ),
        "base_actions": source.get(
            "base_actions",
            []
        ),
        "outcome_rules": source.get(
            "outcome_rules",
            []
        ),
        "special_effects": source.get(
            "special_effects",
            []
        ),
        "resolution": source.get(
            "resolution",
            {}
        ),
        "source": source.get(
            "source",
            {}
        ),
        "review": source.get(
            "review",
            {}
        )
    }

    return result



static func _is_valid_action(
    raw_action: Variant
) -> bool:
    if not raw_action is Dictionary:
        return false

    var action: Dictionary = (
        raw_action as Dictionary
    )

    var opcode: String = String(
        action.get(
            "opcode",
            ""
        )
    )

    if opcode.is_empty():
        return false

    if not (
        action.get(
            "args",
            {}
        )
        is Dictionary
    ):
        return false

    return true


static func _is_safe_id(
    content_id: String
) -> bool:
    for character: String in content_id:
        var code: int = (
            character.unicode_at(0)
        )

        var is_lower: bool = (
            code >= 97
            and code <= 122
        )
        var is_digit: bool = (
            code >= 48
            and code <= 57
        )

        if (
            not is_lower
            and not is_digit
            and character != "_"
        ):
            return false

    return true
