extends VBoxContainer


signal changed


const TIMING_OPTIONS: Array[String] = [
    "",
    "next_owner_turn",
    "next_owner_move",
    "next_incoming_attack"
]

const DURATION_SCOPE_OPTIONS: Array[String] = [
    "owner_turn"
]

const STACK_MODE_OPTIONS: Array[String] = [
    "add",
    "replace",
    "max",
    "min"
]


var timing_option: OptionButton
var remaining_uses_spin: SpinBox
var duration_turns_spin: SpinBox
var duration_scope_option: OptionButton
var stack_mode_option: OptionButton
var value_spin: SpinBox
var validation_label: Label

var _loading: bool = false
var _source_args: Dictionary = {}


func initialize(
    args: Dictionary = {}
) -> void:
    add_theme_constant_override(
        "separation",
        6
    )

    var title: Label = Label.new()
    title.text = LocalizationService.tr_key("move_editor.lifecycle_title", "Temporary / Lifecycle")
    title.modulate.a = 0.9
    add_child(title)

    var help: Label = Label.new()
    help.text = LocalizationService.tr_key(
        "move_editor.lifecycle_help",
        "Controls when the status is active, consumed, stacked, or expired. Use -1 Remaining Uses for unlimited uses."
    )
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.modulate.a = 0.72
    add_child(help)

    timing_option = _create_option_row(
        LocalizationService.tr_key("move_editor.timing", "Timing"),
        TIMING_OPTIONS
    )

    remaining_uses_spin = _create_int_row(
        LocalizationService.tr_key("move_editor.remaining_uses", "Remaining Uses"),
        -1,
        999999
    )

    duration_turns_spin = _create_int_row(
        LocalizationService.tr_key("move_editor.duration_owner_turns", "Duration (Owner Turns)"),
        0,
        999999
    )

    duration_scope_option = _create_option_row(
        LocalizationService.tr_key("move_editor.duration_scope", "Duration Scope"),
        DURATION_SCOPE_OPTIONS
    )

    stack_mode_option = _create_option_row(
        LocalizationService.tr_key("move_editor.stack_mode", "Stack Mode"),
        STACK_MODE_OPTIONS
    )

    value_spin = _create_int_row(
        LocalizationService.tr_key("move_editor.value", "Value"),
        -999999,
        999999
    )

    validation_label = Label.new()
    validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    validation_label.modulate.a = 0.82
    add_child(validation_label)

    timing_option.item_selected.connect(
        func(_index: int) -> void:
            _emit_changed()
    )
    remaining_uses_spin.value_changed.connect(
        func(_value: float) -> void:
            _emit_changed()
    )
    duration_turns_spin.value_changed.connect(
        func(_value: float) -> void:
            _emit_changed()
    )
    duration_scope_option.item_selected.connect(
        func(_index: int) -> void:
            _emit_changed()
    )
    stack_mode_option.item_selected.connect(
        func(_index: int) -> void:
            _emit_changed()
    )
    value_spin.value_changed.connect(
        func(_value: float) -> void:
            _emit_changed()
    )

    load_args(args)


func load_args(
    args: Dictionary
) -> void:
    _loading = true
    _source_args = args.duplicate(true)

    _select_metadata(
        timing_option,
        String(args.get("timing", "")),
        true
    )
    remaining_uses_spin.value = float(
        int(args.get("remaining_uses", 1))
    )
    duration_turns_spin.value = float(
        int(args.get("duration_turns", 0))
    )
    _select_metadata(
        duration_scope_option,
        String(args.get("duration_scope", "owner_turn")),
        true
    )
    _select_metadata(
        stack_mode_option,
        String(args.get("stack_mode", "add")),
        true
    )
    value_spin.value = float(
        int(args.get("value", 0))
    )

    _loading = false
    _refresh_validation()


func to_dictionary() -> Dictionary:
    var result: Dictionary = {}

    var timing: String = _selected_metadata(timing_option)
    var remaining_uses: int = int(remaining_uses_spin.value)
    var duration_turns: int = int(duration_turns_spin.value)
    var duration_scope: String = _selected_metadata(duration_scope_option)
    var stack_mode: String = _selected_metadata(stack_mode_option)
    var value: int = int(value_spin.value)

    if not timing.is_empty() or _source_args.has("timing"):
        result["timing"] = timing

    if remaining_uses != 1 or _source_args.has("remaining_uses"):
        result["remaining_uses"] = remaining_uses

    if duration_turns > 0 or _source_args.has("duration_turns"):
        result["duration_turns"] = duration_turns

    if (
        duration_turns > 0
        or _source_args.has("duration_scope")
    ):
        result["duration_scope"] = duration_scope

    if stack_mode != "add" or _source_args.has("stack_mode"):
        result["stack_mode"] = stack_mode

    if value != 0 or _source_args.has("value"):
        result["value"] = value

    return result


func is_valid_lifecycle() -> bool:
    var data: Dictionary = to_dictionary()

    if int(data.get("remaining_uses", 1)) == 0:
        return false

    if not TIMING_OPTIONS.has(
        String(data.get("timing", ""))
    ):
        return false

    if int(data.get("duration_turns", 0)) < 0:
        return false

    if (
        int(data.get("duration_turns", 0)) > 0
        and not DURATION_SCOPE_OPTIONS.has(
            String(data.get("duration_scope", ""))
        )
    ):
        return false

    if not STACK_MODE_OPTIONS.has(
        String(data.get("stack_mode", ""))
    ):
        return false

    return true


func _create_int_row(
    label_text: String,
    minimum: int,
    maximum: int
) -> SpinBox:
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    add_child(row)

    var label: Label = Label.new()
    label.text = label_text
    label.custom_minimum_size.x = 190
    row.add_child(label)

    var spin: SpinBox = SpinBox.new()
    spin.custom_minimum_size.x = 180
    spin.step = 1.0
    spin.min_value = float(minimum)
    spin.max_value = float(maximum)
    row.add_child(spin)
    return spin


func _create_option_row(
    label_text: String,
    options: Array[String]
) -> OptionButton:
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    add_child(row)

    var label: Label = Label.new()
    label.text = label_text
    label.custom_minimum_size.x = 190
    row.add_child(label)

    var option: OptionButton = OptionButton.new()
    option.custom_minimum_size.x = 260
    row.add_child(option)

    for value: String in options:
        option.add_item(
            LocalizationService.tr_key(
                "move_editor.option.none_immediate",
                "None / Immediate"
            )
            if value.is_empty()
            else LocalizationService.tr_key(
                "move_editor.option." + value,
                value.replace("_", " ").capitalize()
            )
        )
        option.set_item_metadata(
            option.item_count - 1,
            value
        )

    return option


func _selected_metadata(
    option: OptionButton
) -> String:
    if option.selected < 0:
        return ""
    return String(
        option.get_item_metadata(option.selected)
    )


func _select_metadata(
    option: OptionButton,
    value: String,
    add_if_missing: bool = false
) -> void:
    for index: int in range(option.item_count):
        if String(option.get_item_metadata(index)) == value:
            option.select(index)
            return

    if add_if_missing:
        option.add_item(value)
        option.set_item_metadata(
            option.item_count - 1,
            value
        )
        option.select(option.item_count - 1)


func _refresh_validation() -> void:
    if validation_label == null:
        return

    if int(remaining_uses_spin.value) == 0:
        validation_label.text = LocalizationService.tr_key(
            "move_editor.lifecycle_invalid_uses",
            "Invalid lifecycle: Remaining Uses cannot be 0. Use -1 for unlimited or a positive number."
        )
        return

    validation_label.text = LocalizationService.tr_key("move_editor.lifecycle_valid", "Lifecycle configuration is valid.")


func _emit_changed() -> void:
    if _loading:
        return

    _refresh_validation()
    changed.emit()
