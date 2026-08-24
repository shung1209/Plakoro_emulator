extends Node

# Web-only usability pass for desktop browsers and touch-friendly landscape play.
# This intentionally does not introduce responsive/mobile re-layouts; it only
# increases the hit area and text size of ordinary textual controls.

const MIN_TEXT_BUTTON_HEIGHT: float = 52.0
const MIN_OPTION_HEIGHT: float = 52.0
const MIN_WEB_FONT_SIZE: int = 17
const MIN_WEB_SCROLLBAR_WIDTH: float = 22.0

var _bound: Dictionary = {}


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply_existing")


func _apply_existing() -> void:
	var root: Node = get_tree().root
	if root != null:
		_apply_recursive(root)


func _apply_recursive(node: Node) -> void:
	_apply_node(node)
	for child: Node in node.get_children():
		_apply_recursive(child)


func _on_node_added(node: Node) -> void:
	if not OS.has_feature("web"):
		return
	call_deferred("_apply_node", node)


func _apply_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var id: int = node.get_instance_id()
	if _bound.has(id):
		return

	if node is ScrollContainer:
		_bound[id] = true
		var scroll_container: ScrollContainer = node as ScrollContainer
		# Web users should always have a visible, draggable vertical scrollbar
		# whenever the container is configured for vertical scrolling. This is
		# much easier to operate with a mouse or a thumb in landscape mode than
		# relying only on wheel/touch gestures.
		if scroll_container.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
			var vertical_bar: VScrollBar = scroll_container.get_v_scroll_bar()
			if vertical_bar != null:
				vertical_bar.custom_minimum_size.x = maxf(
					vertical_bar.custom_minimum_size.x,
					MIN_WEB_SCROLLBAR_WIDTH
				)
		return

	if node is OptionButton:
		_bound[id] = true
		var option: OptionButton = node as OptionButton
		option.custom_minimum_size.y = maxf(
			option.custom_minimum_size.y,
			MIN_OPTION_HEIGHT
		)
		option.add_theme_font_size_override(
			"font_size",
			maxi(MIN_WEB_FONT_SIZE, option.get_theme_font_size("font_size"))
		)
		return

	if node is Button:
		var button: Button = node as Button
		# Move cards are already large, image-driven touch targets, so the
		# global text-button sizing pass should not reshape them.
		var script_resource: Script = button.get_script() as Script
		if script_resource != null and script_resource.resource_path.ends_with("PlakoroMoveButton.gd"):
			return
		if button.text.strip_edges().is_empty():
			return
		_bound[id] = true
		button.custom_minimum_size.y = maxf(
			button.custom_minimum_size.y,
			MIN_TEXT_BUTTON_HEIGHT
		)
		button.add_theme_font_size_override(
			"font_size",
			maxi(MIN_WEB_FONT_SIZE, button.get_theme_font_size("font_size"))
		)
