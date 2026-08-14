extends RefCounted


const PRESENTATION_QUEUE: Script = preload(
    "res://scripts/presentation/PresentationQueue.gd"
)
const EVENT_TRANSLATOR: Script = preload(
    "res://scripts/presentation/BattleEventTranslator.gd"
)


signal presentation_started
signal presentation_finished
signal command_started(command)
signal command_finished(command)


var queue: Variant = PRESENTATION_QUEUE.new()
var view: Node = null
var _last_event_index: int = 0
var _running: bool = false


func _init(
    target_view: Node
) -> void:
    view = target_view


func reset() -> void:
    queue.clear()
    _last_event_index = 0
    _running = false


func collect_new_events(
    events: Array
) -> int:
    var added_count: int = 0

    while _last_event_index < events.size():
        var event: Variant = events[
            _last_event_index
        ]

        var commands: Array = (
            EVENT_TRANSLATOR.translate_event(
                event
            )
        )

        queue.enqueue_many(commands)
        added_count += commands.size()
        _last_event_index += 1

    return added_count


func play_pending() -> void:
    if _running:
        return

    _running = true
    presentation_started.emit()

    while not queue.is_empty():
        var command: Variant = queue.dequeue()

        command_started.emit(command)

        if view != null and view.has_method(
            "present_command"
        ):
            await view.present_command(command)

        command_finished.emit(command)

    _running = false
    presentation_finished.emit()


func is_running() -> bool:
    return _running
