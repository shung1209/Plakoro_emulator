extends RefCounted


const KNOWN_CONSUME_TIMINGS: Array[StringName] = [
    &"",
    &"next_owner_turn",
    &"next_owner_move",
    &"next_owner_roll",
    &"next_incoming_attack",
    &"when_triggered"
]

const KNOWN_DURATION_SCOPES: Array[StringName] = [
    &"",
    &"owner_turn"
]


static func validate_payload(
    payload: Dictionary
) -> Dictionary:
    var errors: Array[String] = []

    if String(
        payload.get(
            "effect_type",
            ""
        )
    ).strip_edges().is_empty():
        errors.append(
            "effect_type is required."
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

    var consume_timing: StringName = StringName(
        payload.get(
            "consume_timing",
            ""
        )
    )

    if not KNOWN_CONSUME_TIMINGS.has(
        consume_timing
    ):
        errors.append(
            "Unsupported consume_timing: "
            + String(
                consume_timing
            )
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
        payload.get(
            "duration_scope",
            ""
        )
    )

    if not KNOWN_DURATION_SCOPES.has(
        duration_scope
    ):
        errors.append(
            "Unsupported duration_scope: "
            + String(
                duration_scope
            )
        )

    if (
        duration_scope != &""
        and duration_turns <= 0
    ):
        errors.append(
            "duration_turns must be positive when duration_scope is set."
        )

    return {
        "success": errors.is_empty(),
        "errors": errors
    }


static func timing_matches(
    effect: Variant,
    expected_timing: StringName
) -> bool:
    if effect == null:
        return false

    var actual: StringName = StringName(
        effect.consume_timing
    )

    return (
        actual == &""
        or actual == expected_timing
    )


static func describe(
    effect: Variant
) -> String:
    if effect == null:
        return "Unknown battle effect"

    var text: String = String(
        effect.effect_type
    )

    if not String(
        effect.display_text
    ).is_empty():
        text += ": " + String(
            effect.display_text
        )

    if StringName(
        effect.consume_timing
    ) != &"":
        text += (
            " @ "
            + String(
                effect.consume_timing
            )
        )

    if int(
        effect.remaining_uses
    ) >= 0:
        text += (
            " | uses "
            + str(
                int(
                    effect.remaining_uses
                )
            )
        )

    if StringName(
        effect.duration_scope
    ) != &"":
        text += (
            " | turns "
            + str(
                int(
                    effect.duration_turns
                )
            )
            + " "
            + String(
                effect.duration_scope
            )
        )

    return text
