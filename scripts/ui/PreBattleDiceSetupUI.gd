extends Control


const SETUP_LOADER: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
)
const EDITOR_SERVICE: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupEditorService.gd"
)
const SAVE_SERVICE: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupSaveService.gd"
)
const VALIDATOR: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupValidator.gd"
)
const PROBABILITY: Script = preload(
    "res://scripts/dice/setup/EnergyDiceProbabilityCalculator.gd"
)
const DIE_EDITOR_PANEL: Script = preload(
    "res://scripts/ui/components/EnergyDieEditorPanel.gd"
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


@onready var dice_container: HBoxContainer = %DiceContainer
@onready var validation_label: Label = %ValidationLabel
@onready var probability_label: Label = %ProbabilityLabel
@onready var save_path_edit: LineEdit = %SavePathEdit
@onready var confirm_button: Button = %ConfirmButton


var setup: Variant = null
var die_editor_panels: Array = []


func _ready() -> void:
    %LoadDefaultButton.pressed.connect(
        _load_default_setup
    )
    %SaveButton.pressed.connect(
        _save_setup
    )
    confirm_button.pressed.connect(
        _confirm_setup
    )

    save_path_edit.text = (
        "user://user_database/dice_setups/player_energy_dice_setup.json"
    )

    _load_default_setup()


func _load_default_setup() -> void:
    setup = SETUP_LOADER.load_setup(
        "res://database/dice_setups/pikachu_default.json"
    )

    if setup == null:
        setup = EDITOR_SERVICE.create_empty_setup()

    _build_editors()
    _refresh_all()


func _build_editors() -> void:
    die_editor_panels.clear()

    for child: Node in dice_container.get_children():
        child.queue_free()

    for index: int in range(3):
        var panel: PanelContainer = (
            DIE_EDITOR_PANEL.new()
        )

        panel.size_flags_horizontal = (
            Control.SIZE_EXPAND_FILL
        )
        panel.setup_changed.connect(
            _on_any_setup_changed
        )
        dice_container.add_child(panel)

        panel.initialize(
            setup,
            index,
            EDITOR_SERVICE
        )

        die_editor_panels.append(panel)


func _on_any_setup_changed() -> void:
    _refresh_all()


func _refresh_all() -> void:
    _refresh_fixed_constraints()
    _refresh_summary()


func _refresh_fixed_constraints() -> void:
    for panel: Variant in die_editor_panels:
        if panel != null and panel.has_method(
            "refresh_fixed_energy_constraints"
        ):
            panel.refresh_fixed_energy_constraints()


func _refresh_summary() -> void:
    var valid_energy_types: Array = []

    for energy_type: StringName in VALID_ENERGY_TYPES:
        valid_energy_types.append(energy_type)

    var validation: Dictionary = VALIDATOR.validate(
        setup,
        valid_energy_types
    )

    if bool(validation["success"]):
        validation_label.text = (
            "VALID — Ready for battle."
        )
        confirm_button.disabled = false
    else:
        validation_label.text = (
            "INVALID
"
            + "
".join(validation["errors"])
        )
        confirm_button.disabled = true

    var expected: Dictionary = (
        PROBABILITY.get_expected_energy_per_roll(
            setup
        )
    )

    var lines: Array[String] = [
        "Expected energy per roll"
    ]

    var keys: Array = expected.keys()
    keys.sort()

    for raw_energy: Variant in keys:
        var energy_type: StringName = StringName(
            raw_energy
        )
        var expected_value: float = float(
            expected[raw_energy]
        )
        var at_least_one: float = (
            PROBABILITY
            .get_at_least_one_probability(
                setup,
                energy_type
            )
        )

        lines.append(
            String(energy_type)
            + ": "
            + "%.3f" % expected_value
            + " expected, "
            + "%.1f%%" % (at_least_one * 100.0)
            + " chance of at least one"
        )

    probability_label.text = "
".join(lines)


func _save_setup() -> void:
    if setup == null:
        return

    if SAVE_SERVICE.save_setup(
        setup,
        save_path_edit.text
    ):
        validation_label.text = (
            "Saved to " + save_path_edit.text
        )
    else:
        validation_label.text = "Save failed."


func _confirm_setup() -> void:
    if confirm_button.disabled:
        return

    if SAVE_SERVICE.save_setup(
        setup,
        save_path_edit.text
    ):
        validation_label.text = (
            "Setup confirmed and saved."
        )
    else:
        validation_label.text = (
            "Setup is valid, but save failed."
        )
