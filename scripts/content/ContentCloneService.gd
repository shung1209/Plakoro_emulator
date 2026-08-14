extends RefCounted

const POKEMON: Script = preload("res://scripts/content/PokemonAuthoringService.gd")
const MOVE: Script = preload("res://scripts/content/MoveCardAuthoringService.gd")
const KYOKORO: Script = preload("res://scripts/content/KyokoroProfileAuthoringService.gd")

const MODE_POKEMON: StringName = &"pokemon"
const MODE_KYOKORO: StringName = &"kyokoro"
const MODE_MOVE: StringName = &"move"


static func duplicate_content(mode: StringName, source_id: String) -> Dictionary:
    var source: Dictionary = _load_source(mode, source_id)
    if source.is_empty():
        return {
            "success": false,
            "errors": ["Could not load the selected content."]
        }

    var copy: Dictionary = source.duplicate(true)
    var new_id: String = _next_copy_id(mode, source_id)
    copy["id"] = new_id

    if mode == MODE_POKEMON or mode == MODE_MOVE:
        var display_name: String = String(
            copy.get("display_name", source_id)
        ).strip_edges()
        if display_name.is_empty():
            display_name = source_id
        copy["display_name"] = display_name + " Copy"

    _reset_clone_metadata(mode, copy)

    var save_result: Dictionary = _save_clone(mode, copy)
    if not bool(save_result.get("success", false)):
        return save_result

    return {
        "success": true,
        "errors": [],
        "id": new_id,
        "document": copy,
        "path": String(save_result.get("path", ""))
    }


static func _load_source(mode: StringName, source_id: String) -> Dictionary:
    match mode:
        MODE_POKEMON:
            return POKEMON.load_by_id(source_id)
        MODE_KYOKORO:
            return KYOKORO.load_by_id(source_id)
        MODE_MOVE:
            return MOVE.load_by_id(source_id)
    return {}


static func _save_clone(mode: StringName, data: Dictionary) -> Dictionary:
    match mode:
        MODE_POKEMON:
            return POKEMON.save(data)
        MODE_KYOKORO:
            return KYOKORO.save(data)
        MODE_MOVE:
            return MOVE.save_basic_preserving_complex(data)
    return {
        "success": false,
        "errors": ["Unsupported content type."]
    }


static func _next_copy_id(mode: StringName, source_id: String) -> String:
    var base: String = source_id.strip_edges().to_lower()
    if base.is_empty():
        base = "copy"

    var existing: Array[String] = _list_ids(mode)
    var candidate: String = base + "_copy"
    if not existing.has(candidate):
        return candidate

    var suffix: int = 2
    while existing.has(base + "_copy_" + str(suffix)):
        suffix += 1
    return base + "_copy_" + str(suffix)


static func _list_ids(mode: StringName) -> Array[String]:
    match mode:
        MODE_POKEMON:
            return POKEMON.list_saved()
        MODE_KYOKORO:
            return KYOKORO.list_saved()
        MODE_MOVE:
            return MOVE.list_saved()
    return []


static func _reset_clone_metadata(mode: StringName, data: Dictionary) -> void:
    # A clone is new user-authored content. It must not claim the provenance
    # or review state of the original built-in/user document.
    data.erase("source")
    data.erase("review")

    if mode == MODE_MOVE:
        data["source"] = {
            "document": "",
            "page": 0,
            "card_code": "",
            "raw_text": ""
        }
        data["review"] = {
            "status": "draft",
            "orientation_mapping_confirmed": false,
            "needs_manual_review": true,
            "notes": []
        }
