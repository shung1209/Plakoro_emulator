extends RefCounted


const MOVE_AUTHORING: Script = preload(
    "res://scripts/content/MoveCardAuthoringService.gd"
)


static func audit_all() -> Dictionary:
    var missing_display_sources: Array[Dictionary] = []
    var kyokoro_move_count: int = 0

    for move_id: String in MOVE_AUTHORING.list_saved():
        var data: Dictionary = (
            MOVE_AUTHORING.load_by_id(
                move_id
            )
        )

        if data.is_empty():
            continue

        var source: Dictionary = data.get(
            "source",
            {}
        )

        if not [
            "ST.pdf",
            "EB01.pdf"
        ].has(
            String(
                source.get(
                    "document",
                    ""
                )
            )
        ):
            continue

        var kyokoro_text: Variant = source.get(
            "kyokoro_effect_text",
            []
        )

        if kyokoro_text is String:
            kyokoro_text = [
                kyokoro_text
            ]

        if (
            not kyokoro_text is Array
            or (kyokoro_text as Array).is_empty()
        ):
            continue

        kyokoro_move_count += 1

        var has_outcome: bool = not (
            data.get(
                "outcome_rules",
                []
            )
            as Array
        ).is_empty()

        var has_special: bool = false

        for raw_special: Variant in data.get(
            "special_effects",
            []
        ):
            if (
                raw_special is Dictionary
                and String(
                    (raw_special as Dictionary).get(
                        "trigger",
                        ""
                    )
                ) == "kyokoro_outcome"
            ):
                has_special = true
                break

        if not (
            has_outcome
            or has_special
        ):
            missing_display_sources.append(
                {
                    "move_id": move_id,
                    "display_name": data.get(
                        "display_name",
                        move_id
                    )
                }
            )

    return {
        "success": missing_display_sources.is_empty(),
        "kyokoro_move_count": kyokoro_move_count,
        "missing_display_sources": missing_display_sources
    }
