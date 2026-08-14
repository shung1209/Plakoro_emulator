extends RefCounted

const MOVE_DRAFT_DATA: Script = preload(
    "res://scripts/draft/MoveDraftData.gd"
)
const SAVE_SERVICE: Script = preload(
    "res://scripts/draft/MoveDraftSaveService.gd"
)
const DRAFT_VALIDATOR: Script = preload(
    "res://scripts/draft/MoveDraftValidator.gd"
)
const PLAYER_LOADOUT_PROVIDER: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
)

const DRAFT_PATH: String = "user://player_move_builder_draft.json"

static func load_or_create_draft() -> Variant:
    var loadout: Variant = PLAYER_LOADOUT_PROVIDER.load_player_loadout()
    if loadout == null:
        return null

    if FileAccess.file_exists(DRAFT_PATH):
        var draft: Variant = SAVE_SERVICE.load_draft(DRAFT_PATH)
        var validation: Dictionary = DRAFT_VALIDATOR.validate_for_loading(
            draft,
            loadout.pokemon_id
        )
        if bool(validation["success"]):
            return draft
        SAVE_SERVICE.delete_draft(DRAFT_PATH)

    return create_from_loadout(loadout)

static func create_from_loadout(loadout: Variant) -> Variant:
    if loadout == null:
        return null

    var draft: Variant = MOVE_DRAFT_DATA.new()
    draft.pokemon_id = loadout.pokemon_id
    for move_id: StringName in loadout.move_card_ids:
        draft.selected_move_ids.append(move_id)
    return draft

static func save_draft(draft: Variant) -> bool:
    return SAVE_SERVICE.save_draft(draft, DRAFT_PATH)

static func discard_draft() -> bool:
    return SAVE_SERVICE.delete_draft(DRAFT_PATH)

static func has_draft() -> bool:
    return FileAccess.file_exists(DRAFT_PATH)
