extends RefCounted


const ACTION_DATA: Script = preload(
    "res://scripts/data/ActionData.gd"
)


static func compile_effect(
    effect: Variant
) -> Variant:
    if effect == null:
        return null

    var effect_type: StringName = StringName(
        effect.effect_type
    )
    var parameters: Dictionary = effect.parameters

    match effect_type:
        &"damage.create":
            return ACTION_DATA.new(
                &"damage.create",
                {
                    "amount": int(
                        parameters.get("amount", 0)
                    ),
                    "damage_type": parameters.get(
                        "damage_type",
                        ""
                    ),
                    "target": parameters.get(
                        "target",
                        "opponent"
                    )
                }
            )

        &"damage.add":
            return ACTION_DATA.new(
                &"damage.add",
                {
                    "amount": int(
                        parameters.get("amount", 0)
                    ),
                    "target": parameters.get(
                        "target",
                        "opponent"
                    )
                }
            )

        &"damage.deal":
            return ACTION_DATA.new(
                &"damage.deal",
                {
                    "amount": int(
                        parameters.get("amount", 0)
                    ),
                    "target": parameters.get(
                        "target",
                        "opponent"
                    ),
                    "damage_type": parameters.get(
                        "damage_type",
                        "direct"
                    )
                }
            )

        &"hp.restore":
            return ACTION_DATA.new(
                &"hp.restore",
                {
                    "amount": int(
                        parameters.get("amount", 0)
                    ),
                    "target": parameters.get(
                        "target",
                        "self"
                    )
                }
            )

        &"status.add":
            var args: Dictionary = parameters.duplicate(true)
            return ACTION_DATA.new(
                &"status.add",
                args
            )

        &"energy_dice.modify":
            return ACTION_DATA.new(
                &"energy_dice.modify",
                {
                    "amount": int(
                        parameters.get("amount", 0)
                    ),
                    "target": parameters.get(
                        "target",
                        "self"
                    )
                }
            )

        &"move.repeat_permission":
            return ACTION_DATA.new(
                &"move.repeat_permission",
                {
                    "target": parameters.get(
                        "target",
                        "self"
                    ),
                    "move_name_id": parameters.get(
                        "move_name_id",
                        ""
                    )
                }
            )

        &"weakness.disable":
            return ACTION_DATA.new(
                &"weakness.disable",
                {
                    "target": parameters.get(
                        "target",
                        "self"
                    )
                }
            )

        _:
            push_error(
                "EffectCompiler: unsupported effect type '%s'."
                % String(effect_type)
            )
            return null
