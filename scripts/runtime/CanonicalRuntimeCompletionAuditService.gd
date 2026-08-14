extends RefCounted


const MOVE_AUTHORING: Script = preload(
    "res://scripts/content/MoveCardAuthoringService.gd"
)


const NON_FINAL_MARKERS: Array[String] = [
    "pending",
    "manual",
    "partially",
    "trigger_mapping"
]


static func audit() -> Dictionary:
    var non_final_effects: Array[Dictionary] = []
    var manual_review_moves: Array[Dictionary] = []
    var canonical_move_count: int = 0
    var special_effect_entry_count: int = 0

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
        var document: String = String(
            source.get(
                "document",
                ""
            )
        )

        if not [
            "ST.pdf",
            "EB01.pdf"
        ].has(
            document
        ):
            continue

        canonical_move_count += 1

        var review: Dictionary = data.get(
            "review",
            {}
        )

        if bool(
            review.get(
                "needs_manual_review",
                false
            )
        ):
            manual_review_moves.append(
                {
                    "move_id": move_id,
                    "status": review.get(
                        "status",
                        ""
                    )
                }
            )

        for raw_effect: Variant in data.get(
            "special_effects",
            []
        ):
            if not raw_effect is Dictionary:
                continue

            special_effect_entry_count += 1

            var effect: Dictionary = (
                raw_effect as Dictionary
            )
            var runtime_status: String = String(
                effect.get(
                    "runtime_status",
                    ""
                )
            )

            for marker: String in NON_FINAL_MARKERS:
                if runtime_status.contains(
                    marker
                ):
                    non_final_effects.append(
                        {
                            "move_id": move_id,
                            "effect_type": effect.get(
                                "effect_type",
                                effect.get(
                                    "trigger",
                                    ""
                                )
                            ),
                            "runtime_status": runtime_status
                        }
                    )
                    break

    return {
        "success": (
            non_final_effects.is_empty()
            and manual_review_moves.is_empty()
        ),
        "canonical_move_count": canonical_move_count,
        "special_effect_entry_count": special_effect_entry_count,
        "non_final_effects": non_final_effects,
        "manual_review_moves": manual_review_moves
    }
