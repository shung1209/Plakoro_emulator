extends RefCounted

const CURRENT_BUILDER_VERSION: String = "9.7"

static func validate_for_loading(
    draft: Variant,
    expected_pokemon_id: StringName
) -> Dictionary:
    var result: Dictionary = {"success": true, "errors": []}

    if draft == null:
        _add_error(result, "Draft is null.")
        return result

    if draft.metadata.draft_type != &"move_builder":
        _add_error(result, "Draft type is not move_builder.")

    if draft.metadata.builder_version != CURRENT_BUILDER_VERSION:
        _add_error(result, "Draft builder version is incompatible.")

    if draft.pokemon_id == &"":
        _add_error(result, "Draft Pokémon is missing.")

    if (
        expected_pokemon_id != &""
        and draft.pokemon_id != expected_pokemon_id
    ):
        _add_error(result, "Draft belongs to a different Pokémon.")

    if draft.selected_move_ids.size() > 4:
        _add_error(result, "Draft contains more than four moves.")

    return result

static func _add_error(result: Dictionary, message: String) -> void:
    result["success"] = false
    var errors: Array = result["errors"]
    errors.append(message)
