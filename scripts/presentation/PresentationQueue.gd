extends RefCounted


var _commands: Array = []


func enqueue(command: Variant) -> void:
    if command == null:
        return

    _commands.append(command)


func enqueue_many(commands: Array) -> void:
    for command: Variant in commands:
        enqueue(command)


func dequeue() -> Variant:
    if _commands.is_empty():
        return null

    return _commands.pop_front()


func peek() -> Variant:
    if _commands.is_empty():
        return null

    return _commands[0]


func is_empty() -> bool:
    return _commands.is_empty()


func size() -> int:
    return _commands.size()


func clear() -> void:
    _commands.clear()


func get_all() -> Array:
    return _commands.duplicate()
