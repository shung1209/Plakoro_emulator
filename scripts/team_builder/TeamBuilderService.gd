extends RefCounted


const LOADOUT_DATA: Script = preload(
    "res://scripts/team_builder/data/PlayerLoadoutData.gd"
)

const ENERGY_DIE_DATA: Script = preload(
    "res://scripts/team_builder/data/EnergyDieConfigData.gd"
)

const VALIDATOR: Script = preload(
    "res://scripts/team_builder/TeamBuilderValidator.gd"
)


var database: Node
var rules: Dictionary = {}


func _init(
    database_service: Node,
    team_builder_rules: Dictionary
) -> void:
    database = database_service
    rules = team_builder_rules.duplicate(true)


func create_empty_loadout(
    owner_type: StringName = &"player"
) -> Variant:
    var loadout: Variant = LOADOUT_DATA.new()
    loadout.owner_type = owner_type
    return loadout


func set_pokemon(
    loadout: Variant,
    pokemon_id: StringName
) -> bool:
    if not database.has_pokemon(pokemon_id):
        push_error(
            "Team Builder: unknown Pokémon '%s'."
            % String(pokemon_id)
        )
        return false

    loadout.pokemon_id = pokemon_id
    loadout.pokemon_data = database.get_pokemon(
        pokemon_id
    )

    loadout.selected_move_card_ids.clear()
    loadout.selected_move_cards.clear()

    return true


func select_move_card(
    loadout: Variant,
    card_id: StringName
) -> bool:
    if loadout.pokemon_data == null:
        push_error(
            "Team Builder: select a Pokémon first."
        )
        return false

    if not database.has_move_card(card_id):
        push_error(
            "Team Builder: unknown move card '%s'."
            % String(card_id)
        )
        return false

    if not loadout.pokemon_data.has_available_card(
        card_id
    ):
        push_error(
            "Team Builder: move card '%s' is not available to Pokémon '%s'."
            % [
                String(card_id),
                String(loadout.pokemon_id)
            ]
        )
        return false

    if loadout.has_move_card(card_id):
        return false

    var card: Variant = database.get_move_card(
        card_id
    )

    if loadout.has_move_name(
        StringName(card.move_name_id)
    ):
        return false

    var maximum_count: int = int(
        rules.get(
            "required_selected_move_cards",
            4
        )
    )

    if (
        loadout.selected_move_card_ids.size()
        >= maximum_count
    ):
        return false

    loadout.selected_move_card_ids.append(
        card_id
    )
    loadout.selected_move_cards.append(card)

    return true


func remove_move_card(
    loadout: Variant,
    card_id: StringName
) -> bool:
    var index: int = (
        loadout.selected_move_card_ids.find(
            card_id
        )
    )

    if index < 0:
        return false

    loadout.selected_move_card_ids.remove_at(
        index
    )
    loadout.selected_move_cards.remove_at(index)

    return true


func set_energy_die(
    loadout: Variant,
    die_index: int,
    energy_a: StringName,
    energy_b: StringName
) -> bool:
    return configure_energy_die(
        loadout,
        die_index,
        energy_a,
        energy_b,
        energy_a,
        energy_b,
        energy_a,
        energy_b
    )


func configure_energy_die(
    loadout: Variant,
    die_index: int,
    fixed_energy_a: StringName,
    fixed_energy_b: StringName,
    single_energy_a: StringName,
    single_energy_b: StringName,
    double_energy_a: StringName,
    double_energy_b: StringName
) -> bool:
    if die_index < 0:
        push_error(
            "Team Builder: die_index cannot be negative."
        )
        return false

    var all_energies: Array = [
        fixed_energy_a,
        fixed_energy_b,
        single_energy_a,
        single_energy_b,
        double_energy_a,
        double_energy_b
    ]

    for raw_energy: Variant in all_energies:
        var energy_type: StringName = StringName(
            raw_energy
        )

        if not database.reference_data.has_energy_type(
            energy_type
        ):
            push_error(
                "Team Builder: unknown energy '%s'."
                % String(energy_type)
            )
            return false

    if fixed_energy_a == fixed_energy_b:
        push_error(
            "Team Builder: fixed energies must differ."
        )
        return false

    while loadout.energy_dice.size() <= die_index:
        var next_index: int = (
            loadout.energy_dice.size()
        )

        loadout.energy_dice.append(
            ENERGY_DIE_DATA.new(
                StringName(
                    "energy_die_%d"
                    % (next_index + 1)
                )
            )
        )

    var die: Variant = loadout.energy_dice[
        die_index
    ]

    die.configure_all_faces(
        fixed_energy_a,
        fixed_energy_b,
        single_energy_a,
        single_energy_b,
        double_energy_a,
        double_energy_b
    )

    return true


func get_energy_die_profiles(
    loadout: Variant
) -> Array:
    var result: Array = []

    for die: Variant in loadout.energy_dice:
        result.append(die.create_profile())

    return result


func validate_loadout(
    loadout: Variant
) -> bool:
    return VALIDATOR.validate_loadout(
        loadout,
        database,
        rules
    )
