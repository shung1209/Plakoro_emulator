extends VBoxContainer


signal changed
signal remove_requested(row)


const REGISTRY_FACTORY: Script = preload(
    "res://scripts/battle/opcode/DefaultOpcodeRegistryFactory.gd"
)
const CONDITION_EDITOR: Script = preload(
    "res://scripts/ui/components/MoveConditionEditor.gd"
)
const LIFECYCLE_EDITOR: Script = preload(
    "res://scripts/ui/components/MoveLifecycleEffectEditor.gd"
)


var type_option: OptionButton
var fields_box: VBoxContainer
var field_controls: Dictionary = {}
var field_metadata: Dictionary = {}

var extra_args_box: VBoxContainer
var extra_args_json: TextEdit
var nested_actions_box: VBoxContainer
var then_actions_rows: VBoxContainer
var else_actions_rows: VBoxContainer
var custom_json: TextEdit
var remove_button: Button
var help_label: Label

var _registry: Variant = null
var _loading: bool = false
var _current_opcode: StringName = &""
var _custom_source_action: Dictionary = {}
var _custom_source_text: String = ""
var _preserved_hidden_args: Dictionary = {}


func initialize(
	action: Dictionary = {}
) -> void:
	add_theme_constant_override(
		"separation",
		7
	)

	_registry = REGISTRY_FACTORY.create()

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override(
		"separation",
		10
	)
	add_child(header)

	var label: Label = Label.new()
	label.text = "Action"
	header.add_child(label)

	type_option = OptionButton.new()
	type_option.custom_minimum_size.x = 360
	type_option.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	header.add_child(type_option)

	_populate_opcode_options()

	remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.custom_minimum_size.x = 110
	header.add_child(remove_button)

	help_label = Label.new()
	help_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	help_label.modulate.a = 0.78
	add_child(help_label)

	fields_box = VBoxContainer.new()
	fields_box.add_theme_constant_override(
		"separation",
		6
	)
	add_child(fields_box)

	nested_actions_box = VBoxContainer.new()
	nested_actions_box.add_theme_constant_override(
		"separation",
		8
	)
	add_child(nested_actions_box)

	var then_header: HBoxContainer = HBoxContainer.new()
	nested_actions_box.add_child(then_header)

	var then_title: Label = Label.new()
	then_title.text = "Then Actions"
	then_title.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	then_header.add_child(then_title)

	var add_then_button: Button = Button.new()
	add_then_button.text = "+ Add Then Action"
	then_header.add_child(add_then_button)

	then_actions_rows = VBoxContainer.new()
	then_actions_rows.add_theme_constant_override(
		"separation",
		8
	)
	nested_actions_box.add_child(
		then_actions_rows
	)

	var else_header: HBoxContainer = HBoxContainer.new()
	nested_actions_box.add_child(else_header)

	var else_title: Label = Label.new()
	else_title.text = "Else Actions"
	else_title.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	else_header.add_child(else_title)

	var add_else_button: Button = Button.new()
	add_else_button.text = "+ Add Else Action"
	else_header.add_child(add_else_button)

	else_actions_rows = VBoxContainer.new()
	else_actions_rows.add_theme_constant_override(
		"separation",
		8
	)
	nested_actions_box.add_child(
		else_actions_rows
	)

	add_then_button.pressed.connect(
		func() -> void:
			_create_nested_action_row(
				then_actions_rows,
				{}
			)
			_emit_changed()
	)
	add_else_button.pressed.connect(
		func() -> void:
			_create_nested_action_row(
				else_actions_rows,
				{}
			)
			_emit_changed()
	)

	extra_args_box = VBoxContainer.new()
	extra_args_box.add_theme_constant_override(
		"separation",
		4
	)
	add_child(extra_args_box)

	var extra_label: Label = Label.new()
	extra_label.text = (
        "Additional Args JSON"
	)
	extra_args_box.add_child(
		extra_label
	)

	extra_args_json = TextEdit.new()
	extra_args_json.custom_minimum_size = Vector2(
		0,
		100
	)
	extra_args_json.wrap_mode = (
		TextEdit.LINE_WRAPPING_BOUNDARY
	)
	extra_args_box.add_child(
		extra_args_json
	)

	custom_json = TextEdit.new()
	custom_json.custom_minimum_size = Vector2(
		0,
		150
	)
	custom_json.wrap_mode = (
		TextEdit.LINE_WRAPPING_BOUNDARY
	)
	add_child(custom_json)

	type_option.item_selected.connect(
		func(_index: int) -> void:
			if _loading:
				return
			_rebuild_fields_for_selected_opcode(
				{}
			)
			_emit_changed()
	)
	extra_args_json.text_changed.connect(
		_emit_changed
	)
	custom_json.text_changed.connect(
		_emit_changed
	)
	remove_button.pressed.connect(
		func() -> void:
			remove_requested.emit(
				self
			)
	)

	load_action(
		action
	)


func _populate_opcode_options() -> void:
	type_option.clear()

	if _registry != null:
		var metadata_rows: Array[Dictionary] = (
			_registry.get_all_authoring_metadata()
		)

		for metadata: Dictionary in metadata_rows:
			var opcode: String = String(
				metadata.get(
					"opcode",
                    ""
				)
			)
			if opcode.is_empty():
				continue

			var category: String = String(
				metadata.get(
					"category",
                    "Other"
				)
			)
			var display_name: String = String(
				metadata.get(
					"display_name",
					opcode
				)
			)

			type_option.add_item(
				category
				+ " — "
				+ display_name
			)
			type_option.set_item_metadata(
				type_option.item_count - 1,
				opcode
			)

	type_option.add_separator()

	type_option.add_item(
        "Advanced — Custom JSON"
	)
	type_option.set_item_metadata(
		type_option.item_count - 1,
        "custom"
	)


func load_action(
	action: Dictionary
) -> void:
	_loading = true

	var opcode: String = String(
		action.get(
			"opcode",
            ""
		)
	)
	var recognized: bool = (
		_registry != null
		and _registry.has_handler(
			StringName(opcode)
		)
	)

	_select_metadata(
		type_option,
		(
			opcode
			if recognized
			else "custom"
		)
	)

	_custom_source_action = action.duplicate(true)
	_custom_source_text = JSON.stringify(
		action,
        "  "
	)
	custom_json.text = _custom_source_text

	if recognized:
		_rebuild_fields_for_selected_opcode(
			action
		)
	else:
		_show_custom_mode()

	_loading = false


func _rebuild_fields_for_selected_opcode(
	action: Dictionary
) -> void:
	_clear_container(
		fields_box
	)
	field_controls.clear()
	field_metadata.clear()
	_preserved_hidden_args.clear()

	var selected_opcode: String = str(
		type_option.get_item_metadata(
			type_option.selected
		)
	)

	if selected_opcode == "custom":
		_show_custom_mode()
		return

	_current_opcode = StringName(
		selected_opcode
	)

	var metadata: Dictionary = (
		_registry.get_authoring_metadata(
			_current_opcode
		)
	)

	help_label.text = String(
		metadata.get(
			"description",
            ""
		)
	)
	custom_json.visible = false
	fields_box.visible = true

	var action_args: Dictionary = {}
	var raw_args: Variant = action.get(
		"args",
		{}
	)

	if raw_args is Dictionary:
		action_args = (
			raw_args as Dictionary
		).duplicate(
			true
		)

	var known_keys: Array[String] = []
	var hidden_keys: Variant = metadata.get(
		"preserved_hidden_args",
		[]
	)
	if hidden_keys is Array:
		for raw_hidden_key: Variant in hidden_keys:
			var hidden_key: String = String(raw_hidden_key)
			if hidden_key.is_empty():
				continue
			known_keys.append(hidden_key)
			if action_args.has(hidden_key):
				_preserved_hidden_args[hidden_key] = (
					action_args[hidden_key]
				)

	var fields: Variant = metadata.get(
		"fields",
		[]
	)

	if fields is Array:
		for raw_field: Variant in fields:
			if not raw_field is Dictionary:
				continue

			var schema: Dictionary = (
				raw_field as Dictionary
			)
			var key: String = String(
				schema.get(
					"key",
                    ""
				)
			)

			if key.is_empty():
				continue

			known_keys.append(
				key
			)
			if String(schema.get("type", "")) == "lifecycle":
				for lifecycle_key: String in [
					"timing",
					"remaining_uses",
					"duration_turns",
					"duration_scope",
					"stack_mode",
					"value"
				]:
					known_keys.append(lifecycle_key)

			var field_value: Variant = action_args.get(
				key,
				schema.get(
					"default",
					null
				)
			)
			if String(schema.get("type", "")) == "lifecycle":
				field_value = action_args

			_create_field_control(
				schema,
				field_value
			)

	var supports_nested_actions: bool = bool(
		metadata.get(
			"supports_nested_actions",
			false
		)
	)
	nested_actions_box.visible = supports_nested_actions

	_clear_container(
		then_actions_rows
	)
	_clear_container(
		else_actions_rows
	)

	if supports_nested_actions:
		var then_value: Variant = action.get(
			"then",
			[]
		)
		if then_value is Array:
			for raw_nested: Variant in then_value:
				if raw_nested is Dictionary:
					_create_nested_action_row(
						then_actions_rows,
						raw_nested as Dictionary
					)

		var else_value: Variant = action.get(
			"else",
			[]
		)
		if else_value is Array:
			for raw_nested: Variant in else_value:
				if raw_nested is Dictionary:
					_create_nested_action_row(
						else_actions_rows,
						raw_nested as Dictionary
					)

	var allow_extra_args: bool = bool(
		metadata.get(
			"allow_extra_args",
			false
		)
	)

	var extra_args: Dictionary = {}
	for raw_key: Variant in action_args.keys():
		var key: String = String(
			raw_key
		)
		if not known_keys.has(
			key
		):
			extra_args[key] = action_args[
				raw_key
			]

	# Preserve unknown args for forward compatibility even when the current
	# metadata does not explicitly advertise them. They remain visible instead
	# of being silently deleted by the editor.
	extra_args_box.visible = (
		allow_extra_args
		or not extra_args.is_empty()
	)
	extra_args_json.text = JSON.stringify(
		extra_args,
        "  "
	)


func _create_field_control(
	schema: Dictionary,
	value: Variant
) -> void:
	var key: String = String(
		schema.get(
			"key",
            ""
		)
	)
	var field_type: String = String(
		schema.get(
			"type",
            "string"
		)
	)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(
		"separation",
		10
	)
	fields_box.add_child(
		row
	)

	var label: Label = Label.new()
	label.text = String(
		schema.get(
			"label",
			key
		)
	)
	label.custom_minimum_size.x = 190
	row.add_child(
		label
	)

	var control: Control = null

	match field_type:
		"int":
			var spin: SpinBox = SpinBox.new()
			spin.custom_minimum_size.x = 180
			spin.step = 1.0
			spin.min_value = float(
				schema.get(
					"min",
					-999999
				)
			)
			spin.max_value = float(
				schema.get(
					"max",
					999999
				)
			)
			spin.value = float(
				value
				if value != null
				else 0
			)
			spin.value_changed.connect(
				func(_new_value: float) -> void:
					_emit_changed()
			)
			control = spin

		"float":
			var spin: SpinBox = SpinBox.new()
			spin.custom_minimum_size.x = 180
			spin.step = 0.1
			spin.min_value = float(
				schema.get(
					"min",
					-999999.0
				)
			)
			spin.max_value = float(
				schema.get(
					"max",
					999999.0
				)
			)
			spin.value = float(
				value
				if value != null
				else 0.0
			)
			spin.value_changed.connect(
				func(_new_value: float) -> void:
					_emit_changed()
			)
			control = spin

		"enum":
			var option: OptionButton = (
				OptionButton.new()
			)
			option.custom_minimum_size.x = 240

			var options: Variant = schema.get(
				"options",
				[]
			)
			if options is Array:
				for raw_option: Variant in options:
					var option_value: String = String(
						raw_option
					)
					option.add_item(
						option_value.capitalize()
					)
					option.set_item_metadata(
						option.item_count - 1,
						option_value
					)

			_select_metadata(
				option,
				String(value),
				true
			)
			option.item_selected.connect(
				func(_index: int) -> void:
					_emit_changed()
			)
			control = option

		"lifecycle":
			var lifecycle_editor: VBoxContainer = (
				LIFECYCLE_EDITOR.new()
			)
			lifecycle_editor.size_flags_horizontal = (
				Control.SIZE_EXPAND_FILL
			)
			lifecycle_editor.initialize(
				value as Dictionary
				if value is Dictionary
				else {}
			)
			lifecycle_editor.changed.connect(
				_emit_changed
			)
			control = lifecycle_editor

		"condition":
			var editor: VBoxContainer = (
				CONDITION_EDITOR.new()
			)
			editor.size_flags_horizontal = (
				Control.SIZE_EXPAND_FILL
			)
			editor.initialize(
				(
					value as Dictionary
					if value is Dictionary
					else {
						"type": "always"
					}
				)
			)
			editor.changed.connect(
				_emit_changed
			)
			control = editor

		_:
			var edit: LineEdit = LineEdit.new()
			edit.custom_minimum_size.x = 300
			edit.size_flags_horizontal = (
				Control.SIZE_EXPAND_FILL
			)
			edit.text = String(
				value
				if value != null
				else ""
			)
			edit.text_changed.connect(
				func(_new_text: String) -> void:
					_emit_changed()
			)
			control = edit

	if control == null:
		return

	row.add_child(
		control
	)
	field_controls[key] = control
	field_metadata[key] = schema.duplicate(
		true
	)


func to_dictionary() -> Dictionary:
	var action_type: String = str(
		type_option.get_item_metadata(
			type_option.selected
		)
	)

	if action_type == "custom":
		# If the user has not edited the raw JSON, return the original
		# Dictionary verbatim. JSON.parse_string() normalizes JSON numbers
		# and can change an integer Variant into a float Variant.
		if (
			custom_json.text
			== _custom_source_text
			and not _custom_source_action.is_empty()
		):
			return _custom_source_action.duplicate(
				true
			)

		var parsed_custom: Variant = (
			JSON.parse_string(
				custom_json.text
			)
		)

		if parsed_custom is Dictionary:
			return (
				parsed_custom as Dictionary
			).duplicate(
				true
			)

		return {}

	var args: Dictionary = _preserved_hidden_args.duplicate(true)

	for raw_key: Variant in field_controls.keys():
		var key: String = String(
			raw_key
		)
		var control: Control = field_controls[
			raw_key
		]
		var schema: Dictionary = field_metadata.get(
			key,
			{}
		)
		var field_type: String = String(
			schema.get(
				"type",
                "string"
			)
		)

		match field_type:
			"int":
				args[key] = int(
					(control as SpinBox).value
				)
			"float":
				args[key] = float(
					(control as SpinBox).value
				)
			"enum":
				var option: OptionButton = (
					control as OptionButton
				)
				args[key] = str(
					option.get_item_metadata(
						option.selected
					)
				)
			"condition":
				args[key] = (
					control.to_dictionary()
					if control.has_method(
                        "to_dictionary"
					)
					else {}
				)
			"lifecycle":
				if control.has_method("to_dictionary"):
					var lifecycle_args: Dictionary = (
						control.to_dictionary()
					)
					for lifecycle_key: Variant in lifecycle_args.keys():
						args[lifecycle_key] = lifecycle_args[lifecycle_key]
			_:
				args[key] = (
					control as LineEdit
				).text

	if extra_args_box.visible:
		var parsed_extra: Variant = (
			JSON.parse_string(
				extra_args_json.text
			)
		)
		if parsed_extra is Dictionary:
			for raw_key: Variant in (
				parsed_extra as Dictionary
			).keys():
				args[raw_key] = (
					parsed_extra as Dictionary
				)[raw_key]

	var result: Dictionary = {
		"opcode": action_type,
		"args": args
	}

	if nested_actions_box.visible:
		result["then"] = _collect_nested_actions(
			then_actions_rows
		)
		result["else"] = _collect_nested_actions(
			else_actions_rows
		)

	return result


func is_valid_action() -> bool:
	var action_type: String = str(
		type_option.get_item_metadata(
			type_option.selected
		)
	)

	if action_type == "custom":
		var parsed: Variant = JSON.parse_string(
			custom_json.text
		)
		return (
			parsed is Dictionary
			and not String(
				(parsed as Dictionary).get(
					"opcode",
                    ""
				)
			).is_empty()
		)

	for raw_key: Variant in field_controls.keys():
		var key: String = String(
			raw_key
		)
		var schema: Dictionary = field_metadata.get(
			key,
			{}
		)

		var schema_type: String = String(
			schema.get(
				"type",
				""
			)
		)

		if schema_type == "condition":
			var condition_control: Control = (
				field_controls[key]
			)
			if (
				not condition_control.has_method(
                    "is_valid_condition"
				)
				or not condition_control.is_valid_condition()
			):
				return false

		if schema_type == "lifecycle":
			var lifecycle_control: Control = field_controls[key]
			if (
				not lifecycle_control.has_method("is_valid_lifecycle")
				or not lifecycle_control.is_valid_lifecycle()
			):
				return false

	if extra_args_box.visible:
		var parsed_extra: Variant = (
			JSON.parse_string(
				extra_args_json.text
			)
		)
		if not parsed_extra is Dictionary:
			return false

	if nested_actions_box.visible:
		if not _nested_actions_valid(
			then_actions_rows
		):
			return false
		if not _nested_actions_valid(
			else_actions_rows
		):
			return false

	return true


func _create_nested_action_row(
	container: VBoxContainer,
	action: Dictionary
) -> void:
	var action_script: Script = get_script()
	var row: VBoxContainer = action_script.new()
	container.add_child(
		row
	)
	row.initialize(
		action
	)
	row.changed.connect(
		_emit_changed
	)
	row.remove_requested.connect(
		func(target_row: Node) -> void:
			container.remove_child(
				target_row
			)
			target_row.queue_free()
			_emit_changed()
	)


func _collect_nested_actions(
	container: VBoxContainer
) -> Array:
	var result: Array = []

	for child: Node in container.get_children():
		if not child.has_method(
            "to_dictionary"
		):
			continue

		var action: Dictionary = (
			child.to_dictionary()
		)
		if not action.is_empty():
			result.append(
				action
			)

	return result


func _nested_actions_valid(
	container: VBoxContainer
) -> bool:
	for child: Node in container.get_children():
		if (
			child.has_method(
                "is_valid_action"
			)
			and not child.is_valid_action()
		):
			return false

	return true


func _show_custom_mode() -> void:
	_current_opcode = &"custom"
	_clear_container(
		fields_box
	)
	field_controls.clear()
	field_metadata.clear()

	fields_box.visible = false
	nested_actions_box.visible = false
	extra_args_box.visible = false
	custom_json.visible = true
	help_label.text = (
        "Unknown / advanced action. "
		+ "Raw JSON is preserved."
	)


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
