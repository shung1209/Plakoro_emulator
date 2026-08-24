extends Control


var showing_heads: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_refresh_pivot)
	_refresh_pivot()
	queue_redraw()


func reset_visual() -> void:
	showing_heads = true
	scale = Vector2.ONE
	rotation = 0.0
	modulate = Color.WHITE
	_refresh_pivot()
	queue_redraw()


func play_flip(final_heads: bool) -> void:
	reset_visual()
	for cycle: int in 7:
		var squash: Tween = create_tween()
		squash.set_trans(Tween.TRANS_SINE)
		squash.set_ease(Tween.EASE_IN)
		squash.set_parallel(true)
		squash.tween_property(self, "scale", Vector2(0.07, 1.1), 0.075)
		squash.tween_property(
			self,
			"rotation",
			0.1 if cycle % 2 == 0 else -0.1,
			0.075
		)
		squash.tween_property(
			self,
			"modulate",
			Color(1.35, 1.22, 0.82, 1.0),
			0.075
		)
		await squash.finished

		showing_heads = not showing_heads
		queue_redraw()

		var expand: Tween = create_tween()
		expand.set_trans(Tween.TRANS_BACK)
		expand.set_ease(Tween.EASE_OUT)
		expand.set_parallel(true)
		expand.tween_property(self, "scale", Vector2.ONE, 0.09)
		expand.tween_property(
			self,
			"rotation",
			-0.055 if cycle % 2 == 0 else 0.055,
			0.09
		)
		expand.tween_property(self, "modulate", Color.WHITE, 0.09)
		await expand.finished

	showing_heads = final_heads
	queue_redraw()
	var settle: Tween = create_tween()
	settle.set_trans(Tween.TRANS_BACK)
	settle.set_ease(Tween.EASE_OUT)
	settle.tween_property(self, "scale", Vector2(1.13, 0.94), 0.1)
	settle.tween_property(self, "scale", Vector2.ONE, 0.18)
	settle.parallel().tween_property(self, "rotation", 0.0, 0.18)
	await settle.finished


func _refresh_pivot() -> void:
	pivot_offset = size * 0.5


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = min(size.x, size.y) * 0.5 - 10.0
	if radius <= 8.0:
		return

	draw_circle(
		center + Vector2(6.0, 8.0),
		radius,
		Color(0.07, 0.08, 0.12, 0.42)
	)
	draw_circle(center, radius, Color("#9b5d13"))
	draw_circle(center, radius - 4.0, Color("#f2b72d"))
	draw_circle(center, radius - 10.0, Color("#ffd96a"))
	draw_circle(center, radius - 15.0, Color("#d99518"))
	draw_circle(center, radius - 18.0, Color("#f6c94f"))
	draw_arc(
		center,
		radius - 7.0,
		PI * 1.08,
		PI * 1.82,
		32,
		Color(1.0, 0.96, 0.7, 0.9),
		5.0,
		true
	)
	draw_arc(
		center,
		radius - 12.0,
		PI * 0.02,
		PI * 0.72,
		32,
		Color(0.48, 0.25, 0.04, 0.48),
		4.0,
		true
	)

	if showing_heads:
		_draw_heads(center, radius)
	else:
		_draw_tails(center, radius)


func _draw_heads(center: Vector2, radius: float) -> void:
	var emboss: Color = Color("#7a4710")
	var shine: Color = Color(1.0, 0.88, 0.42, 0.72)
	var head_center: Vector2 = center + Vector2(-3.0, -radius * 0.22)
	draw_circle(head_center, radius * 0.22, emboss)
	var nose: PackedVector2Array = PackedVector2Array([
		head_center + Vector2(radius * 0.18, -radius * 0.05),
		head_center + Vector2(radius * 0.31, radius * 0.04),
		head_center + Vector2(radius * 0.17, radius * 0.1)
	])
	draw_colored_polygon(nose, emboss)
	var shoulders: PackedVector2Array = PackedVector2Array([
		center + Vector2(-radius * 0.43, radius * 0.42),
		center + Vector2(-radius * 0.31, radius * 0.18),
		center + Vector2(-radius * 0.12, radius * 0.08),
		center + Vector2(radius * 0.18, radius * 0.12),
		center + Vector2(radius * 0.43, radius * 0.42)
	])
	draw_colored_polygon(shoulders, emboss)
	draw_arc(
		head_center + Vector2(-2.0, -2.0),
		radius * 0.17,
		PI * 1.05,
		PI * 1.8,
		18,
		shine,
		3.0,
		true
	)
	draw_circle(
		head_center + Vector2(radius * 0.1, -radius * 0.04),
		2.4,
		shine
	)


func _draw_tails(center: Vector2, radius: float) -> void:
	var emboss: Color = Color("#75420d")
	var shine: Color = Color(1.0, 0.9, 0.48, 0.78)
	draw_circle(center, radius * 0.18, emboss)
	draw_circle(center, radius * 0.1, Color("#f5bd36"))
	for spoke: int in 8:
		var angle: float = TAU * float(spoke) / 8.0
		var direction: Vector2 = Vector2.from_angle(angle)
		draw_line(
			center + direction * radius * 0.24,
			center + direction * radius * 0.48,
			emboss,
			7.0,
			true
		)
		draw_circle(
			center + direction * radius * 0.55,
			radius * 0.055,
			emboss
		)
	draw_arc(
		center,
		radius * 0.66,
		PI * 1.05,
		PI * 1.75,
		24,
		shine,
		4.0,
		true
	)
