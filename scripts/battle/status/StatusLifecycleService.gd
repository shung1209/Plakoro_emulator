extends RefCounted


const KNOWN_TIMINGS: Array[StringName] = [
    &"next_owner_turn",
    &"next_incoming_attack",
    &"next_owner_move",
    &""
]

const KNOWN_DURATION_SCOPES: Array[StringName] = [
    &"owner_turn"
]


static func validate_payload(
    payload: Dictionary
) -> Dictionary:
    var errors: Array[String] = []

    var status_type: String = String(
        payload.get(
            "status_type",
            ""
        )
    ).strip_edges()

    if status_type.is_empty():
        errors.append(
            "status_type is required."
        )

    var timing: StringName = StringName(
        String(
            payload.get(
                "timing",
                ""
            )
        )
    )

    if not KNOWN_TIMINGS.has(
        timing
    ):
        errors.append(
            "Unsupported status timing: "
            + String(timing)
        )

    var remaining_uses: int = int(
        payload.get(
            "remaining_uses",
            1
        )
    )

    if remaining_uses == 0:
        errors.append(
            "remaining_uses cannot start at 0."
        )

    var duration_turns: int = int(
        payload.get(
            "duration_turns",
            0
        )
    )

    if duration_turns < 0:
        errors.append(
            "duration_turns cannot be negative."
        )

    var duration_scope: StringName = StringName(
        String(
            payload.get(
                "duration_scope",
                "owner_turn"
            )
        )
    )

    if (
        duration_turns > 0
        and not KNOWN_DURATION_SCOPES.has(
            duration_scope
        )
    ):
        errors.append(
            "Unsupported duration_scope: "
            + String(duration_scope)
        )

    return {
        "success": errors.is_empty(),
        "errors": errors
    }


static func timing_matches(
    status: Variant,
    expected_timing: StringName
) -> bool:
    if status == null:
        return false

    var actual: StringName = StringName(
        status.timing
    )

    return (
        actual == &""
        or actual == expected_timing
    )


static func describe(
    status: Variant
) -> String:
    if status == null:
        return "Unknown status"

    var result: String = String(
        status.status_type
    )

    if int(status.value) != 0:
        result += " (" + str(int(status.value)) + ")"

    if StringName(status.timing) != &"":
        result += " @ " + String(status.timing)

    if int(status.remaining_uses) >= 0:
        result += " | uses " + str(int(status.remaining_uses))

    if bool(status.duration_based):
        result += (
            " | turns "
            + str(
                int(
                    status.duration_turns
                )
            )
            + " "
            + String(
                status.duration_scope
            )
        )

    return result
