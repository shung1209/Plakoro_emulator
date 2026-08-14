extends RefCounted


const PLAYER_STYLE_VALIDATOR: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutValidator.gd"
)


const VALID_DIFFICULTIES: Array[StringName] = [
    &"easy",
    &"normal",
    &"hard"
]


static func validate(
    loadout_data: Variant,
    database: Variant
) -> Dictionary:
    var result: Dictionary = (
        PLAYER_STYLE_VALIDATOR.validate(
            loadout_data,
            database
        )
    )

    if loadout_data == null:
        return result

    if not VALID_DIFFICULTIES.has(
        StringName(loadout_data.difficulty)
    ):
        result["success"] = false
        var errors: Array = result["errors"]
        errors.append(
            "Unsupported AI difficulty: "
            + String(loadout_data.difficulty)
        )

    return result
