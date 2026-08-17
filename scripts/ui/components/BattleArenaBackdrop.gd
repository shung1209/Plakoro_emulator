extends Control


const TOP_COLOR: Color = Color(0.105, 0.255, 0.115, 1.0)
const BOTTOM_COLOR: Color = Color(0.055, 0.155, 0.085, 1.0)
const PLAYER_GLOW: Color = Color(0.18, 0.62, 1.0, 0.11)
const ENEMY_GLOW: Color = Color(1.0, 0.30, 0.34, 0.10)
const FIELD_LINE: Color = Color(0.78, 0.94, 0.67, 0.18)
const FIELD_FILL: Color = Color(0.60, 0.88, 0.42, 0.055)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var bounds: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bounds, TOP_COLOR)

	var band_count: int = 20
	for band: int in range(band_count):
		var ratio: float = float(band) / float(band_count)
		var band_rect: Rect2 = Rect2(
			0.0,
			size.y * ratio,
			size.x,
			size.y / float(band_count) + 1.0
		)
		draw_rect(band_rect, TOP_COLOR.lerp(BOTTOM_COLOR, ratio))

	_draw_glow(Vector2(size.x * 0.22, size.y * 0.78), PLAYER_GLOW)
	_draw_glow(Vector2(size.x * 0.78, size.y * 0.22), ENEMY_GLOW)
	_draw_playmat_field()


func _draw_playmat_field() -> void:
	var field_rect: Rect2 = Rect2(
		size.x * 0.245,
		size.y * 0.10,
		size.x * 0.51,
		size.y * 0.80
	)
	draw_rect(field_rect, FIELD_FILL)
	draw_rect(field_rect, FIELD_LINE, false, 2.0)

	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.5)
	var target_radius: float = min(size.x, size.y) * 0.185
	for ring: int in range(4, 0, -1):
		var ratio: float = float(ring) / 4.0
		var ring_color: Color = Color(0.83, 0.96, 0.70, 0.045)
		if ring % 2 == 0:
			ring_color.a = 0.105
		draw_circle(center, target_radius * ratio, ring_color)
	draw_arc(center, target_radius, 0.0, TAU, 96, FIELD_LINE, 2.0)
	draw_arc(center, target_radius * 0.48, 0.0, TAU, 96, FIELD_LINE, 2.0)
	draw_circle(center, target_radius * 0.12, Color(0.88, 0.97, 0.75, 0.16))

	draw_line(
		Vector2(field_rect.position.x, center.y),
		Vector2(field_rect.end.x, center.y),
		FIELD_LINE,
		2.0
	)

	_draw_card_zones(size.y * 0.055)
	_draw_card_zones(size.y * 0.875)


func _draw_card_zones(y: float) -> void:
	var zone_width: float = min(118.0, size.x * 0.072)
	var zone_height: float = min(62.0, size.y * 0.060)
	var separation: float = 12.0
	var total_width: float = zone_width * 4.0 + separation * 3.0
	var start_x: float = size.x * 0.5 - total_width * 0.5

	for zone: int in range(4):
		var rect: Rect2 = Rect2(
			start_x + float(zone) * (zone_width + separation),
			y,
			zone_width,
			zone_height
		)
		draw_rect(rect, Color(0.82, 0.95, 0.72, 0.035))
		draw_rect(rect, Color(0.82, 0.95, 0.72, 0.12), false, 1.0)


func _draw_glow(center: Vector2, color: Color) -> void:
	var max_radius: float = min(size.x, size.y) * 0.42
	for ring: int in range(12, 0, -1):
		var ratio: float = float(ring) / 12.0
		var ring_color: Color = color
		ring_color.a *= (1.0 - ratio) * 0.32
		draw_circle(center, max_radius * ratio, ring_color)
