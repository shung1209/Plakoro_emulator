extends RefCounted


const BATTLE_MOVE_SELECTION_OWNER: StringName = (
    &"configure_battle"
)
const MOVE_CONTENT_EDIT_OWNER: StringName = (
    &"content_studio"
)
const PLAYER_ENERKORO_EDIT_OWNER: StringName = (
    &"energy_dice_builder"
)


static func battle_preparation_actions() -> Array[StringName]:
    return [
        &"refresh",
        &"edit_enerkoro",
        &"configure_battle",
        &"start_battle"
    ]


static func should_expose_move_builder_in_preparation() -> bool:
    return false


static func configure_battle_owns_move_selection() -> bool:
    return true


static func content_studio_owns_move_content_editing() -> bool:
    return true
