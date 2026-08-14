extends RefCounted


const STATUS_RESOLVER: Script = preload(
    "res://scripts/battle/status/StatusResolver.gd"
)


static func get_weakness_bonus(
    attacker: Variant,
    defender: Variant,
    move_card: Variant
) -> int:
    return int(
        get_weakness_bonus_report(
            attacker,
            defender,
            move_card
        ).get(
            "bonus",
            0
        )
    )


static func get_weakness_bonus_report(
    attacker: Variant,
    defender: Variant,
    move_card: Variant
) -> Dictionary:
    var disable_report: Dictionary = (
        STATUS_RESOLVER
        .consume_weakness_disable_report(
            attacker
        )
    )

    if bool(
        disable_report.get(
            "consumed",
            false
        )
    ):
        return {
            "bonus": 0,
            "weakness_disabled": true,
            "status_report": disable_report
        }

    if StringName(
        move_card.attack_type
    ) == &"":
        return {
            "bonus": 0,
            "weakness_disabled": false,
            "status_report": {}
        }

    return {
        "bonus": int(
            defender.pokemon_data.get_weakness_bonus(
                StringName(
                    move_card.attack_type
                )
            )
        ),
        "weakness_disabled": false,
        "status_report": {}
    }
