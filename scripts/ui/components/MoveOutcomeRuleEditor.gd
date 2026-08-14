extends VBoxContainer


signal changed
signal remove_requested(rule)


const ACTION_ROW: Script = preload(
    "res://scripts/ui/components/MoveActionEditorRow.gd"
)
const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)

const ORIENTATIONS: Array[StringName] = [
    &"FACE_DOWN",
    &"FACE_UP",
    &"HEAD_UP",
    &"HEAD_DOWN",
    &"HEAD_LEFT",
    &"HEAD_RIGHT"
]


var orientation_checks: Dictionary = {}
var action_rows: VBoxContainer
var raw_text_edit: TextEdit

var _loading: bool = false


func initialize(
    rule: Dictionary = {}
) -> void:
    add_theme_constant_override(
        "separation",
        8
    )

    var header: HBoxContainer = HBoxContainer.new()
    header.add_theme_constant_override(
        "separation",
        10
    )
    add_child(header)

    var title: Label = Label.new()
    title.text = "Charakoro Outcome Rule"
    title.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )
    header.add_child(title)

    var remove_button: Button = Button.new()
    remove_button.text = "Remove Rule"
    remove_button.custom_minimum_size.x = 130
    header.add_child(remove_button)

    remove_button.pressed.connect(
        func() -> void:
            remove_requested.emit(
                self
            )
    )

    var orientation_title: Label = Label.new()
    orientation_title.text = (
        "When Charakoro orientation is any of:"
    )
    add_child(orientation_title)

    var orientation_row: HBoxContainer = HBoxContainer.new()
    orientation_row.add_theme_constant_override(
        "separation",
        12
    )
    add_child(orientation_row)

    for orientation: StringName in ORIENTATIONS:
        var card: VBoxContainer = VBoxContainer.new()
        card.alignment = (
            BoxContainer.ALIGNMENT_CENTER
        )
        orientation_row.add_child(card)

        var icon: TextureRect = TextureRect.new()
        icon.custom_minimum_size = Vector2(
            34,
            34
        )
        icon.size_flags_horizontal = (
            Control.SIZE_SHRINK_CENTER
        )
        icon.expand_mode = (
            TextureRect.EXPAND_IGNORE_SIZE
        )
        icon.stretch_mode = (
            TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        )
        icon.texture = ICONS.load_kyokoro_icon(
            orientation
        )
        card.add_child(icon)

        var check: CheckBox = CheckBox.new()
        check.text = String(
            orientation
        )
        check.button_pressed = false
        card.add_child(check)

        orientation_checks[
            orientation
        ] = check

        check.toggled.connect(
            func(_pressed: bool) -> void:
                _emit_changed()
        )

    var actions_header: HBoxContainer = HBoxContainer.new()
    add_child(actions_header)

    var actions_title: Label = Label.new()
    actions_title.text = "Actions"
    actions_title.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )
    actions_header.add_child(actions_title)

    var add_action_button: Button = Button.new()
    add_action_button.text = "+ Add Action"
    actions_header.add_child(
        add_action_button
    )

    action_rows = VBoxContainer.new()
    action_rows.add_theme_constant_override(
        "separation",
        8
    )
    add_child(action_rows)

    add_action_button.pressed.connect(
        func() -> void:
            _create_action_row({})
            _emit_changed()
    )

    var raw_label: Label = Label.new()
    raw_label.text = "raw_text"
    add_child(raw_label)

    raw_text_edit = TextEdit.new()
    raw_text_edit.custom_minimum_size.y = 86
    raw_text_edit.wrap_mode = (
        TextEdit.LINE_WRAPPING_BOUNDARY
    )
    add_child(raw_text_edit)
    raw_text_edit.text_changed.connect(
        _emit_changed
    )

    load_rule(
        rule
    )


func load_rule(
    rule: Dictionary
) -> void:
    _loading = true

    var selected: Array = []

    var condition: Variant = rule.get(
        "condition",
        {}
    )

    if condition is Dictionary:
        var raw_orientations: Variant = (
            (condition as Dictionary).get(
                "orientations",
                []
            )
        )

        if raw_orientations is Array:
            selected = raw_orientations as Array

    for orientation: StringName in ORIENTATIONS:
        orientation_checks[
            orientation
        ].button_pressed = (
            selected.has(
                String(
                    orientation
                )
            )
            or selected.has(
                orientation
            )
        )

    for child: Node in action_rows.get_children():
        action_rows.remove_child(
            child
        )
        child.queue_free()

    var actions: Variant = rule.get(
        "actions",
        []
    )

    if actions is Array:
        for raw_action: Variant in actions:
            if raw_action is Dictionary:
                _create_action_row(
                    raw_action as Dictionary
                )

    raw_text_edit.text = String(
        rule.get(
            "raw_text",
            ""
        )
    )

    _loading = false


func to_dictionary() -> Dictionary:
    var orientations: Array[String] = []

    for orientation: StringName in ORIENTATIONS:
        if bool(
            orientation_checks[
                orientation
            ].button_pressed
        ):
            orientations.append(
                String(
                    orientation
                )
            )

    var actions: Array = []

    for child: Node in action_rows.get_children():
        if child.has_method(
            "to_dictionary"
        ):
            var action: Dictionary = (
                child.to_dictionary()
            )

            if not action.is_empty():
                actions.append(
                    action
                )

    var result: Dictionary = {
        "condition": {
            "type": "kyokoro_orientation_any",
            "orientations": orientations
        },
        "actions": actions
    }

    if not raw_text_edit.text.strip_edges().is_empty():
        result["raw_text"] = (
            raw_text_edit.text.strip_edges()
        )

    return result


func is_valid_rule() -> bool:
    var rule: Dictionary = to_dictionary()
    var condition: Dictionary = rule.get(
        "condition",
        {}
    )

    var orientations: Variant = condition.get(
        "orientations",
        []
    )

    if (
        not orientations is Array
        or (
            orientations as Array
        ).is_empty()
    ):
        return false

    for child: Node in action_rows.get_children():
        if (
            child.has_method(
                "is_valid_action"
            )
            and not child.is_valid_action()
        ):
            return false

    return true


func _create_action_row(
    action: Dictionary
) -> void:
    var row: VBoxContainer = ACTION_ROW.new()
    action_rows.add_child(
        row
    )
    row.initialize(
        action
    )
    row.changed.connect(
        _emit_changed
    )
    row.remove_requested.connect(
        _remove_action_row
    )


func _remove_action_row(
    row: Node
) -> void:
    action_rows.remove_child(
        row
    )
    row.queue_free()
    _emit_changed()


func _emit_changed() -> void:
    if _loading:
        return

    changed.emit()
