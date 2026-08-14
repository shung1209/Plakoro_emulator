extends RefCounted


const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)
const KYOKORO_AUTHORING: Script = preload(
    "res://scripts/content/KyokoroProfileAuthoringService.gd"
)
const MOVE_AUTHORING: Script = preload(
    "res://scripts/content/MoveCardAuthoringService.gd"
)
const DEFAULT_DICE_GENERATOR: Script = preload(
    "res://scripts/dice/setup/PokemonDefaultDiceGenerator.gd"
)


static func _append_unique_warning(
    warnings: Array[String],
    message: String
) -> void:
    if not warnings.has(
        message
    ):
        warnings.append(
            message
        )


static func _find_duplicate_strings(
    values: Array
) -> Array[String]:
    var seen: Dictionary = {}
    var duplicates: Array[String] = []

    for raw_value: Variant in values:
        var value: String = String(
            raw_value
        ).strip_edges()

        if value.is_empty():
            continue

        if seen.has(
            value
        ):
            if not duplicates.has(
                value
            ):
                duplicates.append(
                    value
                )
        else:
            seen[value] = true

    return duplicates


static func validate_all() -> Dictionary:
    var errors: Array[String] = []
    var warnings: Array[String] = []

    var move_reference_counts: Dictionary = {}
    var profile_reference_counts: Dictionary = {}

    var pokemon_ids: Array[String] = (
        POKEMON_AUTHORING.list_saved()
    )
    var move_ids: Array[String] = (
        MOVE_AUTHORING.list_saved()
    )
    var profile_ids: Array[String] = (
        KYOKORO_AUTHORING.list_saved()
    )

    var pokemon_by_species: Dictionary = {}

    for pokemon_id: String in pokemon_ids:
        var pokemon: Dictionary = (
            POKEMON_AUTHORING.load_by_id(
                pokemon_id
            )
        )

        if pokemon.is_empty():
            errors.append(
                "Pokémon could not be loaded: "
                + pokemon_id
            )
            continue

        var validation: Dictionary = (
            POKEMON_AUTHORING.validate(
                pokemon
            )
        )

        if not bool(
            validation.get(
                "success",
                false
            )
        ):
            for message: String in (
                validation.get(
                    "errors",
                    []
                )
            ):
                errors.append(
                    "Pokémon "
                    + pokemon_id
                    + ": "
                    + message
                )

        var species_id: String = String(
            pokemon.get(
                "species_id",
                ""
            )
        ).strip_edges().to_lower()

        if not species_id.is_empty():
            if not pokemon_by_species.has(
                species_id
            ):
                pokemon_by_species[
                    species_id
                ] = []

            (
                pokemon_by_species[
                    species_id
                ] as Array
            ).append(
                pokemon_id
            )

            var default_dice_path: String = (
                DEFAULT_DICE_GENERATOR
                .default_path_for_species(
                    species_id
                )
            )

            if not FileAccess.file_exists(
                default_dice_path
            ):
                errors.append(
                    "Pokémon "
                    + pokemon_id
                    + " is missing species Default Dice: "
                    + default_dice_path
                )

        var profile_id: String = String(
            pokemon.get(
                "kyokoro_profile_id",
                ""
            )
        ).strip_edges()

        if not profile_id.is_empty():
            profile_reference_counts[profile_id] = (
                int(
                    profile_reference_counts.get(
                        profile_id,
                        0
                    )
                )
                + 1
            )

            if not profile_ids.has(
                profile_id
            ):
                errors.append(
                    "Pokémon "
                    + pokemon_id
                    + " references missing Charakoro profile: "
                    + profile_id
                )

        var raw_move_ids: Variant = pokemon.get(
            "available_move_card_ids",
            []
        )

        if raw_move_ids is Array:
            var duplicate_move_ids: Array[String] = (
                _find_duplicate_strings(
                    raw_move_ids as Array
                )
            )

            for duplicate_id: String in duplicate_move_ids:
                _append_unique_warning(
                    warnings,
                    "Pokémon "
                    + pokemon_id
                    + " contains duplicate Move reference: "
                    + duplicate_id
                )

            for raw_move_id: Variant in (
                raw_move_ids as Array
            ):
                var move_id: String = String(
                    raw_move_id
                ).strip_edges()

                move_reference_counts[move_id] = (
                    int(
                        move_reference_counts.get(
                            move_id,
                            0
                        )
                    )
                    + 1
                )

                if not move_ids.has(
                    move_id
                ):
                    errors.append(
                        "Pokémon "
                        + pokemon_id
                        + " references missing Move: "
                        + move_id
                    )

    for profile_id: String in profile_ids:
        var profile: Dictionary = (
            KYOKORO_AUTHORING.load_by_id(
                profile_id
            )
        )

        if profile.is_empty():
            errors.append(
                "Charakoro profile could not be loaded: "
                + profile_id
            )
            continue

        var validation: Dictionary = (
            KYOKORO_AUTHORING.validate(
                profile
            )
        )

        if not bool(
            validation.get(
                "success",
                false
            )
        ):
            for message: String in (
                validation.get(
                    "errors",
                    []
                )
            ):
                errors.append(
                    "Charakoro profile "
                    + profile_id
                    + ": "
                    + message
                )

        var scene_path: String = String(
            profile.get(
                "scene_path",
                ""
            )
        ).strip_edges()

        if (
            not scene_path.is_empty()
            and not ResourceLoader.exists(
                scene_path
            )
        ):
            _append_unique_warning(
                warnings,
                "Charakoro profile "
                + profile_id
                + " scene_path does not exist: "
                + scene_path
            )

    for move_id: String in move_ids:
        var move: Dictionary = (
            MOVE_AUTHORING.load_by_id(
                move_id
            )
        )

        if move.is_empty():
            errors.append(
                "Move could not be loaded: "
                + move_id
            )
            continue

        var validation: Dictionary = (
            MOVE_AUTHORING.validate_basic(
                move
            )
        )

        if not bool(
            validation.get(
                "success",
                false
            )
        ):
            for message: String in (
                validation.get(
                    "errors",
                    []
                )
            ):
                errors.append(
                    "Move "
                    + move_id
                    + ": "
                    + message
                )

        var owner_id: String = String(
            move.get(
                "owner_id",
                ""
            )
        ).strip_edges().to_lower()

        if (
            not owner_id.is_empty()
            and not pokemon_by_species.has(
                owner_id
            )
        ):
            warnings.append(
                "Move "
                + move_id
                + " owner_id '"
                + owner_id
                + "' has no Pokémon species in the database."
            )

        # The Move can only be referenced by Pokémon of the same species
        # under the current 10.1f1 rule. Existing cross-species references
        # are warnings, not automatic destructive fixes.
        for pokemon_id: String in pokemon_ids:
            var pokemon: Dictionary = (
                POKEMON_AUTHORING.load_by_id(
                    pokemon_id
                )
            )

            if pokemon.is_empty():
                continue

            var raw_move_ids: Variant = pokemon.get(
                "available_move_card_ids",
                []
            )

            if (
                raw_move_ids is Array
                and (
                    raw_move_ids as Array
                ).has(
                    move_id
                )
            ):
                var species_id: String = String(
                    pokemon.get(
                        "species_id",
                        ""
                    )
                ).strip_edges().to_lower()

                if species_id != owner_id:
                    _append_unique_warning(
                        warnings,
                        "Cross-species Move reference: "
                        + pokemon_id
                        + " ("
                        + species_id
                        + ") → "
                        + move_id
                        + " (owner "
                        + owner_id
                        + ")."
                    )

        if int(
            move_reference_counts.get(
                move_id,
                0
            )
        ) == 0:
            _append_unique_warning(
                warnings,
                "Move "
                + move_id
                + " is not assigned to any Pokémon."
            )

    for profile_id: String in profile_ids:
        if int(
            profile_reference_counts.get(
                profile_id,
                0
            )
        ) == 0:
            _append_unique_warning(
                warnings,
                "Charakoro profile "
                + profile_id
                + " is not assigned to any Pokémon."
            )

    return {
        "success": errors.is_empty(),
        "errors": errors,
        "warnings": warnings,
        "counts": {
            "pokemon": pokemon_ids.size(),
            "moves": move_ids.size(),
            "kyokoro_profiles": profile_ids.size()
        }
    }


static func format_report(
    report: Dictionary
) -> String:
    var counts: Dictionary = report.get(
        "counts",
        {}
    )
    var errors: Array = report.get(
        "errors",
        []
    )
    var warnings: Array = report.get(
        "warnings",
        []
    )

    var lines: Array[String] = []

    lines.append(
        (
            "PASS"
            if bool(
                report.get(
                    "success",
                    false
                )
            )
            else "FAIL"
        )
        + " — Database Integrity"
    )

    lines.append(
        "Pokémon: "
        + str(
            int(
                counts.get(
                    "pokemon",
                    0
                )
            )
        )
        + " | Moves: "
        + str(
            int(
                counts.get(
                    "moves",
                    0
                )
            )
        )
        + " | Charakoro Profiles: "
        + str(
            int(
                counts.get(
                    "kyokoro_profiles",
                    0
                )
            )
        )
    )

    lines.append(
        "Errors: "
        + str(
            errors.size()
        )
        + " | Warnings: "
        + str(
            warnings.size()
        )
    )

    if not errors.is_empty():
        lines.append("")
        lines.append("Errors")

        for message: Variant in errors:
            lines.append(
                "• "
                + String(
                    message
                )
            )

    if not warnings.is_empty():
        lines.append("")
        lines.append("Warnings")

        for message: Variant in warnings:
            lines.append(
                "• "
                + String(
                    message
                )
            )

    if errors.is_empty() and warnings.is_empty():
        lines.append("")
        lines.append(
            "No integrity issues found."
        )

    return "\n".join(
        lines
    )
