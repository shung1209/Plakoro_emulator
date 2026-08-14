extends RefCounted


const PROVIDER: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
)
const SAVE_SERVICE: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutSaveService.gd"
)


static func ensure_user_loadout_exists() -> bool:
    if FileAccess.file_exists(
        PROVIDER.USER_LOADOUT_PATH
    ):
        return true

    var default_loadout: Variant = (
        PROVIDER.create_default_player_loadout()
    )

    if default_loadout == null:
        return false

    return SAVE_SERVICE.save_loadout(
        default_loadout,
        PROVIDER.USER_LOADOUT_PATH
    )
