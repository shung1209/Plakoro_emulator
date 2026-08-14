extends Control


const SETUP_LOADER: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
)
const VALIDATOR: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupValidator.gd"
)
const PROBABILITY: Script = preload(
    "res://scripts/dice/setup/EnergyDiceProbabilityCalculator.gd"
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


@onready var database: Node = $Database
@onready var setup_path_edit: LineEdit = %SetupPathEdit
@onready var dice_container: VBoxContainer = %DiceContainer
@onready var validation_label: Label = %ValidationLabel
@onready var probability_label: Label = %ProbabilityLabel


var setup: Variant = null


func _ready() -> void:
	%LoadButton.pressed.connect(
		_on_load_pressed
	)
	setup_path_edit.text = (
        "res://database/dice_setups/pikachu_default.json"
	)

	if not database.load_all():
		validation_label.text = "Database load failed."
		return

	_load_current_path()


func _on_load_pressed() -> void:
	_load_current_path()


func _load_current_path() -> void:
	setup = SETUP_LOADER.load_setup(
		setup_path_edit.text
	)

	if setup == null:
		validation_label.text = "Setup load failed."
		return

	_render_setup()
	_render_validation()
	_render_probabilities()


func _render_setup() -> void:
	for child: Node in dice_container.get_children():
		child.queue_free()

	for index: int in range(setup.dice.size()):
		var die_data: Variant = setup.dice[index]

		var panel: PanelContainer = PanelContainer.new()
		panel.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

		var box: VBoxContainer = VBoxContainer.new()
		panel.add_child(box)

		var title: Label = Label.new()
		title.text = (
            "Dice "
			+ str(index + 1)
			+ " — "
			+ String(die_data.die_id)
		)
		title.add_theme_font_size_override(
			"font_size",
			18
		)
		box.add_child(title)

		_add_line(
			box,
			"FACE_UP ↔ FACE_DOWN",
			String(die_data.fixed_a)
			+ " ↔ "
			+ String(die_data.fixed_b)
			+ "  [fixed]"
		)

		_add_line(
			box,
			"HEAD_UP",
			String(die_data.double_a_first)
			+ " + "
			+ String(die_data.double_a_second)
			+ "  [double]"
		)

		_add_line(
			box,
			"HEAD_DOWN",
			String(die_data.double_b_first)
			+ " + "
			+ String(die_data.double_b_second)
			+ "  [double]"
		)

		_add_line(
			box,
			"HEAD_LEFT ↔ HEAD_RIGHT",
			String(die_data.single_a)
			+ " ↔ "
			+ String(die_data.single_b)
			+ "  [single]"
		)

		dice_container.add_child(panel)


func _render_validation() -> void:
	var valid_energy_types: Array = []

	for energy_type: StringName in VALID_ENERGY_TYPES:
		valid_energy_types.append(energy_type)

	var result: Dictionary = VALIDATOR.validate(
		setup,
		valid_energy_types
	)

	if bool(result["success"]):
		validation_label.text = (
            "VALID — 3 dice, 6 unique fixed energies."
		)
		return

	validation_label.text = (
        "INVALID
"
		+ "
".join(result["errors"])
	)


func _render_probabilities() -> void:
	var expected: Dictionary = (
		PROBABILITY.get_expected_energy_per_roll(
			setup
		)
	)

	var lines: Array[String] = [
        "Expected energy per three-dice roll:"
	]

	var keys: Array = expected.keys()
	keys.sort()

	for raw_energy: Variant in keys:
		var energy_type: StringName = StringName(
			raw_energy
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
			+ ": expected "
			+ "%.3f" % float(expected[raw_energy])
			+ ", at least one "
			+ "%.1f%%" % (at_least_one * 100.0)
		)

	probability_label.text = "
".join(lines)


func _add_line(
	parent: VBoxContainer,
	orientation_text: String,
	result_text: String
) -> void:
	var label: Label = Label.new()
	label.text = (
		orientation_text
		+ ": "
		+ result_text
	)
	parent.add_child(label)
