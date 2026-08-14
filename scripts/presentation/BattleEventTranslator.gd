extends RefCounted


const PRESENTATION_COMMAND: Script = preload(
    "res://scripts/presentation/PresentationCommandData.gd"
)


static func translate_event(
    event: Variant
) -> Array:
    var result: Array = []

    if event == null:
        return result

    var event_type: StringName = StringName(
        event.event_type
    )
    var payload: Dictionary = event.payload

    match event_type:
        &"battle_started":
            result.append(
                PRESENTATION_COMMAND.new(
                    &"show_message",
                    {
                        "text": "Battle Start!"
                    },
                    0.6
                )
            )

        &"move_selected":
            result.append(
                PRESENTATION_COMMAND.new(
                    &"show_move",
                    {
                        "source_participant_id": (
                            event.source_participant_id
                        ),
                        "move_card_id": payload.get(
                            "move_card_id",
                            ""
                        )
                    },
                    0.45
                )
            )

        &"energy_checked":
            var success: bool = bool(
                payload.get("success", false)
            )

            result.append(
                PRESENTATION_COMMAND.new(
                    &"show_energy_result",
                    {
                        "success": success
                    },
                    0.35
                )
            )

        &"outcome_triggered":
            result.append(
                PRESENTATION_COMMAND.new(
                    &"show_outcome",
                    {
                        "orientation": payload.get(
                            "orientation",
                            ""
                        )
                    },
                    0.4
                )
            )

        &"damage_applied":
            result.append(
                PRESENTATION_COMMAND.new(
                    &"show_damage",
                    {
                        "target_participant_id": (
                            event.target_participant_id
                        ),
                        "amount": int(
                            payload.get(
                                "applied_amount",
                                0
                            )
                        ),
                        "remaining_hp": int(
                            payload.get(
                                "remaining_hp",
                                0
                            )
                        )
                    },
                    0.55
                )
            )

        &"hp_restored":
            result.append(
                PRESENTATION_COMMAND.new(
                    &"show_heal",
                    {
                        "target_participant_id": (
                            event.target_participant_id
                        ),
                        "amount": int(
                            payload.get("amount", 0)
                        ),
                        "remaining_hp": int(
                            payload.get(
                                "remaining_hp",
                                0
                            )
                        )
                    },
                    0.45
                )
            )

        &"status_added":
            result.append(
                PRESENTATION_COMMAND.new(
                    &"show_status",
                    {
                        "target_participant_id": (
                            event.target_participant_id
                        ),
                        "status_type": payload.get(
                            "status_type",
                            ""
                        ),
                        "value": int(
                            payload.get("value", 0)
                        )
                    },
                    0.45
                )
            )

        &"turn_changed":
            result.append(
                PRESENTATION_COMMAND.new(
                    &"show_turn_change",
                    {
                        "current_participant_id": (
                            payload.get(
                                "current_participant_id",
                                event.source_participant_id
                            )
                        )
                    },
                    0.35
                )
            )

        &"battle_finished":
            result.append(
                PRESENTATION_COMMAND.new(
                    &"show_battle_result",
                    {
                        "winner_participant_id": (
                            payload.get(
                                "winner_participant_id",
                                event.source_participant_id
                            )
                        )
                    },
                    0.8
                )
            )

        _:
            pass

    return result
