extends VBoxContainer


signal changed


const CONDITION_TYPES: Array[Dictionary] = [
	{
		"id": "always",
		"label": "Always"
	},
	{
		"id": "hp",
		"label": "HP comparison"
	},
	{
		"id": "energy_count",
		"label": "Energy count",
		"label_key": "move_editor.energy_count"
	},
	{
		"id": "previous_self_energy_failed",
		"label": "Previous self energy failed"
	},
	{
		"id": "previous_opponent_energy_failed",
		"label": "Previous opponent energy failed"
	},
	{
		"id": "previous_self_move_outcome_success",
		"label": "Previous self Move outcome succeeded"
	},
	{
		"id": "all",
		"label": "All conditions"
	},
	{
		"id": "any",
		"label": "Any condition"
	},
	{
		"id": "not",
		"label": "NOT condition"
	}
]

const TARGETS: Array[String] = [
	"self",
    "opponent"
]

const OPERATORS: Array[String] = [
	"<",
	"<=",
	"==",
	"!=",
	">=",
    ">"
]

const ENERGY_TYPES: Array[String] = [
	"grass",
	"fire",
	"water",
	"electric",
	"psychic",
	"fighting",
	"dark",
	"steel",
    "flying"
]


var type_option: OptionButton
var fields_box: VBoxContainer
var child_conditions_box: VBoxContainer
var child_rows: VBoxContainer
var add_child_button: Button

var target_option: OptionButton
var operator_option: OptionButton
var value_spin: SpinBox
var energy_type_option: OptionButton
var move_name_edit: LineEdit

var _loading: bool = false


func initialize(
	condition: Dictionary = {}
) -> void:
	add_theme_constant_override(
		"separation",
		6
	)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override(
		"separation",
		8
	)
	add_child(header)

	var label: Label = Label.new()
	label.text = "Condition"
	header.add_child(label)

	type_option = OptionButton.new()
	type_option.custom_minimum_size.x = 330
	type_option.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	header.add_child(type_option)

	for entry: Dictionary in CONDITION_TYPES:
		var fallback_label: String = String(
			entry.get(
				"label",
				entry.get(
					"id",
                    ""
				)
			)
		)
		var label_key: String = String(
			entry.get(
				"label_key",
                ""
			)
		)
		type_option.add_item(
			LocalizationService.tr_key(
				label_key,
				fallback_label
			)
			if not label_key.is_empty()
			else fallback_label
		)
		type_option.set_item_metadata(
			type_option.item_count - 1,
			String(
				entry.get(
					"id",
                    ""
				)
			)
		)

	fields_box = VBoxContainer.new()
	fields_box.add_theme_constant_override(
		"separation",
		6
	)
	add_child(fields_box)

	child_conditions_box = VBoxContainer.new()
	child_conditions_box.add_theme_constant_override(
		"separation",
		6
	)
	add_child(child_conditions_box)

	var child_header: HBoxContainer = HBoxContainer.new()
	child_conditions_box.add_child(
		child_header
	)

	var child_title: Label = Label.new()
	child_title.text = "Child Conditions"
	child_title.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	child_header.add_child(child_title)

	add_child_button = Button.new()
	add_child_button.text = "+ Add Condition"
	child_header.add_child(
		add_child_button
	)

	child_rows = VBoxContainer.new()
	child_rows.add_theme_constant_override(
		"separation",
		8
	)
	child_conditions_box.add_child(
		child_rows
	)

	type_option.item_selected.connect(
		func(_index: int) -> void:
			if _loading:
				return
			_rebuild_fields({})
			_emit_changed()
	)

	add_child_button.pressed.connect(
		func() -> void:
			_create_child_condition(
				{
					"type": "always"
				}
			)
			_emit_changed()
	)

	load_condition(
		condition
	)


func load_condition(
	condition: Dictionary
) -> void:
	_loading = true

	var condition_type: String = String(
		condition.get(
			"type",
            "always"
		)
	)

	_select_metadata(
		type_option,
		condition_type,
		true
	)

	_rebuild_fields(
		condition
	)

	_loading = false


func _rebuild_fields(
	condition: Dictionary
) -> void:
	_clear_container(
		fields_box
	)
	_clear_container(
		child_rows
	)

	target_option = null
	operator_option = null
	value_spin = null
	energy_type_option = null
	move_name_edit = null

	var condition_type: String = str(
		type_option.get_item_metadata(
			type_option.selected
		)
	)

	match condition_type:
		"hp":
			target_option = _add_option_field(
				"Target",
				TARGETS,
				String(
					condition.get(
						"target",
                        "self"
					)
				)
			)
			operator_option = _add_option_field(
				"Operator",
				OPERATORS,
				String(
					condition.get(
						"operator",
                        "<="
					)
				)
			)
			value_spin = _add_int_field(
				"HP Value",
				int(
					condition.get(
						"value",
						0
					)
				),
				0
			)

		"energy_count":
			energy_type_option = _add_option_field(
				LocalizationService.tr_key("move_editor.energy_type", "Energy Type"),
				ENERGY_TYPES,
				String(
					condition.get(
						"energy_type",
                        "electric"
					)
				)
			)
			operator_option = _add_option_field(
				"Operator",
				OPERATORS,
				String(
					condition.get(
						"operator",
                        ">="
					)
				)
			)
			value_spin = _add_int_field(
				"Count",
				int(
					condition.get(
						"value",
						1
					)
				),
				0
			)

		"previous_self_move_outcome_success":
			move_name_edit = _add_string_field(
				"Move Name ID",
				String(
					condition.get(
						"move_name_id",
                        ""
					)
				)
			)

	var composite: bool = (
		condition_type == "all"
		or condition_type == "any"
		or condition_type == "not"
	)
	child_conditions_box.visible = composite

	if not composite:
		return

	if condition_type == "not":
		add_child_button.text = "Set NOT Condition"
		add_child_button.disabled = (
			child_rows.get_child_count()
			>= 1
		)

		var raw_child: Variant = condition.get(
			"condition",
			{}
		)
		if raw_child is Dictionary:
			_create_child_condition(
				raw_child as Dictionary
			)
	else:
		add_child_button.text = "+ Add Condition"
		add_child_button.disabled = false

		var raw_children: Variant = condition.get(
			"conditions",
			[]
		)
		if raw_children is Array:
			for raw_child: Variant in raw_children:
				if raw_child is Dictionary:
					_create_child_condition(
						raw_child as Dictionary
					)


func _create_child_condition(
	condition: Dictionary
) -> void:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override(
		"separation",
		4
	)
	child_rows.add_child(wrapper)

	var controls: HBoxContainer = HBoxContainer.new()
	wrapper.add_child(controls)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	controls.add_child(spacer)

	var remove_button: Button = Button.new()
	remove_button.text = "Remove Condition"
	controls.add_child(remove_button)

	var condition_script: Script = get_script()
	var editor: VBoxContainer = condition_script.new()
	wrapper.add_child(editor)
	editor.initialize(
		condition
	)
	editor.changed.connect(
		_emit_changed
	)

	remove_button.pressed.connect(
		func() -> void:
			child_rows.remove_child(
				wrapper
			)
			wrapper.queue_free()

			if (
				str(
					type_option.get_item_metadata(
						type_option.selected
					)
				)
				== "not"
			):
				add_child_button.disabled = false

			_emit_changed()
	)

	if (
		str(
			type_option.get_item_metadata(
				type_option.selected
			)
		)
		== "not"
	):
		add_child_button.disabled = true


func to_dictionary() -> Dictionary:
	var condition_type: String = str(
		type_option.get_item_metadata(
			type_option.selected
		)
	)

	var result: Dictionary = {
		"type": condition_type
	}

	match condition_type:
		"hp":
			result["target"] = str(
				target_option.get_item_metadata(
					target_option.selected
				)
			)
			result["operator"] = str(
				operator_option.get_item_metadata(
					operator_option.selected
				)
			)
			result["value"] = int(
				value_spin.value
			)

		"energy_count":
			result["energy_type"] = str(
				energy_type_option.get_item_metadata(
					energy_type_option.selected
				)
			)
			result["operator"] = str(
				operator_option.get_item_metadata(
					operator_option.selected
				)
			)
			result["value"] = int(
				value_spin.value
			)

		"previous_self_move_outcome_success":
			result["move_name_id"] = (
				move_name_edit.text.strip_edges()
			)

		"all", "any":
			var conditions: Array = []
			for wrapper: Node in child_rows.get_children():
				var editor: Node = _find_condition_editor(
					wrapper
				)
				if (
					editor != null
					and editor.has_method(
                        "to_dictionary"
					)
				):
					conditions.append(
						editor.to_dictionary()
					)
			result["conditions"] = conditions

		"not":
			if child_rows.get_child_count() > 0:
				var wrapper: Node = child_rows.get_child(
					0
				)
				var editor: Node = _find_condition_editor(
					wrapper
				)
				if (
					editor != null
					and editor.has_method(
                        "to_dictionary"
					)
				):
					result["condition"] = (
						editor.to_dictionary()
					)

	return result


func is_valid_condition() -> bool:
	var result: Dictionary = to_dictionary()
	var condition_type: String = String(
		result.get(
			"type",
            ""
		)
	)

	if condition_type.is_empty():
		return false

	if condition_type == "previous_self_move_outcome_success":
		return not String(
			result.get(
				"move_name_id",
                ""
			)
		).is_empty()

	if condition_type == "not":
		return (
			result.get(
				"condition",
				null
			)
			is Dictionary
		)

	if (
		condition_type == "all"
		or condition_type == "any"
	):
		var conditions: Variant = result.get(
			"conditions",
			[]
		)
		if (
			not conditions is Array
			or (conditions as Array).is_empty()
		):
			return false

	for wrapper: Node in child_rows.get_children():
		var editor: Node = _find_condition_editor(
			wrapper
		)
		if (
			editor != null
			and editor.has_method(
                "is_valid_condition"
			)
			and not editor.is_valid_condition()
		):
			return false

	return true


func _add_option_field(
	label_text: String,
	options: Array[String],
	selected_value: String
) -> OptionButton:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(
		"separation",
		8
	)
	fields_box.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 170
	row.add_child(label)

	var option: OptionButton = OptionButton.new()
	option.custom_minimum_size.x = 220
	row.add_child(option)

	for value: String in options:
		option.add_item(
			value.capitalize()
		)
		option.set_item_metadata(
			option.item_count - 1,
			value
		)

	_select_metadata(
		option,
		selected_value,
		true
	)

	option.item_selected.connect(
		func(_index: int) -> void:
			_emit_changed()
	)

	return option


func _add_int_field(
	label_text: String,
	value: int,
	minimum: int
) -> SpinBox:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(
		"separation",
		8
	)
	fields_box.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 170
	row.add_child(label)

	var spin: SpinBox = SpinBox.new()
	spin.custom_minimum_size.x = 180
	spin.min_value = minimum
	spin.max_value = 999999
	spin.step = 1
	spin.value = value
	row.add_child(spin)

	spin.value_changed.connect(
		func(_value: float) -> void:
			_emit_changed()
	)

	return spin


func _add_string_field(
	label_text: String,
	value: String
) -> LineEdit:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(
		"separation",
		8
	)
	fields_box.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 170
	row.add_child(label)

	var edit: LineEdit = LineEdit.new()
	edit.custom_minimum_size.x = 300
	edit.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	edit.text = value
	row.add_child(edit)

	edit.text_changed.connect(
		func(_new_text: String) -> void:
			_emit_changed()
	)

	return edit


func _find_condition_editor(
	wrapper: Node
) -> Node:
	for child: Node in wrapper.get_children():
		if child.has_method(
            "to_dictionary"
		) and child.has_method(
            "is_valid_condition"
		):
			return child

	return null


func _clear_container(
	container: Node
) -> void:
	for child: Node in container.get_children():
		container.remove_child(
			child
		)
		child.queue_free()


func _emit_changed() -> void:
	if _loading:
		return

	changed.emit()


func _select_metadata(
	option: OptionButton,
	value: String,
	add_if_missing: bool = false
) -> void:
	for index: int in range(
		option.item_count
	):
		if str(
			option.get_item_metadata(
				index
			)
		) == value:
			option.select(
				index
			)
			return

	if add_if_missing:
		option.add_item(
			value
		)
		option.set_item_metadata(
			option.item_count - 1,
			value
		)
		option.select(
			option.item_count - 1
		)
