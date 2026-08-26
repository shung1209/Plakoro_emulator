extends RefCounted


const DESKTOP_SIZE: Vector2i = Vector2i(560, 165)
const NARROW_HEIGHT: int = 175
const VIEWPORT_MARGIN: int = 32
const MIN_WIDTH: int = 300


static func apply(dialog: ConfirmationDialog) -> Vector2i:
	var target_size: Vector2i = _target_size(dialog)
	dialog.min_size = target_size
	dialog.max_size = target_size
	dialog.unresizable = true
	dialog.size = target_size
	return target_size


static func popup(dialog: ConfirmationDialog) -> void:
	dialog.popup_centered(apply(dialog))


static func _target_size(dialog: ConfirmationDialog) -> Vector2i:
	var viewport_width: int = int(
		dialog.get_viewport().get_visible_rect().size.x
	)
	if viewport_width <= 0:
		return DESKTOP_SIZE

	var available_width: int = maxi(
		MIN_WIDTH,
		viewport_width - VIEWPORT_MARGIN
	)
	var width: int = mini(DESKTOP_SIZE.x, available_width)
	var height: int = (
		NARROW_HEIGHT
		if width < 480
		else DESKTOP_SIZE.y
	)
	return Vector2i(width, height)
