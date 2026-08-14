extends RefCounted


var turn_number: int = 0
var actor_id: StringName = &""
var move_card_id: StringName = &""
var move_name: String = ""

var entries: Array = []


func add_entry(entry: Variant) -> void:
    if entry == null:
        return

    entries.append(entry)


func is_empty() -> bool:
    return entries.is_empty()
