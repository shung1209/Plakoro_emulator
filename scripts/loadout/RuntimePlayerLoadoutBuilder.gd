extends RefCounted


const TEAM_BUILDER_SERVICE: Script = preload(
    "res://scripts/team_builder/TeamBuilderService.gd"
)
const STRUCTURED_DICE_SERVICE: Script = preload(
    "res://scripts/team_builder/StructuredEnergyDiceService.gd"
)
const LOADOUT_VALIDATOR: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutValidator.gd"
)


static func build_runtime_loadout(
    loadout_data: Variant,
    database: Variant,
    team_rules: Dictionary,
    participant_id: StringName = &"player"
) -> Variant:
    var validation: Dictionary = (
        LOADOUT_VALIDATOR.validate(
            loadout_data,
            database
        )
    )

    if not bool(validation["success"]):
        for raw_error: Variant in validation["errors"]:
            push_error(
                "RuntimePlayerLoadoutBuilder: "
                + String(raw_error)
            )

        return null

    var service: Variant = TEAM_BUILDER_SERVICE.new(
        database,
        team_rules
    )

    var runtime_loadout: Variant = (
        service.create_empty_loadout(
            participant_id
        )
    )

    if runtime_loadout == null:
        return null

    if not service.set_pokemon(
        runtime_loadout,
        loadout_data.pokemon_id
    ):
        return null

    for move_card_id: StringName in (
        loadout_data.move_card_ids
    ):
        if not service.select_move_card(
            runtime_loadout,
            move_card_id
        ):
            return null

    if not STRUCTURED_DICE_SERVICE.apply_setup_to_loadout(
        runtime_loadout,
        loadout_data.energy_dice_setup
    ):
        return null

    if not service.validate_loadout(
        runtime_loadout
    ):
        return null

    return runtime_loadout
