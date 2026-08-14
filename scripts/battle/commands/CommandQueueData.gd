extends RefCounted


var _commands: Array = []


func enqueue(command: Variant) -> void:
    if command == null:
        return

    _commands.append(command)


func dequeue() -> Variant:
    if _commands.is_empty():
        return null

    return _commands.pop_front()


func is_empty() -> bool:
    return _commands.is_empty()


func size() -> int:
    return _commands.size()


func clear() -> void:
    _commands.clear()


func get_all() -> Array:
    return _commands.duplicate()
