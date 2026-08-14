extends RefCounted


const EVENT_DATA: Script = preload(
    "res://scripts/battle/events/BattleEventData.gd"
)


var events: Array = []


func emit_event(
    event_type: StringName,
    turn_number: int,
    source_participant_id: StringName,
    target_participant_id: StringName,
    payload: Dictionary = {}
) -> Variant:
    var event: Variant = EVENT_DATA.new(
        event_type,
        turn_number,
        source_participant_id,
        target_participant_id,
        payload
    )

    events.append(event)
    return event


func clear() -> void:
    events.clear()


func get_events_by_type(
    event_type: StringName
) -> Array:
    var result: Array = []

    for event: Variant in events:
        if StringName(event.event_type) == event_type:
            result.append(event)

    return result
