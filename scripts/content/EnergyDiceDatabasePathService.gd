extends RefCounted


const DICE_SETUP_DIRECTORY: String = (
    "res://database/dice_setups"
)

const USER_DICE_SETUP_DIRECTORY: String = (
    "user://user_database/dice_setups"
)

const PLAYER_SETUP_ID: String = (
    "player_energy_dice_setup"
)

const PLAYER_SETUP_PATH: String = (
    USER_DICE_SETUP_DIRECTORY
    + "/"
    + PLAYER_SETUP_ID
    + ".json"
)


static func ensure_database_directory() -> bool:
    var absolute_path: String = (
        ProjectSettings.globalize_path(
            DICE_SETUP_DIRECTORY
        )
    )

    var result: Error = (
        DirAccess.make_dir_recursive_absolute(
            absolute_path
        )
    )

    return (
        result == OK
        or result == ERR_ALREADY_EXISTS
    )


static func ensure_user_database_directory() -> bool:
    var absolute_path: String = ProjectSettings.globalize_path(USER_DICE_SETUP_DIRECTORY)
    var result: Error = DirAccess.make_dir_recursive_absolute(absolute_path)
    return result == OK or result == ERR_ALREADY_EXISTS
