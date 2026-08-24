extends Node

# Global UI micro-interaction layer for Plakoro.
# Keeps motion subtle and reusable instead of hardcoding tweens per screen.
# Designed to preserve keyboard/gamepad focus behavior and work with the
# shared Plakoro theme (including the non-white focus treatment).

const MOTION_ENABLED: bool = true
const BUTTON_HOVER_LIFT: float = 3.0
const BUTTON_HOVER_SCALE: float = 1.022
const BUTTON_PRESS_DROP: float = 1.0
const BUTTON_PRESS_SCALE: float = 0.985
const FOCUS_SCALE: float = 1.010
const HOVER_DURATION: float = 0.11
const PRESS_DURATION: float = 0.065
const RELEASE_DURATION: float = 0.10
const POPUP_SLIDE_PIXELS: int = 10
const POPUP_DURATION: float = 0.13
const DIALOG_SLIDE_PIXELS: int = 14
const DIALOG_DURATION: float = 0.16
const PAGE_SLIDE_PIXELS: float = 8.0
const PAGE_DURATION: float = 0.18

var _bound_nodes: Dictionary = {}
var _button_state: Dictionary = {}
var _tweens: Dictionary = {}
var _last_scene_id: int = 0


func _ready() -> void:
	if not MOTION_ENABLED:
		return

	get_tree().node_added.connect(_on_node_added)
	call_deferred("_bind_existing_tree")
	set_process(true)


func _process(_delta: float) -> void:
	if not MOTION_ENABLED:
		return

	var scene := get_tree().current_scene
	if scene == null:
		return

	var scene_id: int = scene.get_instance_id()
	if scene_id == _last_scene_id:
		return

	_last_scene_id = scene_id
	call_deferred("_animate_current_scene")


func _bind_existing_tree() -> void:
	var root := get_tree().root
	if root == null:
		return
	_bind_recursive(root)


func _bind_recursive(node: Node) -> void:
	_bind_node(node)
	for child: Node in node.get_children():
		_bind_recursive(child)


func _on_node_added(node: Node) -> void:
	call_deferred("_bind_node", node)


func _bind_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return

	var id: int = node.get_instance_id()
	if _bound_nodes.has(id):
		return

	# Toggle fields should stay visually anchored. Their checked/color state is
	# already strong feedback, and scale/lift motion makes settings rows feel
	# unstable (especially on touch/Web). Do not bind motion to them.
	if node is CheckButton or node is CheckBox:
		_bound_nodes[id] = true
		return

	if node is OptionButton:
		_bound_nodes[id] = true
		_bind_button(node as BaseButton)
		_bind_option_button(node as OptionButton)
		return

	if node is BaseButton:
		_bound_nodes[id] = true
		_bind_button(node as BaseButton)
		return

	if node is LineEdit:
		_bound_nodes[id] = true
		_bind_line_edit(node as LineEdit)
		return

	if node is TextEdit:
		_bound_nodes[id] = true
		_bind_text_edit(node as TextEdit)
		return

	if node is AcceptDialog or node is ConfirmationDialog:
		_bound_nodes[id] = true
		_bind_window_popup(node as Window)
		return

	if node is PopupPanel:
		_bound_nodes[id] = true
		_bind_window_popup(node as Window)


func _bind_button(button: BaseButton) -> void:
	if button == null:
		return

	var id := button.get_instance_id()
	_button_state[id] = {
		"hovered": false,
		"pressed": false,
		"focused": false,
		"base_position": button.position,
		"base_scale": button.scale,
	}

	button.resized.connect(_update_control_pivot.bind(button))
	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))
	button.focus_entered.connect(_on_button_focus_entered.bind(button))
	button.focus_exited.connect(_on_button_focus_exited.bind(button))
	button.tree_exiting.connect(_cleanup_control.bind(id))
	_update_control_pivot(button)


func _bind_option_button(option: OptionButton) -> void:
	if option == null:
		return
	var popup: PopupMenu = option.get_popup()
	if popup == null:
		return

	var popup_id: int = popup.get_instance_id()
	if not _bound_nodes.has(popup_id):
		_bound_nodes[popup_id] = true
		popup.about_to_popup.connect(_on_popup_about_to_show.bind(popup))
		popup.tree_exiting.connect(_cleanup_control.bind(popup_id))


func _bind_line_edit(edit: LineEdit) -> void:
	edit.resized.connect(_update_control_pivot.bind(edit))
	edit.focus_entered.connect(_on_input_focus_entered.bind(edit))
	edit.focus_exited.connect(_on_input_focus_exited.bind(edit))
	edit.tree_exiting.connect(_cleanup_control.bind(edit.get_instance_id()))
	_update_control_pivot(edit)


func _bind_text_edit(edit: TextEdit) -> void:
	edit.resized.connect(_update_control_pivot.bind(edit))
	edit.focus_entered.connect(_on_input_focus_entered.bind(edit))
	edit.focus_exited.connect(_on_input_focus_exited.bind(edit))
	edit.tree_exiting.connect(_cleanup_control.bind(edit.get_instance_id()))
	_update_control_pivot(edit)


func _bind_window_popup(window: Window) -> void:
	if window == null:
		return
	window.about_to_popup.connect(_on_window_about_to_show.bind(window))
	window.tree_exiting.connect(_cleanup_control.bind(window.get_instance_id()))


func _update_control_pivot(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5


func _on_button_mouse_entered(button: BaseButton) -> void:
	if not _can_animate_button(button):
		return
	var state := _get_button_state(button)
	state["hovered"] = true
	state["base_position"] = button.position
	state["base_scale"] = button.scale
	_button_state[button.get_instance_id()] = state
	_animate_button_to(
		button,
		Vector2(0.0, -BUTTON_HOVER_LIFT),
		BUTTON_HOVER_SCALE,
		HOVER_DURATION
	)


func _on_button_mouse_exited(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button):
		return
	var state := _get_button_state(button)
	state["hovered"] = false
	_button_state[button.get_instance_id()] = state
	if bool(state.get("pressed", false)):
		return
	if bool(state.get("focused", false)):
		_animate_button_to(button, Vector2.ZERO, FOCUS_SCALE, RELEASE_DURATION)
	else:
		_animate_button_to(button, Vector2.ZERO, 1.0, RELEASE_DURATION)


func _on_button_down(button: BaseButton) -> void:
	if not _can_animate_button(button):
		return
	var state := _get_button_state(button)
	state["pressed"] = true
	_button_state[button.get_instance_id()] = state
	_animate_button_to(
		button,
		Vector2(0.0, BUTTON_PRESS_DROP),
		BUTTON_PRESS_SCALE,
		PRESS_DURATION
	)


func _on_button_up(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button):
		return
	var state := _get_button_state(button)
	state["pressed"] = false
	_button_state[button.get_instance_id()] = state
	if bool(state.get("hovered", false)):
		_animate_button_to(
			button,
			Vector2(0.0, -BUTTON_HOVER_LIFT),
			BUTTON_HOVER_SCALE,
			RELEASE_DURATION
		)
	elif bool(state.get("focused", false)):
		_animate_button_to(button, Vector2.ZERO, FOCUS_SCALE, RELEASE_DURATION)
	else:
		_animate_button_to(button, Vector2.ZERO, 1.0, RELEASE_DURATION)


func _on_button_focus_entered(button: BaseButton) -> void:
	if not _can_animate_button(button):
		return
	var state := _get_button_state(button)
	state["focused"] = true
	_button_state[button.get_instance_id()] = state
	if not bool(state.get("hovered", false)) and not bool(state.get("pressed", false)):
		_animate_button_to(button, Vector2.ZERO, FOCUS_SCALE, HOVER_DURATION)


func _on_button_focus_exited(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button):
		return
	var state := _get_button_state(button)
	state["focused"] = false
	_button_state[button.get_instance_id()] = state
	if not bool(state.get("hovered", false)) and not bool(state.get("pressed", false)):
		_animate_button_to(button, Vector2.ZERO, 1.0, RELEASE_DURATION)


func _animate_button_to(
	button: BaseButton,
	offset: Vector2,
	scale_multiplier: float,
	duration: float
) -> void:
	if button == null or not is_instance_valid(button):
		return

	var state := _get_button_state(button)
	var base_position: Vector2 = state.get("base_position", button.position)
	var base_scale: Vector2 = state.get("base_scale", Vector2.ONE)
	var target_position := base_position + offset
	var target_scale := base_scale * scale_multiplier
	var tween := _replace_tween(button.get_instance_id())
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)

	# A Container owns the position of its children. Tweening the position of
	# a Button inside VBox/HBox/Grid containers fights the layout pass and can
	# accumulate offsets after focus changes or OptionButton popups. Keep the
	# tactile scale response for container-managed buttons, but never move them.
	# Buttons outside a Container can still use the subtle vertical lift/drop.
	if not (button.get_parent() is Container):
		tween.tween_property(button, "position", target_position, duration)
	tween.tween_property(button, "scale", target_scale, duration)


func _on_input_focus_entered(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.set_meta("plakoro_motion_base_scale", control.scale)
	var tween := _replace_tween(control.get_instance_id())
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		control,
		"scale",
		control.scale * 1.006,
		0.10
	)


func _on_input_focus_exited(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	var base_scale: Vector2 = control.get_meta(
		"plakoro_motion_base_scale",
		Vector2.ONE
	)
	var tween := _replace_tween(control.get_instance_id())
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", base_scale, 0.10)


func _on_popup_about_to_show(popup: PopupMenu) -> void:
	if popup == null or not is_instance_valid(popup):
		return
	call_deferred("_animate_popup_menu", popup)


func _animate_popup_menu(popup: PopupMenu) -> void:
	if popup == null or not is_instance_valid(popup) or not popup.visible:
		return
	var final_position: Vector2i = popup.position
	popup.position = final_position + Vector2i(0, -POPUP_SLIDE_PIXELS)
	var tween := _replace_tween(popup.get_instance_id())
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "position", final_position, POPUP_DURATION)


func _on_window_about_to_show(window: Window) -> void:
	if window == null or not is_instance_valid(window):
		return
	call_deferred("_animate_window_popup", window)


func _animate_window_popup(window: Window) -> void:
	if window == null or not is_instance_valid(window) or not window.visible:
		return
	var final_position: Vector2i = window.position
	window.position = final_position + Vector2i(0, DIALOG_SLIDE_PIXELS)
	var tween := _replace_tween(window.get_instance_id())
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(window, "position", final_position, DIALOG_DURATION)


func _animate_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene == null or not scene is Control:
		return

	var control := scene as Control
	# Battle presentation already contains its own high-frequency animation.
	# Only use a very light entrance so it does not fight with battle VFX/HUD.
	var original_position: Vector2 = control.position
	var original_modulate: Color = control.modulate
	control.position = original_position + Vector2(0.0, PAGE_SLIDE_PIXELS)
	control.modulate = Color(
		original_modulate.r,
		original_modulate.g,
		original_modulate.b,
		0.0
	)

	var tween := _replace_tween(control.get_instance_id())
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(control, "position", original_position, PAGE_DURATION)
	tween.tween_property(control, "modulate", original_modulate, PAGE_DURATION)


func _can_animate_button(button: BaseButton) -> bool:
	return (
		button != null
		and is_instance_valid(button)
		and button.visible
		and not button.disabled
	)


func _get_button_state(button: BaseButton) -> Dictionary:
	var id := button.get_instance_id()
	if not _button_state.has(id):
		_button_state[id] = {
			"hovered": false,
			"pressed": false,
			"focused": false,
			"base_position": button.position,
			"base_scale": button.scale,
		}
	return _button_state[id]


func _replace_tween(id: int) -> Tween:
	if _tweens.has(id):
		var old_tween: Variant = _tweens[id]
		if old_tween is Tween and old_tween.is_valid():
			old_tween.kill()
	var tween := create_tween()
	_tweens[id] = tween
	return tween


func _cleanup_control(id: int) -> void:
	if _tweens.has(id):
		var tween: Variant = _tweens[id]
		if tween is Tween and tween.is_valid():
			tween.kill()
		_tweens.erase(id)
	_button_state.erase(id)
	_bound_nodes.erase(id)
