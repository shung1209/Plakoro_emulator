extends RefCounted

static func compare(draft: Variant, loadout: Variant) -> Dictionary:
    var result: Dictionary = {
        "added": [],
        "removed": [],
        "changed": false
    }

    if draft == null or loadout == null:
        return result

    var loadout_ids: Array[StringName] = []
    for move_id: StringName in loadout.move_card_ids:
        loadout_ids.append(move_id)

    for move_id: StringName in draft.selected_move_ids:
        if not loadout_ids.has(move_id):
            result["added"].append(move_id)

    for move_id: StringName in loadout_ids:
        if not draft.selected_move_ids.has(move_id):
            result["removed"].append(move_id)

    result["changed"] = (
        not result["added"].is_empty()
        or not result["removed"].is_empty()
    )
    return result
