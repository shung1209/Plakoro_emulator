extends RefCounted


const TARGET_OPTIONS: Array[String] = [
    "self",
    "opponent"
]


static func get_metadata(
    opcode: StringName
) -> Dictionary:
    var all: Dictionary = get_all()
    return (
        (all.get(opcode, {}) as Dictionary)
        .duplicate(true)
    )


static func get_all() -> Dictionary:
    return {
        &"turn.end": _entry(
            "Battle / End Turn",
            "Battle",
            "Ends the current action sequence.",
            []
        ),
        &"condition.if": _entry(
            "Conditional Branch",
            "Condition",
            "Runs nested actions when a condition matches.",
            [
                _field(
                    "condition",
                    "Condition",
                    "condition",
                    {},
                    true
                )
            ],
            true
        ),
        &"damage.add": _entry(
            "Add Damage",
            "Damage",
            "Adds a fixed amount to the current damage context.",
            [
                _int_field("amount", "Amount", 0, 0)
            ],
            false,
            false,
            ["target"]
        ),
        &"damage.add_per_energy": _entry(
            LocalizationService.tr_key("opcode.add_damage_per_energy", "Add Damage per Energy"),
            "Damage",
            "Adds damage for each matching rolled energy symbol.",
            [
                _string_field(
                    "energy_type",
                    LocalizationService.tr_key("opcode.energy_type", "Energy Type"),
                    ""
                ),
                _int_field(
                    "amount_per_energy",
                    LocalizationService.tr_key("opcode.damage_per_energy", "Damage per Energy"),
                    0,
                    0
                )
            ]
        ),
        &"damage.copy_previous_opponent_move": _entry(
            "Copy Previous Opponent Move Damage",
            "Damage",
            "Copies damage information from the opponent's previous Move.",
            [],
            false,
            false,
            [
                "copy",
                "ignore_copied_kyokoro_effects"
            ]
        ),
        &"damage.create": _entry(
            "Create Damage",
            "Damage",
            "Creates the base Move damage.",
            [
                _int_field("amount", "Amount", 0, 0),
                _string_field(
                    "damage_type",
                    "Damage Type",
                    ""
                )
            ],
            false,
            false,
            ["target", "source"]
        ),
        &"damage.deal": _entry(
            "Deal Damage",
            "Damage",
            "Queues direct damage to a selected target.",
            [
                _enum_field(
                    "target",
                    "Target",
                    "opponent",
                    TARGET_OPTIONS
                ),
                _int_field("amount", "Amount", 0, 0),
                _string_field(
                    "damage_type",
                    "Damage Type",
                    "direct"
                )
            ]
        ),
        &"damage.multiply": _entry(
            "Multiply Damage",
            "Damage",
            "Multiplies the current damage value.",
            [
                _float_field(
                    "factor",
                    "Factor",
                    1.0,
                    0.0
                )
            ]
        ),
        &"damage.recoil": _entry(
            "Recoil / Self Damage",
            "Damage",
            "Deals damage to the Move user.",
            [
                _int_field("amount", "Self Damage", 0, 0)
            ]
        ),
        &"damage.set": _entry(
            "Set Damage",
            "Damage",
            "Replaces the current damage value.",
            [
                _int_field("amount", "Amount", 0, 0)
            ]
        ),
        &"energy_dice.modify": _entry(
            LocalizationService.tr_key("opcode.modify_energy_dice", "Modify Energy Dice"),
            LocalizationService.tr_key("opcode.dice_energy", "Dice / Energy"),
            "Temporarily modifies the target's energy dice result.",
            [
                _enum_field(
                    "target",
                    "Target",
                    "self",
                    TARGET_OPTIONS
                ),
                _int_field("amount", "Modifier", 0),
                _int_field(
                    "duration_turns",
                    "Duration (Turns)",
                    0,
                    0
                ),
                _int_field(
                    "remaining_uses",
                    "Remaining Uses",
                    1,
                    0
                )
            ]
        ),
        &"hp.restore": _entry(
            "Restore HP",
            "HP",
            "Restores HP to the selected target.",
            [
                _enum_field(
                    "target",
                    "Target",
                    "self",
                    TARGET_OPTIONS
                ),
                _int_field("amount", "Amount", 0, 0)
            ]
        ),
        &"move.lock": _entry(
            "Lock Move",
            "Move",
            "Prevents a Move from being used according to its status lifecycle.",
            [
                _enum_field(
                    "target",
                    "Target",
                    "opponent",
                    TARGET_OPTIONS
                ),
                _string_field(
                    "move_name_id",
                    "Move Name ID",
                    ""
                ),
                _int_field(
                    "duration_turns",
                    "Duration (Turns)",
                    1,
                    1
                )
            ]
        ),
        &"move.repeat_permission": _entry(
            "Allow Move Repeat",
            "Move",
            "Allows a Move to bypass the consecutive-use restriction.",
            [
                _enum_field(
                    "target",
                    "Target",
                    "self",
                    TARGET_OPTIONS
                ),
                _string_field(
                    "move_name_id",
                    "Move Name ID",
                    ""
                ),
                _int_field(
                    "remaining_uses",
                    "Remaining Uses",
                    1,
                    0
                )
            ]
        ),
        &"incoming_damage.immunity": _entry(
            "Incoming Damage Immunity",
            "Status",
            "Makes the selected target immune to incoming attack damage.",
            [
                _enum_field(
                    "target",
                    "Target",
                    "self",
                    TARGET_OPTIONS
                ),
                _int_field(
                    "duration_turns",
                    "Duration (Turns)",
                    1,
                    1
                )
            ]
        ),
        &"incoming_damage.modify": _entry(
            "Modify Incoming Damage",
            "Status",
            "Adds a temporary incoming-damage modifier.",
            [
                _enum_field(
                    "target",
                    "Target",
                    "self",
                    TARGET_OPTIONS
                ),
                _int_field("amount", "Modifier", 0),
                _int_field(
                    "duration_turns",
                    "Duration (Turns)",
                    0,
                    0
                ),
                _int_field(
                    "remaining_uses",
                    "Remaining Uses",
                    1,
                    0
                )
            ]
        ),
        &"status.add": _entry(
            "Add Status",
            "Status",
            "Adds a status payload with visual temporary/lifecycle controls.",
            [
                _enum_field(
                    "target",
                    "Target",
                    "self",
                    TARGET_OPTIONS
                ),
                _string_field(
                    "status_type",
                    "Status Type",
                    ""
                ),
                _field(
                    "lifecycle",
                    "Lifecycle",
                    "lifecycle",
                    {}
                )
            ]
        ),
        &"weakness.disable": _entry(
            "Disable Weakness",
            "Weakness",
            "Disables weakness for the target's next Move.",
            [
                _enum_field(
                    "target",
                    "Target",
                    "self",
                    TARGET_OPTIONS
                )
            ]
        ),
        &"weakness.ignore_current": _entry(
            "Ignore Weakness for Current Move",
            "Weakness",
            "Skips weakness bonus during the current Move resolution.",
            []
        )
    }


static func _entry(
    display_name: String,
    category: String,
    description: String,
    fields: Array,
    supports_nested_actions: bool = false,
    allow_extra_args: bool = false,
    preserved_hidden_args: Array[String] = []
) -> Dictionary:
    return {
        "display_name": display_name,
        "category": category,
        "description": description,
        "fields": fields,
        "supports_nested_actions": supports_nested_actions,
        "allow_extra_args": allow_extra_args,
        "preserved_hidden_args": preserved_hidden_args.duplicate()
    }


static func _field(
    key: String,
    label: String,
    value_type: String,
    default_value: Variant,
    required: bool = false
) -> Dictionary:
    return {
        "key": key,
        "label": label,
        "type": value_type,
        "default": default_value,
        "required": required
    }


static func _int_field(
    key: String,
    label: String,
    default_value: int,
    minimum: Variant = null
) -> Dictionary:
    var result: Dictionary = _field(
        key,
        label,
        "int",
        default_value
    )
    if minimum != null:
        result["min"] = minimum
    return result


static func _float_field(
    key: String,
    label: String,
    default_value: float,
    minimum: Variant = null
) -> Dictionary:
    var result: Dictionary = _field(
        key,
        label,
        "float",
        default_value
    )
    if minimum != null:
        result["min"] = minimum
    return result


static func _string_field(
    key: String,
    label: String,
    default_value: String
) -> Dictionary:
    return _field(
        key,
        label,
        "string",
        default_value
    )


static func _enum_field(
    key: String,
    label: String,
    default_value: String,
    options: Array[String]
) -> Dictionary:
    var result: Dictionary = _field(
        key,
        label,
        "enum",
        default_value
    )
    result["options"] = options.duplicate()
    return result
