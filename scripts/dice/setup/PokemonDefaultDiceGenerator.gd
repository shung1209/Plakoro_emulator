extends RefCounted


const SETUP_DATA: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupData.gd"
)
const DIE_DATA: Script = preload(
    "res://scripts/dice/setup/EnergyDieSetupData.gd"
)
const VALIDATOR: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupValidator.gd"
)
const SAVE_SERVICE: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupSaveService.gd"
)


const DATABASE_DICE_DIRECTORY: String = (
    "res://database/dice_setups"
)

const VALID_ENERGY_TYPES: Array[StringName] = [
    &"grass",
    &"fire",
    &"water",
    &"electric",
    &"psychic",
    &"fighting",
    &"dark",
    &"steel",
    &"flying"
]


static func default_path_for_species(
    species_id: String,
    directory: String = DATABASE_DICE_DIRECTORY
) -> String:
    var normalized: String = (
        species_id.strip_edges().to_lower()
    )

    if normalized.is_empty():
        return ""

    return (
        directory
        + "/"
        + normalized
        + "_default.json"
    )


static func generate_for_pokemon(
    pokemon: Dictionary
) -> Variant:
    var species_id: String = String(
        pokemon.get(
            "species_id",
            ""
        )
    ).strip_edges().to_lower()

    if species_id.is_empty():
        return null

    var pokemon_type: StringName = StringName(
        String(
            pokemon.get(
                "pokemon_type",
                "normal"
            )
        ).strip_edges().to_lower()
    )

    var rng: RandomNumberGenerator = (
        RandomNumberGenerator.new()
    )
    rng.seed = _stable_seed(
        species_id
    )

    var primary_supported: bool = (
        VALID_ENERGY_TYPES.has(
            pokemon_type
        )
    )

    var fixed_pool: Array[StringName] = (
        VALID_ENERGY_TYPES.duplicate()
    )
    _shuffle_energy_pool(
        fixed_pool,
        rng
    )

    var fixed_energies: Array[StringName] = []

    if primary_supported:
        fixed_energies.append(
            pokemon_type
        )
        fixed_pool.erase(
            pokemon_type
        )

    while fixed_energies.size() < 6:
        fixed_energies.append(
            fixed_pool.pop_front()
        )

    var setup: Variant = SETUP_DATA.new()

    if primary_supported:
        _build_primary_weighted_setup(
            setup,
            species_id,
            pokemon_type,
            fixed_energies,
            rng
        )
    else:
        _build_balanced_setup(
            setup,
            species_id,
            fixed_energies,
            rng
        )

    return setup


static func ensure_default_for_pokemon(
    pokemon: Dictionary,
    directory: String = DATABASE_DICE_DIRECTORY
) -> Dictionary:
    var species_id: String = String(
        pokemon.get(
            "species_id",
            ""
        )
    ).strip_edges().to_lower()

    var path: String = (
        default_path_for_species(
            species_id,
            directory
        )
    )

    if path.is_empty():
        return {
            "success": false,
            "created": false,
            "errors": [
                "species_id is required to generate Default Dice."
            ]
        }

    if FileAccess.file_exists(
        path
    ):
        return {
            "success": true,
            "created": false,
            "path": path,
            "errors": []
        }

    var setup: Variant = (
        generate_for_pokemon(
            pokemon
        )
    )

    if setup == null:
        return {
            "success": false,
            "created": false,
            "errors": [
                "Could not generate Default Dice."
            ]
        }

    var valid_energy_types: Array = []

    for energy_type: StringName in (
        VALID_ENERGY_TYPES
    ):
        valid_energy_types.append(
            energy_type
        )

    var validation: Dictionary = (
        VALIDATOR.validate(
            setup,
            valid_energy_types
        )
    )

    if not bool(
        validation.get(
            "success",
            false
        )
    ):
        return {
            "success": false,
            "created": false,
            "errors": validation.get(
                "errors",
                []
            )
        }

    var absolute_directory: String = (
        ProjectSettings.globalize_path(
            directory
        )
    )

    var directory_error: Error = (
        DirAccess.make_dir_recursive_absolute(
            absolute_directory
        )
    )

    if (
        directory_error != OK
        and directory_error != ERR_ALREADY_EXISTS
    ):
        return {
            "success": false,
            "created": false,
            "errors": [
                "Could not create dice_sets database directory."
            ]
        }

    if not SAVE_SERVICE.save_setup(
        setup,
        path
    ):
        return {
            "success": false,
            "created": false,
            "errors": [
                "Could not save generated Default Dice: "
                + path
            ]
        }

    return {
        "success": true,
        "created": true,
        "path": path,
        "errors": []
    }


static func regenerate_default_for_pokemon(
    pokemon: Dictionary,
    directory: String = DATABASE_DICE_DIRECTORY
) -> Dictionary:
    var species_id: String = String(
        pokemon.get(
            "species_id",
            ""
        )
    ).strip_edges().to_lower()

    var path: String = (
        default_path_for_species(
            species_id,
            directory
        )
    )

    if path.is_empty():
        return {
            "success": false,
            "created": false,
            "overwritten": false,
            "errors": [
                "species_id is required to regenerate Default Dice."
            ]
        }

    var setup: Variant = (
        generate_for_pokemon(
            pokemon
        )
    )

    if setup == null:
        return {
            "success": false,
            "created": false,
            "overwritten": false,
            "errors": [
                "Could not generate Default Dice."
            ]
        }

    var valid_energy_types: Array = []

    for energy_type: StringName in VALID_ENERGY_TYPES:
        valid_energy_types.append(
            energy_type
        )

    var validation: Dictionary = (
        VALIDATOR.validate(
            setup,
            valid_energy_types
        )
    )

    if not bool(
        validation.get(
            "success",
            false
        )
    ):
        return {
            "success": false,
            "created": false,
            "overwritten": false,
            "errors": validation.get(
                "errors",
                []
            )
        }

    var absolute_directory: String = (
        ProjectSettings.globalize_path(
            directory
        )
    )
    var directory_error: Error = (
        DirAccess.make_dir_recursive_absolute(
            absolute_directory
        )
    )

    if (
        directory_error != OK
        and directory_error != ERR_ALREADY_EXISTS
    ):
        return {
            "success": false,
            "created": false,
            "overwritten": false,
            "errors": [
                "Could not create dice_sets database directory."
            ]
        }

    var existed: bool = FileAccess.file_exists(
        path
    )

    if not SAVE_SERVICE.save_setup(
        setup,
        path
    ):
        return {
            "success": false,
            "created": false,
            "overwritten": false,
            "errors": [
                "Could not save regenerated Default Dice: "
                + path
            ]
        }

    return {
        "success": true,
        "created": not existed,
        "overwritten": existed,
        "path": path,
        "errors": []
    }


static func _build_primary_weighted_setup(
    setup: Variant,
    species_id: String,
    primary: StringName,
    fixed_energies: Array[StringName],
    rng: RandomNumberGenerator
) -> void:
    var support_pool: Array[StringName] = (
        VALID_ENERGY_TYPES.duplicate()
    )
    support_pool.erase(
        primary
    )
    _shuffle_energy_pool(
        support_pool,
        rng
    )

    for index: int in range(3):
        var die: Variant = DIE_DATA.new()
        die.die_id = StringName(
            species_id
            + "_die_"
            + str(index + 1)
        )

        die.fixed_a = fixed_energies[
            index * 2
        ]
        die.fixed_b = fixed_energies[
            index * 2 + 1
        ]

        var support_a: StringName = (
            support_pool[
                (index * 2)
                % support_pool.size()
            ]
        )
        var support_b: StringName = (
            support_pool[
                (index * 2 + 1)
                % support_pool.size()
            ]
        )

        die.double_a_first = primary
        die.double_a_second = support_a
        die.double_b_first = primary
        die.double_b_second = support_b
        die.single_a = primary
        die.single_b = (
            primary
            if index == 0
            else support_a
        )

        setup.add_die(
            die
        )


static func _build_balanced_setup(
    setup: Variant,
    species_id: String,
    fixed_energies: Array[StringName],
    rng: RandomNumberGenerator
) -> void:
    var dynamic_pool: Array[StringName] = []

    for cycle: int in range(2):
        var shuffled: Array[StringName] = (
            VALID_ENERGY_TYPES.duplicate()
        )
        _shuffle_energy_pool(
            shuffled,
            rng
        )

        for energy: StringName in shuffled:
            dynamic_pool.append(
                energy
            )

    var cursor: int = 0

    for index: int in range(3):
        var die: Variant = DIE_DATA.new()
        die.die_id = StringName(
            species_id
            + "_die_"
            + str(index + 1)
        )

        die.fixed_a = fixed_energies[
            index * 2
        ]
        die.fixed_b = fixed_energies[
            index * 2 + 1
        ]

        die.double_a_first = dynamic_pool[cursor]
        cursor += 1
        die.double_a_second = dynamic_pool[cursor]
        cursor += 1
        die.double_b_first = dynamic_pool[cursor]
        cursor += 1
        die.double_b_second = dynamic_pool[cursor]
        cursor += 1
        die.single_a = dynamic_pool[cursor]
        cursor += 1
        die.single_b = dynamic_pool[cursor]
        cursor += 1

        setup.add_die(
            die
        )


static func _shuffle_energy_pool(
    values: Array[StringName],
    rng: RandomNumberGenerator
) -> void:
    for index: int in range(
        values.size() - 1,
        0,
        -1
    ):
        var other_index: int = rng.randi_range(
            0,
            index
        )

        var temp: StringName = values[index]
        values[index] = values[other_index]
        values[other_index] = temp


static func _stable_seed(
    text: String
) -> int:
    var result: int = 17

    for character: String in text:
        result = (
            (
                result * 131
                + character.unicode_at(0)
            )
            % 2147483647
        )

    return max(
        result,
        1
    )
