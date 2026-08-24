extends Control


signal finished


const EFFECT_DURATION: float = 1.05
const PROJECTILE_END: float = 0.36

var _attack_type: StringName = &"normal"
var _source: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _completed: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(false)


func play(
	source_anchor: Control,
	target_anchor: Control,
	attack_type: StringName
) -> void:
	_attack_type = attack_type if attack_type != &"" else &"normal"

	# Allow the full-rect overlay to receive its final canvas transform before
	# converting the combatant anchors into local drawing coordinates.
	await get_tree().process_frame

	_source = _anchor_center_in_local_space(source_anchor)
	_target = _anchor_center_in_local_space(target_anchor)
	_elapsed = 0.0
	_completed = false
	set_process(true)
	queue_redraw()

	await finished
	queue_free()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

	if _elapsed < EFFECT_DURATION or _completed:
		return

	_completed = true
	set_process(false)
	finished.emit()


func _draw() -> void:
	var progress: float = clamp(_elapsed / EFFECT_DURATION, 0.0, 1.0)
	var projectile_progress: float = clamp(
		progress / PROJECTILE_END,
		0.0,
		1.0
	)
	var impact_progress: float = clamp(
		(progress - PROJECTILE_END) / (1.0 - PROJECTILE_END),
		0.0,
		1.0
	)

	_draw_attack_travel(projectile_progress)

	if impact_progress <= 0.0:
		return

	_draw_screen_accent(impact_progress)

	match _attack_type:
		&"fire":
			_draw_fire_impact(impact_progress)
		&"water":
			_draw_water_impact(impact_progress)
		&"electric":
			_draw_electric_impact(impact_progress)
		&"grass":
			_draw_grass_impact(impact_progress)
		&"psychic":
			_draw_psychic_impact(impact_progress)
		&"fighting":
			_draw_fighting_impact(impact_progress)
		&"dark":
			_draw_dark_impact(impact_progress)
		&"steel":
			_draw_steel_impact(impact_progress)
		&"flying":
			_draw_flying_impact(impact_progress)
		_:
			_draw_normal_impact(impact_progress)


func _draw_attack_travel(progress: float) -> void:
	if progress >= 1.0:
		return

	match _attack_type:
		&"fire":
			_draw_fire_travel(progress)
		&"water":
			_draw_water_travel(progress)
		&"electric":
			_draw_electric_travel(progress)
		&"grass":
			_draw_grass_travel(progress)
		&"psychic":
			_draw_psychic_travel(progress)
		&"fighting":
			_draw_fighting_travel(progress)
		&"dark":
			_draw_dark_travel(progress)
		&"steel":
			_draw_steel_travel(progress)
		&"flying":
			_draw_flying_travel(progress)
		_:
			_draw_generic_travel(progress, _type_color(_attack_type))


func _travel_position(progress: float) -> Vector2:
	var eased: float = 1.0 - pow(1.0 - progress, 3.0)
	return _source.lerp(_target, eased)


func _travel_direction() -> Vector2:
	var direction: Vector2 = (_target - _source).normalized()
	return direction if direction.length_squared() > 0.001 else Vector2.RIGHT


func _draw_generic_travel(progress: float, primary: Color) -> void:
	var position: Vector2 = _travel_position(progress)
	var fade: float = 1.0 - progress
	var direction: Vector2 = _travel_direction()
	draw_circle(position, 14.0 + 8.0 * sin(progress * PI), Color(primary.r, primary.g, primary.b, 0.95))
	draw_circle(position, 5.0, Color(1.0, 1.0, 1.0, 0.95))
	for index: int in range(7):
		var offset: Vector2 = direction * -float(index + 1) * 15.0
		draw_circle(position + offset, max(2.0, 9.0 - float(index)), Color(primary.r, primary.g, primary.b, max(0.0, 0.7 - float(index) * 0.09) * fade))


func _draw_fire_travel(progress: float) -> void:
	var position: Vector2 = _travel_position(progress)
	var direction: Vector2 = _travel_direction()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	var pulse: float = 1.0 + 0.18 * sin(progress * 24.0)
	# Large comet head with layered hot core.
	draw_circle(position, 22.0 * pulse, Color(1.0, 0.16, 0.02, 0.88))
	draw_circle(position, 15.0 * pulse, Color(1.0, 0.48, 0.02, 0.95))
	draw_circle(position, 7.0 * pulse, Color(1.0, 0.96, 0.55, 1.0))
	# Jagged flame tail is deliberately asymmetrical for a recognizable silhouette.
	var tail: PackedVector2Array = PackedVector2Array([
		position + normal * 15.0,
		position - direction * 86.0 + normal * 6.0,
		position - direction * 58.0,
		position - direction * 98.0 - normal * 8.0,
		position - normal * 15.0
	])
	draw_colored_polygon(tail, Color(1.0, 0.26, 0.02, 0.72))
	for index: int in range(9):
		var lane: float = float(index) - 4.0
		var ember_pos: Vector2 = position - direction * (28.0 + float(index) * 8.0) + normal * lane * 3.5
		ember_pos += normal * sin(progress * 20.0 + float(index)) * 7.0
		draw_circle(ember_pos, 2.5 + float(index % 3), Color(1.0, 0.72, 0.08, 0.8))


func _draw_water_travel(progress: float) -> void:
	var position: Vector2 = _travel_position(progress)
	var direction: Vector2 = _travel_direction()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	draw_circle(position, 21.0, Color(0.1, 0.55, 1.0, 0.82))
	draw_circle(position - Vector2(5.0, 5.0), 8.0, Color(0.75, 0.95, 1.0, 0.9))
	for index: int in range(6):
		var back: float = 20.0 + float(index) * 14.0
		var wave_center: Vector2 = position - direction * back + normal * sin(progress * 18.0 + float(index)) * 10.0
		draw_arc(wave_center, 8.0 + float(index % 2) * 3.0, 0.0, TAU, 18, Color(0.3, 0.8, 1.0, 0.6), 3.0, true)


func _draw_electric_travel(progress: float) -> void:
	var direction: Vector2 = _travel_direction()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	var end_pos: Vector2 = _travel_position(progress)
	var start_pos: Vector2 = end_pos - direction * 105.0
	var points: PackedVector2Array = PackedVector2Array([start_pos])
	for segment: int in range(1, 8):
		var t: float = float(segment) / 7.0
		var base: Vector2 = start_pos.lerp(end_pos, t)
		var zig: float = sin(float(segment) * 4.7 + progress * 32.0) * (13.0 if segment < 7 else 0.0)
		points.append(base + normal * zig)
	draw_polyline(points, Color(1.0, 0.84, 0.05, 0.95), 8.0, true)
	draw_polyline(points, Color(1.0, 1.0, 0.88, 1.0), 2.5, true)
	draw_circle(end_pos, 12.0, Color(1.0, 0.94, 0.3, 0.9))


func _draw_grass_travel(progress: float) -> void:
	var position: Vector2 = _travel_position(progress)
	var direction: Vector2 = _travel_direction()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	for index: int in range(7):
		var back: float = float(index) * 17.0
		var center: Vector2 = position - direction * back + normal * sin(progress * 15.0 + float(index) * 1.4) * 13.0
		var leaf_dir: Vector2 = direction.rotated(float(index - 3) * 0.13)
		var leaf_normal: Vector2 = Vector2(-leaf_dir.y, leaf_dir.x)
		var leaf: PackedVector2Array = PackedVector2Array([center + leaf_dir * 14.0, center + leaf_normal * 7.0, center - leaf_dir * 11.0, center - leaf_normal * 7.0])
		draw_colored_polygon(leaf, Color(0.18, 0.76, 0.3, 0.88))


func _draw_psychic_travel(progress: float) -> void:
	var position: Vector2 = _travel_position(progress)
	var color: Color = _type_color(&"psychic")
	draw_circle(position, 18.0, Color(color.r, color.g, color.b, 0.42))
	for ring: int in range(3):
		var radius: float = 14.0 + float(ring) * 9.0
		draw_arc(position, radius, progress * 8.0 + float(ring), progress * 8.0 + float(ring) + PI * 1.35, 24, Color(color.r, color.g, color.b, 0.9 - float(ring) * 0.2), 3.0, true)
	draw_circle(position, 5.5, Color(1.0, 0.88, 1.0, 1.0))


func _draw_fighting_travel(progress: float) -> void:
	var position: Vector2 = _travel_position(progress)
	var direction: Vector2 = _travel_direction()
	for lane: int in range(-2, 3):
		var normal: Vector2 = Vector2(-direction.y, direction.x)
		var start: Vector2 = position - direction * (95.0 + abs(lane) * 14.0) + normal * float(lane) * 12.0
		draw_line(start, position + direction * 12.0 + normal * float(lane) * 4.0, Color(1.0, 0.48, 0.08, 0.78 - abs(float(lane)) * 0.12), 4.0 + float(2 - abs(lane)), true)
	draw_circle(position, 14.0, Color(1.0, 0.74, 0.28, 0.9))


func _draw_dark_travel(progress: float) -> void:
	var position: Vector2 = _travel_position(progress)
	for ring: int in range(3):
		draw_arc(position, 14.0 + float(ring) * 8.0, -progress * 12.0 + float(ring), -progress * 12.0 + float(ring) + PI * 1.5, 26, Color(0.45, 0.12, 0.68, 0.82 - float(ring) * 0.18), 4.0, true)
	draw_circle(position, 13.0, Color(0.025, 0.02, 0.05, 0.94))
	draw_circle(position - Vector2(4.0, 4.0), 4.0, Color(0.72, 0.25, 0.95, 0.9))


func _draw_steel_travel(progress: float) -> void:
	var position: Vector2 = _travel_position(progress)
	var direction: Vector2 = _travel_direction()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	var shard: PackedVector2Array = PackedVector2Array([position + direction * 24.0, position + normal * 10.0, position - direction * 18.0, position - normal * 10.0])
	draw_colored_polygon(shard, Color(0.72, 0.78, 0.9, 0.95))
	draw_line(position - direction * 15.0, position + direction * 17.0, Color(1.0, 1.0, 1.0, 0.9), 2.0, true)
	for index: int in range(4):
		draw_line(position - direction * (30.0 + float(index) * 15.0) + normal * float(index - 2) * 5.0, position - direction * (10.0 + float(index) * 12.0), Color(0.75, 0.85, 1.0, 0.55), 2.0, true)


func _draw_flying_travel(progress: float) -> void:
	var position: Vector2 = _travel_position(progress)
	var direction: Vector2 = _travel_direction()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	for index: int in range(5):
		var offset: float = float(index - 2) * 11.0
		var start: Vector2 = position - direction * (92.0 + float(index) * 7.0) + normal * offset
		var end: Vector2 = position + direction * 12.0 + normal * offset * 0.4
		draw_line(start, end, Color(0.58, 0.93, 1.0, 0.72 - abs(float(index - 2)) * 0.09), 3.0, true)
	draw_arc(position, 19.0, progress * 9.0, progress * 9.0 + PI * 1.35, 22, Color(0.75, 0.98, 1.0, 0.9), 3.0, true)


func _draw_fire_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var burst: float = sin(progress * PI)
	var hot: float = max(0.0, 1.0 - progress * 1.35)

	# Layered blast rings create a much stronger first-frame impact.
	for ring: int in range(3):
		var radius: float = 20.0 + progress * (62.0 + float(ring) * 26.0)
		draw_arc(_target, radius, 0.0, TAU, 56, Color(1.0, 0.12 + float(ring) * 0.16, 0.02, (0.9 - float(ring) * 0.2) * fade), 7.0 - float(ring) * 1.5, true)

	# White-hot core -> orange body -> red outer fireball.
	draw_circle(_target, 40.0 * burst + 10.0, Color(1.0, 0.12, 0.01, 0.52 * fade))
	draw_circle(_target, 28.0 * burst + 8.0, Color(1.0, 0.48, 0.02, 0.76 * fade))
	draw_circle(_target, 14.0 * burst + 5.0, Color(1.0, 0.96, 0.6, 0.95 * hot))

	# Radial flame spikes make Fire unmistakable even at a glance.
	for index: int in range(14):
		var angle: float = float(index) * TAU / 14.0 + 0.12 * sin(progress * 18.0 + float(index))
		var radial: Vector2 = Vector2(cos(angle), sin(angle))
		var tangent: Vector2 = Vector2(-radial.y, radial.x)
		var inner: Vector2 = _target + radial * (18.0 + burst * 8.0)
		var outer: Vector2 = _target + radial * (50.0 + progress * (48.0 + float(index % 4) * 8.0))
		var spike: PackedVector2Array = PackedVector2Array([inner + tangent * 7.0, outer, inner - tangent * 7.0])
		draw_colored_polygon(spike, Color(1.0, 0.24 if index % 2 == 0 else 0.6, 0.02, 0.72 * fade))

	# Tall flame tongues rise after the explosive hit.
	for index: int in range(11):
		var lane: float = float(index) - 5.0
		var x_offset: float = lane * 11.0
		var sway: float = sin(progress * 12.0 + float(index) * 1.37) * 11.0
		var height: float = (38.0 + float(index % 4) * 13.0) * (0.45 + burst * 1.35)
		var width: float = 10.0 + float(index % 3) * 3.0
		var base: Vector2 = _target + Vector2(x_offset, 26.0 - progress * 16.0)
		var tip: Vector2 = base + Vector2(sway, -height)
		var flame_shape: PackedVector2Array = PackedVector2Array([base + Vector2(-width, 0.0), base + Vector2(width, 0.0), tip])
		draw_colored_polygon(flame_shape, Color(1.0, 0.18 + 0.38 * float(index % 2), 0.02, 0.8 * fade))

	for index: int in range(20):
		var angle: float = float(index) * TAU / 20.0 + float(index % 3) * 0.12
		var distance: float = 28.0 + progress * (52.0 + float(index % 5) * 11.0)
		var ember_pos: Vector2 = _target + Vector2(cos(angle), sin(angle)) * distance
		ember_pos.y -= progress * (22.0 + float(index % 4) * 5.0)
		draw_circle(ember_pos, 2.5 + float(index % 3), Color(1.0, 0.72, 0.08, 0.92 * fade))


func _draw_water_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var color: Color = _type_color(&"water")
	# Deep blue core and three expanding wave fronts.
	draw_circle(_target, (32.0 + 18.0 * sin(progress * PI)) * fade, Color(0.12, 0.55, 1.0, 0.5 * fade))
	for ring: int in range(4):
		draw_arc(_target, 22.0 + progress * (42.0 + float(ring) * 20.0), 0.0, TAU, 52, Color(color.r, color.g, color.b, (0.85 - float(ring) * 0.16) * fade), 5.0 - float(ring) * 0.6, true)
	# Large crown-shaped splash.
	for index: int in range(12):
		var angle: float = -PI * 0.92 + float(index) * PI * 1.84 / 11.0
		var radial: Vector2 = Vector2(cos(angle), sin(angle))
		var distance: float = 24.0 + progress * (58.0 + float(index % 4) * 8.0)
		var drop: Vector2 = _target + radial * distance
		draw_line(_target + radial * 18.0, drop, Color(0.35, 0.82, 1.0, 0.62 * fade), 4.0, true)
		draw_circle(drop, 5.0 + float(index % 3), Color(0.65, 0.93, 1.0, 0.9 * fade))


func _draw_electric_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var color: Color = _type_color(&"electric")
	var flash: float = max(0.0, 1.0 - progress * 2.8)
	draw_circle(_target, 34.0 + flash * 30.0, Color(1.0, 1.0, 0.78, 0.7 * flash))
	# Main vertical thunderbolt gives Electric a unique silhouette.
	var main_points: PackedVector2Array = PackedVector2Array([
		_target + Vector2(-10.0, -105.0),
		_target + Vector2(13.0, -48.0),
		_target + Vector2(-4.0, -48.0),
		_target + Vector2(17.0, 8.0),
		_target + Vector2(1.0, 8.0),
		_target + Vector2(12.0, 92.0)
	])
	draw_polyline(main_points, Color(color.r, color.g, color.b, 0.95 * fade), 13.0, true)
	draw_polyline(main_points, Color(1.0, 1.0, 0.92, 0.95 * fade), 4.0, true)
	for branch: int in range(10):
		var angle: float = float(branch) * TAU / 10.0
		var points: PackedVector2Array = PackedVector2Array([_target])
		for segment: int in range(1, 5):
			var distance: float = float(segment) * (16.0 + progress * 10.0)
			var jitter: float = sin(float(segment * 7 + branch) + progress * 20.0) * 9.0
			var perpendicular: Vector2 = Vector2(-sin(angle), cos(angle))
			points.append(_target + Vector2(cos(angle), sin(angle)) * distance + perpendicular * jitter)
		draw_polyline(points, Color(color.r, color.g, color.b, 0.88 * fade), 5.0, true)
		draw_polyline(points, Color(1.0, 1.0, 1.0, 0.72 * fade), 1.6, true)


func _draw_grass_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var color: Color = _type_color(&"grass")
	# Expanding vine rings plus outward leaf blades.
	for ring: int in range(2):
		draw_arc(_target, 24.0 + progress * (40.0 + float(ring) * 25.0), progress * (4.0 if ring == 0 else -4.0), progress * (4.0 if ring == 0 else -4.0) + TAU * 0.88, 42, Color(0.2, 0.7 + float(ring) * 0.1, 0.25, (0.8 - float(ring) * 0.18) * fade), 6.0, true)
	for index: int in range(14):
		var angle: float = float(index) * TAU / 14.0 + progress * 2.0
		var distance: float = 18.0 + progress * (62.0 + float(index % 4) * 9.0)
		var center: Vector2 = _target + Vector2(cos(angle), sin(angle)) * distance
		var tangent: Vector2 = Vector2(-sin(angle), cos(angle))
		var radial: Vector2 = Vector2(cos(angle), sin(angle))
		var leaf: PackedVector2Array = PackedVector2Array([center + tangent * 9.0, center + radial * 17.0, center - tangent * 9.0, center - radial * 7.0])
		draw_colored_polygon(leaf, Color(color.r, color.g, color.b, 0.9 * fade))
		draw_line(center - radial * 5.0, center + radial * 12.0, Color(0.75, 1.0, 0.72, 0.65 * fade), 1.5, true)


func _draw_psychic_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var color: Color = _type_color(&"psychic")
	draw_circle(_target, 34.0 + 22.0 * sin(progress * PI), Color(color.r, color.g, color.b, 0.35 * fade))
	for ring: int in range(6):
		var radius: float = 16.0 + progress * (30.0 + float(ring) * 13.0)
		var start_angle: float = progress * (5.0 if ring % 2 == 0 else -5.0) + float(ring) * 0.5
		draw_arc(_target, radius, start_angle, start_angle + PI * 1.55, 36, Color(color.r, color.g, color.b, (0.9 - float(ring) * 0.11) * fade), 4.0, true)
	for index: int in range(8):
		var angle: float = float(index) * TAU / 8.0 - progress * 3.0
		var pos: Vector2 = _target + Vector2(cos(angle), sin(angle)) * (28.0 + progress * 72.0)
		draw_circle(pos, 5.0 + float(index % 2) * 2.0, Color(0.95, 0.55, 1.0, 0.8 * fade))


func _draw_fighting_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var color: Color = _type_color(&"fighting")
	# Cross-shaped heavy hit plus radial speed lines.
	for diagonal: int in range(2):
		var angle: float = PI * 0.25 + float(diagonal) * PI * 0.5
		var axis: Vector2 = Vector2(cos(angle), sin(angle))
		draw_line(_target - axis * (38.0 + progress * 35.0), _target + axis * (38.0 + progress * 35.0), Color(1.0, 0.84, 0.48, 0.9 * fade), 10.0, true)
	for index: int in range(12):
		var angle: float = float(index) * TAU / 12.0
		var radial: Vector2 = Vector2(cos(angle), sin(angle))
		draw_line(_target + radial * 18.0, _target + radial * (50.0 + progress * 62.0), Color(color.r, color.g, color.b, 0.82 * fade), 5.0, true)
	draw_arc(_target, 24.0 + progress * 68.0, 0.0, TAU, 48, Color(1.0, 0.75, 0.25, 0.72 * fade), 7.0, true)


func _draw_dark_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var color: Color = _type_color(&"dark")
	# Eclipse-like black core surrounded by rotating purple crescents.
	draw_circle(_target, 34.0 + 18.0 * sin(progress * PI), Color(0.015, 0.01, 0.03, 0.88 * fade))
	draw_arc(_target, 43.0 + progress * 15.0, 0.0, TAU, 46, Color(0.65, 0.2, 0.9, 0.7 * fade), 6.0, true)
	for index: int in range(7):
		var radius: float = 22.0 + float(index) * 10.0 + progress * 32.0
		var angle: float = -progress * 5.0 + float(index) * 0.85
		draw_arc(_target, radius, angle, angle + PI * 0.82, 30, Color(color.r, color.g, color.b, (0.82 - float(index) * 0.08) * fade), 5.0, true)


func _draw_steel_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var color: Color = _type_color(&"steel")
	# Metallic cross-flash.
	for axis_index: int in range(2):
		var axis: Vector2 = Vector2.RIGHT.rotated(float(axis_index) * PI * 0.5)
		draw_line(_target - axis * (22.0 + progress * 62.0), _target + axis * (22.0 + progress * 62.0), Color(1.0, 1.0, 1.0, 0.8 * fade), 5.0, true)
	for index: int in range(12):
		var angle: float = float(index) * TAU / 12.0
		var radial: Vector2 = Vector2(cos(angle), sin(angle))
		var tangent: Vector2 = Vector2(-radial.y, radial.x)
		var distance: float = 18.0 + progress * (62.0 + float(index % 3) * 10.0)
		var center: Vector2 = _target + radial * distance
		var shard: PackedVector2Array = PackedVector2Array([center + radial * 16.0, center + tangent * 6.0, center - radial * 10.0, center - tangent * 6.0])
		draw_colored_polygon(shard, Color(color.r, color.g, color.b, 0.9 * fade))
	draw_arc(_target, 25.0 + progress * 55.0, 0.0, TAU, 48, Color(0.82, 0.9, 1.0, 0.65 * fade), 5.0, true)


func _draw_flying_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var color: Color = _type_color(&"flying")
	# Curved cyclone arcs distinguish Flying from straight projectiles.
	for ring: int in range(5):
		var radius: float = 22.0 + float(ring) * 13.0 + progress * 28.0
		var start_angle: float = progress * 5.0 + float(ring) * 0.45
		draw_arc(_target, radius, start_angle, start_angle + PI * 1.15, 34, Color(color.r, color.g, color.b, (0.85 - float(ring) * 0.12) * fade), 4.0, true)
	for index: int in range(8):
		var y_offset: float = (float(index) - 3.5) * 11.0
		var start: Vector2 = _target + Vector2(-65.0 - progress * 22.0, y_offset)
		var finish: Vector2 = _target + Vector2(68.0 + progress * 42.0, y_offset - 12.0)
		draw_line(start, finish, Color(0.75, 0.97, 1.0, (0.72 - abs(float(index) - 3.5) * 0.07) * fade), 3.0, true)


func _draw_normal_impact(progress: float) -> void:
	var fade: float = 1.0 - progress
	var color: Color = _type_color(&"normal")
	draw_arc(
		_target,
		18.0 + progress * 60.0,
		0.0,
		TAU,
		48,
		Color(color.r, color.g, color.b, 0.75 * fade),
		5.0,
		true
	)
	for index: int in range(8):
		var angle: float = float(index) * TAU / 8.0
		draw_line(
			_target + Vector2(cos(angle), sin(angle)) * 12.0,
			_target + Vector2(cos(angle), sin(angle)) * (30.0 + progress * 45.0),
			Color(1.0, 1.0, 1.0, 0.75 * fade),
			3.0,
			true
		)


func _draw_screen_accent(progress: float) -> void:
	# A short full-screen color flash gives heavy attacks more punch without
	# moving the battle layout or touching gameplay state.
	var flash: float = max(0.0, 1.0 - progress * 5.0)
	if flash <= 0.0:
		return
	var color: Color = _type_color(_attack_type)
	draw_rect(Rect2(Vector2.ZERO, size), Color(color.r, color.g, color.b, 0.13 * flash), true)
	# White impact frame at the target itself improves readability over busy art.
	draw_circle(_target, 52.0 * (1.0 - progress * 0.3), Color(1.0, 1.0, 1.0, 0.18 * flash))


func _anchor_center_in_local_space(anchor: Control) -> Vector2:
	if anchor == null or not is_instance_valid(anchor):
		return size * 0.5

	var global_center: Vector2 = anchor.get_global_rect().get_center()
	return get_global_transform_with_canvas().affine_inverse() * global_center


func _type_color(attack_type: StringName) -> Color:
	match attack_type:
		&"grass":
			return Color("52b96f")
		&"fire":
			return Color("e75b4f")
		&"water":
			return Color("4c9fd8")
		&"electric":
			return Color("f2c84a")
		&"psychic":
			return Color("d767ad")
		&"fighting":
			return Color("df8742")
		&"dark":
			return Color("69358f")
		&"steel":
			return Color("8995aa")
		&"flying":
			return Color("62b9cf")
		_:
			return Color("a8a8a8")
