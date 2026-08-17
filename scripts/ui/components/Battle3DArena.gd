extends SubViewportContainer


signal move_card_selected(move_card_id: StringName)


const ICONS: Script = preload(
	"res://scripts/presentation/PlakoroIconService.gd"
)
const STL_IMPORTER: Script = preload(
	"res://scripts/model_weight/importers/STLRuntimeImporter.gd"
)

const PLAYER_COLOR := Color("38bdf8")
const ENEMY_COLOR := Color("fb7185")
const MAT_COLOR := Color("173f2b")
const STL_BY_POKEMON: Dictionary = {
	"bulbasaur_standard": "Bulbasaur_standard.stl",
	"charmander_standard": "Charmander_standard.stl",
	"eevee_standard": "Eevee_standard.stl",
	"grimer_eb01_a1": "Grimer_eb01_a1.stl",
	"grimer_eb01_b1": "Grimer_eb01_b1.stl",
	"mew_standard": "Mew_standard.stl",
	"pikachu_standard": "Pikachu_standard.stl",
	"squirtle_standard": "Squirtle_standard.stl",
}
const TYPE_COLORS: Dictionary = {
	"grass": Color("72b93e"), "fire": Color("e84b42"),
	"water": Color("3b9de2"), "electric": Color("f6c928"),
	"psychic": Color("d957a2"), "fighting": Color("dd7735"),
	"dark": Color("375762"), "steel": Color("8d96ad"),
	"flying": Color("75c7de"),
}
# Same axis conversion used by ModelWeightGeneratorPanel:
# preview +Y (head) -> canonical +Z, preview +Z (face) -> canonical +Y,
# preview +X -> canonical -X.
const PREVIEW_TO_CANONICAL := Basis(
	Vector3(-1.0, 0.0, 0.0),
	Vector3(0.0, 0.0, 1.0),
	Vector3(0.0, 1.0, 0.0)
)

static var _mesh_cache: Dictionary = {}

@onready var arena_viewport: SubViewport = %ArenaViewport
@onready var arena_camera: Camera3D = %Camera3D
@onready var move_hit_targets: Control = %MoveHitTargets

var player_pokemon_data: Variant = null
var enemy_pokemon_data: Variant = null
var dice_meshes: Array[MeshInstance3D] = []
var energy_icon_roots: Array[Node3D] = []
var charakoro_die: MeshInstance3D = null
var charakoro_result_label: Label3D = null
var move_hit_buttons: Array[Button] = []
var move_card_materials: Array[StandardMaterial3D] = []
var player_profile_label: Label3D = null
var enemy_profile_label: Label3D = null
var elapsed: float = 0.0
var dice_rolling: bool = false


func _ready() -> void:
	_build_world()


func setup_battle(
	player_pokemon: Variant,
	enemy_pokemon: Variant,
	player_moves: Array = [],
	enemy_moves: Array = []
) -> void:
	if not is_node_ready():
		await ready
	player_pokemon_data = player_pokemon
	enemy_pokemon_data = enemy_pokemon
	_set_charakoro_pokemon(player_pokemon_data)
	_build_table_cards(player_pokemon, enemy_pokemon, player_moves, enemy_moves)


func update_health(player_ratio: float, enemy_ratio: float) -> void:
	_update_profile_label(player_profile_label, player_pokemon_data, player_ratio)
	_update_profile_label(enemy_profile_label, enemy_pokemon_data, enemy_ratio)


func play_roll(
	dice_result: Variant,
	energy_profiles: Array,
	roll_record: Variant,
	is_enemy: bool = false,
	resolved_energy_dice: Array[Array] = []
) -> void:
	if dice_result == null:
		return
	dice_rolling = true
	_set_charakoro_pokemon(enemy_pokemon_data if is_enemy else player_pokemon_data)
	charakoro_result_label.text = "ROLLING"
	for icon_root: Node3D in energy_icon_roots:
		icon_root.visible = false
	var duration: float = 1.15
	var passed: float = 0.0
	while passed < duration:
		var delta: float = get_process_delta_time()
		passed += maxf(delta, 0.016)
		for index: int in range(dice_meshes.size()):
			var die: MeshInstance3D = dice_meshes[index]
			die.rotation += Vector3(8.0, 11.0, 7.0) * maxf(delta, 0.016)
			die.position.y = 0.46 + abs(sin(passed * 9.0 + index)) * 0.8
		if charakoro_die != null:
			charakoro_die.rotation += Vector3(9.0, 7.0, 11.0) * maxf(delta, 0.016)
			charakoro_die.position.y = 0.52 + abs(sin(passed * 8.2 + 2.4)) * 0.95
		await get_tree().process_frame
	var outcomes: Array[Array] = resolved_energy_dice.duplicate(true)
	if outcomes.is_empty():
		outcomes = _resolve_energy_dice(energy_profiles, roll_record)
	if outcomes.is_empty():
		outcomes = _fallback_energy_dice(dice_result)
	for index: int in range(3):
		var energies: Array = outcomes[index] if index < outcomes.size() else []
		_set_die_result(index, energies)
	_set_charakoro_result(_extract_orientation(dice_result))
	for index: int in range(dice_meshes.size()):
		dice_meshes[index].position.y = 0.46
		dice_meshes[index].rotation = Vector3(0.0, 0.15 * index, 0.0)
	if charakoro_die != null:
		charakoro_die.position.y = 0.52
	%DiceGroup.position.z = -0.35 if is_enemy else 0.35
	dice_rolling = false


func _process(delta: float) -> void:
	elapsed += delta
	if not dice_rolling:
		%DiceGroup.rotation.y = sin(elapsed * 0.45) * 0.035
	_refresh_move_hit_targets()


func _build_world() -> void:
	_build_environment()
	_build_lighting()
	_build_playmat()
	_build_dice()


func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("06120d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("cbe3d1")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	%WorldEnvironment.environment = environment


func _build_lighting() -> void:
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-62.0, -24.0, 0.0)
	key_light.light_color = Color("e4f7e8")
	key_light.light_energy = 1.35
	key_light.shadow_enabled = true
	%ArenaRoot.add_child(key_light)
	_add_omni_light(Vector3(-4.2, 5.0, 2.8), PLAYER_COLOR, 4.2, 8.0)
	_add_omni_light(Vector3(4.2, 5.0, -2.8), ENEMY_COLOR, 4.2, 8.0)


func _add_omni_light(position_value: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position_value
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	%ArenaRoot.add_child(light)


func _build_playmat() -> void:
	var mat_mesh := PlaneMesh.new()
	mat_mesh.size = Vector2(18.0, 11.0)
	var mat_material := StandardMaterial3D.new()
	mat_material.albedo_color = MAT_COLOR
	mat_material.roughness = 0.86
	mat_mesh.material = mat_material
	_add_mesh(mat_mesh, Vector3.ZERO)
	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(18.5, 0.025, 0.20)
	var lane_material := StandardMaterial3D.new()
	lane_material.albedo_color = Color(0.72, 0.88, 0.63, 0.32)
	lane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lane_material.emission_enabled = true
	lane_material.emission = Color("86b875")
	lane_material.emission_energy_multiplier = 0.45
	lane_mesh.material = lane_material
	var lane := _add_mesh(lane_mesh, Vector3(0.0, 0.025, 0.0))
	lane.rotation.y = deg_to_rad(-18.0)
	for ring_index: int in range(3):
		var disc_mesh := CylinderMesh.new()
		disc_mesh.top_radius = 1.0 + float(ring_index) * 0.58
		disc_mesh.bottom_radius = disc_mesh.top_radius
		disc_mesh.height = 0.018
		var disc_material := StandardMaterial3D.new()
		disc_material.albedo_color = Color(0.70, 0.86, 0.62, 0.08)
		disc_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		disc_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		disc_mesh.material = disc_material
		_add_mesh(disc_mesh, Vector3(0.0, 0.04 + ring_index * 0.006, 0.0))


func _build_dice() -> void:
	for index: int in range(3):
		var die_mesh := BoxMesh.new()
		die_mesh.size = Vector3(0.68, 0.68, 0.68)
		var die_material := StandardMaterial3D.new()
		die_material.albedo_color = Color("eef3f0")
		die_material.metallic = 0.12
		die_material.roughness = 0.30
		die_mesh.material = die_material
		var die := MeshInstance3D.new()
		die.mesh = die_mesh
		die.position = Vector3(float(index) * 0.88 - 1.32, 0.46, 0.0)
		%DiceGroup.add_child(die)
		dice_meshes.append(die)
		var icon_root := Node3D.new()
		die.add_child(icon_root)
		energy_icon_roots.append(icon_root)
		_set_energy_icons(index, [&"normal"])

	charakoro_die = MeshInstance3D.new()
	charakoro_die.position = Vector3(1.38, 0.52, 0.0)
	%DiceGroup.add_child(charakoro_die)
	charakoro_result_label = _make_table_label("CHARAKORO", Color("f7d9e0"), 24)
	charakoro_result_label.position = Vector3(1.38, 0.08, 0.62)
	charakoro_result_label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	%DiceGroup.add_child(charakoro_result_label)


func _load_pokemon_mesh(pokemon: Variant) -> ArrayMesh:
	if pokemon == null:
		return null
	var pokemon_id: String = String(pokemon.id).to_lower()
	var filename: String = String(STL_BY_POKEMON.get(pokemon_id, ""))
	if filename.is_empty():
		return null
	if _mesh_cache.has(filename):
		return _mesh_cache[filename]
	var source: ArrayMesh = STL_IMPORTER.new().load_mesh(
		"res://assets/pokemon/models/" + filename
	)
	var normalized: ArrayMesh = _center_and_scale_mesh(source, 1.0)
	if normalized != null:
		_mesh_cache[filename] = normalized
	return normalized


func _center_and_scale_mesh(mesh: ArrayMesh, target_size: float) -> ArrayMesh:
	if mesh == null:
		return null
	var aabb: AABB = mesh.get_aabb()
	var max_dimension: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_dimension <= 0.0:
		return null
	var factor: float = target_size / max_dimension
	var center: Vector3 = aabb.position + aabb.size * 0.5
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for surface_index: int in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_index)
		var vertices := PackedVector3Array(arrays[Mesh.ARRAY_VERTEX])
		for vertex: Vector3 in vertices:
			var normalized: Vector3 = (vertex - center) * factor
			surface.add_vertex(PREVIEW_TO_CANONICAL * normalized)
	surface.generate_normals()
	return surface.commit()


func _build_table_cards(
	player_pokemon: Variant,
	enemy_pokemon: Variant,
	player_moves: Array,
	enemy_moves: Array
) -> void:
	for child: Node in %CardGroup.get_children():
		child.queue_free()
	for child: Node in move_hit_targets.get_children():
		child.queue_free()
	move_hit_buttons.clear()
	move_card_materials.clear()
	# Keep both public profile cards inside the central tabletop viewport. The
	# surrounding HUD remains readable while the cards still feel physically
	# placed beside their respective combatant.
	_add_profile_card(player_pokemon, Vector3(-2.35, 0.09, 3.15), PLAYER_COLOR, false)
	_add_profile_card(enemy_pokemon, Vector3(2.35, 0.09, -3.15), ENEMY_COLOR, true)
	for index: int in range(4):
		var move: Variant = player_moves[index] if index < player_moves.size() else null
		var move_name: String = String(move.display_name) if move != null else "MOVE"
		var card_position := Vector3(-2.55 + index * 1.7, 0.08, 4.35)
		var card_result: Dictionary = _add_table_card(
			move_name, card_position, PLAYER_COLOR, false
		)
		move_card_materials.append(
			card_result["material"]
		)
		if move != null:
			_add_move_hit_target(StringName(move.id), move_name, card_position)
		_add_table_card("PLAKORO", Vector3(2.55 - index * 1.7, 0.08, -4.35), ENEMY_COLOR, true)


func _add_profile_card(pokemon: Variant, card_position: Vector3, color: Color, enemy_side: bool) -> void:
	var name_text: String = String(pokemon.display_name) if pokemon != null else "PLAKORO"
	var type_text: String = String(pokemon.pokemon_type).to_upper() if pokemon != null else ""
	var result: Dictionary = _add_table_card(
		name_text + "\n" + type_text + " • HP " + str(pokemon.max_hp),
		card_position,
		color,
		enemy_side,
		Vector3(2.25, 0.07, 1.35)
	)
	if enemy_side:
		enemy_profile_label = result["label"]
	else:
		player_profile_label = result["label"]


func _add_table_card(
	text_value: String,
	card_position: Vector3,
	color: Color,
	enemy_side: bool,
	card_size: Vector3 = Vector3(1.45, 0.055, 0.92)
) -> Dictionary:
	var card_root := Node3D.new()
	card_root.position = card_position
	card_root.rotation.y = PI if enemy_side else 0.0
	%CardGroup.add_child(card_root)
	var card_mesh := BoxMesh.new()
	card_mesh.size = card_size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("121b22")
	material.metallic = 0.12
	material.roughness = 0.68
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.10
	card_mesh.material = material
	var card := MeshInstance3D.new()
	card.mesh = card_mesh
	card_root.add_child(card)
	var label := _make_table_label(text_value, color.lightened(0.28), 30)
	label.position.y = card_size.y * 0.5 + 0.008
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	label.width = 160.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_root.add_child(label)
	return {"material": material, "label": label}


func _update_profile_label(label: Label3D, pokemon: Variant, health_ratio: float) -> void:
	if label == null or pokemon == null:
		return
	var max_hp: int = int(pokemon.max_hp)
	var current_hp: int = roundi(clampf(health_ratio, 0.0, 1.0) * max_hp)
	label.text = (
		String(pokemon.display_name)
		+ "\n"
		+ String(pokemon.pokemon_type).to_upper()
		+ " • HP "
		+ str(current_hp)
		+ "/"
		+ str(max_hp)
	)


func _add_move_hit_target(move_id: StringName, move_name: String, world_position: Vector3) -> void:
	var button := Button.new()
	button.flat = true
	button.text = ""
	button.tooltip_text = move_name
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("world_position", world_position)
	button.pressed.connect(_emit_move_card_selected.bind(move_id))
	move_hit_targets.add_child(button)
	move_hit_buttons.append(button)


func _emit_move_card_selected(move_id: StringName) -> void:
	move_card_selected.emit(move_id)


func _refresh_move_hit_targets() -> void:
	if arena_camera == null or move_hit_targets == null or arena_viewport.size.x <= 0:
		return
	var viewport_scale: Vector2 = size / Vector2(arena_viewport.size)
	for button: Button in move_hit_buttons:
		var world_position: Vector3 = button.get_meta("world_position", Vector3.ZERO)
		var projected: Vector2 = arena_camera.unproject_position(world_position)
		button.size = Vector2(180.0, 105.0) * viewport_scale
		button.position = projected * viewport_scale - button.size * 0.5


func set_move_card_enabled(index: int, enabled: bool) -> void:
	if index >= 0 and index < move_hit_buttons.size():
		move_hit_buttons[index].disabled = not enabled
	if index >= 0 and index < move_card_materials.size():
		var material: StandardMaterial3D = move_card_materials[index]
		material.albedo_color = Color("121b22") if enabled else Color("202328")
		material.emission_energy_multiplier = 0.10 if enabled else 0.0


func _make_table_label(text_value: String, color: Color, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.modulate = color
	label.font_size = font_size
	label.pixel_size = 0.006
	label.outline_size = 4
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.no_depth_test = false
	return label


func _resolve_energy_dice(energy_profiles: Array, roll_record: Variant) -> Array[Array]:
	var result: Array[Array] = []
	if roll_record == null or energy_profiles.is_empty():
		return result
	var face_ids: Variant = roll_record.get("energy_die_face_ids") if roll_record is Dictionary else roll_record.energy_die_face_ids
	if not face_ids is Array:
		return result
	for index: int in range((face_ids as Array).size()):
		var profile: Variant = energy_profiles[index % energy_profiles.size()]
		var face: Dictionary = profile.get_face_result(StringName(face_ids[index]))
		var raw: Variant = face.get("energies", [])
		if not raw is Array or (raw as Array).is_empty():
			return []
		result.append((raw as Array).duplicate())
	return result


func _fallback_energy_dice(dice_result: Variant) -> Array[Array]:
	var result: Array[Array] = [[], [], []]
	var counts: Dictionary = dice_result.energy_counts
	var cursor: int = 0
	for energy: StringName in TYPE_COLORS.keys():
		for count_index: int in range(int(counts.get(energy, counts.get(String(energy), 0)))):
			result[min(cursor, 2)].append(energy)
			cursor += 1
	return result


func _set_die_result(index: int, energies: Array) -> void:
	_set_energy_icons(index, energies)


func _set_energy_icons(index: int, energies: Array) -> void:
	if index < 0 or index >= energy_icon_roots.size():
		return
	var root: Node3D = energy_icon_roots[index]
	for child: Node in root.get_children():
		child.queue_free()
	root.visible = true
	var resolved: Array = energies if not energies.is_empty() else [&"normal"]
	var icon_count: int = mini(resolved.size(), 2)
	for icon_index: int in range(icon_count):
		var energy_type := StringName(resolved[icon_index])
		var sprite := Sprite3D.new()
		sprite.texture = ICONS.load_energy_icon(energy_type)
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.shaded = false
		sprite.pixel_size = 0.0042 if icon_count == 1 else 0.0031
		sprite.position = Vector3(
			(float(icon_index) - float(icon_count - 1) * 0.5) * 0.25,
			0.346,
			0.0
		)
		sprite.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		root.add_child(sprite)


func _set_charakoro_pokemon(pokemon: Variant) -> void:
	if charakoro_die == null:
		return
	var mesh: Mesh = _load_pokemon_mesh(pokemon)
	if mesh == null:
		var fallback := BoxMesh.new()
		fallback.size = Vector3(0.75, 0.75, 0.75)
		mesh = fallback
	charakoro_die.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = _pokemon_color(pokemon) if pokemon != null else Color("cbd5d1")
	material.roughness = 0.72
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	charakoro_die.material_override = material
	charakoro_die.rotation = Vector3.ZERO


func _set_charakoro_result(orientation: StringName) -> void:
	if charakoro_die == null:
		return
	charakoro_result_label.text = (
		String(orientation).replace("_", " ") if orientation != &"" else "DISABLED"
	)
	match orientation:
		&"FACE_UP":
			# canonical +Y points toward world +Y
			charakoro_die.rotation = Vector3.ZERO
		&"FACE_DOWN":
			# canonical -Y points toward world +Y
			charakoro_die.rotation = Vector3(PI, 0.0, 0.0)
		&"HEAD_UP":
			# canonical +Z points toward world +Y
			charakoro_die.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
		&"HEAD_DOWN":
			# canonical -Z points toward world +Y
			charakoro_die.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		&"HEAD_LEFT":
			# canonical +X points toward world +Y
			charakoro_die.rotation = Vector3(0.0, 0.0, PI * 0.5)
		&"HEAD_RIGHT":
			# canonical -X points toward world +Y
			charakoro_die.rotation = Vector3(0.0, 0.0, -PI * 0.5)
		_:
			charakoro_die.rotation = Vector3.ZERO


func _extract_orientation(dice_result: Variant) -> StringName:
	for property_name: StringName in [&"kyokoro_orientation", &"orientation", &"orientation_id"]:
		var value: Variant = dice_result.get(String(property_name)) if dice_result is Dictionary else dice_result.get(property_name)
		if value != null and not String(value).is_empty():
			return StringName(value)
	return &""


func _pokemon_color(pokemon: Variant) -> Color:
	return TYPE_COLORS.get(String(pokemon.pokemon_type), Color("cbd5d1"))


func _add_mesh(mesh: Mesh, mesh_position: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = mesh_position
	%ArenaRoot.add_child(instance)
	return instance
