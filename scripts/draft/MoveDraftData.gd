extends RefCounted

const BUILDER_DRAFT_DATA: Script = preload(
    "res://scripts/draft/BuilderDraftData.gd"
)

var metadata: Variant = BUILDER_DRAFT_DATA.new()
var pokemon_id: StringName = &""
var selected_move_ids: Array[StringName] = []

func _init() -> void:
    metadata.draft_type = &"move_builder"

func is_complete_enough_to_edit() -> bool:
    return pokemon_id != &"" and selected_move_ids.size() <= 4

func to_dictionary() -> Dictionary:
    metadata.touch()
    var result: Dictionary = metadata.to_base_dictionary()
    var serialized_moves: Array[String] = []
    for move_id: StringName in selected_move_ids:
        serialized_moves.append(String(move_id))
    result["pokemon_id"] = String(pokemon_id)
    result["selected_move_ids"] = serialized_moves
    return result

static func from_dictionary(data: Dictionary) -> Variant:
    var result: Variant = new()
    result.metadata.load_base_dictionary(data)
    result.pokemon_id = StringName(data.get("pokemon_id", ""))
    var raw_moves: Variant = data.get("selected_move_ids", [])
    if raw_moves is Array:
        for raw_move: Variant in raw_moves:
            result.selected_move_ids.append(StringName(raw_move))
    return result
