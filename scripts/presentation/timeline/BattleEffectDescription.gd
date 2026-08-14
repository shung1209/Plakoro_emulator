extends RefCounted


static func describe_actions(
    actions: Array,
    source_label: String
) -> Array[String]:
    var result: Array[String] = []

    for action: Variant in actions:
        var opcode: StringName = StringName(
            action.opcode
        )
        var args: Dictionary = action.args

        match opcode:
            &"damage.create":
                result.append(
                    _join([
                        source_label,
                        "creates",
                        str(int(args.get("amount", 0))),
                        "base damage."
                    ])
                )

            &"damage.add":
                result.append(
                    _join([
                        source_label,
                        "adds",
                        str(int(args.get("amount", 0))),
                        "damage."
                    ])
                )

            &"damage.set":
                result.append(
                    _join([
                        source_label,
                        "sets damage to",
                        str(int(args.get("amount", 0))) + "."
                    ])
                )

            &"damage.deal":
                result.append(
                    _join([
                        source_label,
                        "deals",
                        str(int(args.get("amount", 0))),
                        "direct damage to",
                        String(args.get("target", "opponent")) + "."
                    ])
                )

            &"hp.restore":
                result.append(
                    _join([
                        source_label,
                        "restores",
                        str(int(args.get("amount", 0))),
                        "HP to",
                        String(args.get("target", "self")) + "."
                    ])
                )

            &"incoming_damage.modify":
                result.append(
                    _describe_status_value(
                        source_label,
                        &"incoming_damage_modifier",
                        int(args.get("amount", 0))
                    )
                )

            &"energy_dice.modify":
                result.append(
                    _describe_status_value(
                        source_label,
                        &"energy_dice_modifier",
                        int(args.get("amount", 0))
                    )
                )

            &"move.repeat_permission":
                result.append(
                    _join([
                        source_label,
                        "allows the specified move to be used again."
                    ])
                )

            &"weakness.disable":
                result.append(
                    _join([
                        source_label,
                        "disables weakness calculation for the next move."
                    ])
                )

            &"status.add":
                result.append(
                    _describe_status_value(
                        source_label,
                        StringName(
                            args.get("status_type", "")
                        ),
                        int(args.get("value", 0))
                    )
                )

            &"condition.if":
                result.append(
                    _join([
                        source_label,
                        "evaluates a conditional effect."
                    ])
                )

            _:
                result.append(
                    _join([
                        source_label,
                        "executes",
                        String(opcode) + "."
                    ])
                )

    return result


static func describe_status(
    status_type: StringName,
    value: int
) -> String:
    return _describe_status_value(
        "Status",
        status_type,
        value
    )


static func _describe_status_value(
    source_label: String,
    status_type: StringName,
    value: int
) -> String:
    match status_type:
        &"incoming_damage_modifier":
            if value < 0:
                return _join([
                    source_label,
                    "reduces the next incoming attack by",
                    str(abs(value)),
                    "damage."
                ])

            return _join([
                source_label,
                "increases the next incoming attack by",
                str(value),
                "damage."
            ])

        &"energy_dice_modifier":
            if value >= 0:
                return _join([
                    source_label,
                    "adds",
                    str(value),
                    "energy die/dice to the next applicable roll."
                ])

            return _join([
                source_label,
                "removes",
                str(abs(value)),
                "energy die/dice from the next applicable roll."
            ])

        &"repeat_move_permission":
            return _join([
                source_label,
                "allows the specified move to be used again."
            ])

        &"weakness_disable":
            return _join([
                source_label,
                "disables weakness calculation for the next move."
            ])

        _:
            return _join([
                source_label,
                "applies",
                String(status_type),
                "with value",
                str(value) + "."
            ])


static func _join(parts: Array) -> String:
    var strings: Array[String] = []

    for part: Variant in parts:
        strings.append(String(part))

    return " ".join(strings)
