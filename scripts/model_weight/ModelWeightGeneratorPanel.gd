extends Control

const STLImporter = preload("res://scripts/model_weight/importers/STLRuntimeImporter.gd")
const OBJImporter = preload("res://scripts/model_weight/importers/OBJRuntimeImporter.gd")
const GLTFImporter = preload("res://scripts/model_weight/importers/GLTFRuntimeImporter.gd")

const ORIENTATIONS := [
	"FACE_DOWN",
	"FACE_UP",
	"HEAD_UP",
	"HEAD_DOWN",
	"HEAD_LEFT",
    "HEAD_RIGHT"
]

# Preview convention:
#   screen UP      = preview +Y
#   toward camera  = preview +Z
#
# Project canonical convention:
#   HEAD_UP    = canonical +Z
#   FACE_UP    = canonical +Y
#   HEAD_LEFT  = canonical +X
#
# Therefore:
#   preview +Y -> canonical +Z
#   preview +Z -> canonical +Y
#   preview +X -> canonical -X
const PREVIEW_TO_CANONICAL := Basis(
	Vector3(-1, 0, 0),
	Vector3(0, 0, 1),
	Vector3(0, 1, 0)
)

var file_dialog: FileDialog
var path_edit: LineEdit
var id_edit: LineEdit
var output_name_edit: LineEdit
var throws_spin: SpinBox
var size_spin: SpinBox
var mode_option: OptionButton
var mode_note: Label
var progress: ProgressBar
var status: Label
var result_box: RichTextLabel
var generate_button: Button
var confirm_orientation_button: Button
var orientation_state: Label
var import_state_label: Label
var model_info_label: RichTextLabel
var ready_state_label: Label
var preview_color_option: OptionButton
var preview_mode_option: OptionButton
var preview_material: StandardMaterial3D
var localized_controls: Array[Dictionary] = []

var imported_mesh: ArrayMesh
var imported_model_path: String = ""
var imported_mesh_info: Dictionary = {}
var confirmed_orientation := Basis.IDENTITY
var orientation_confirmed := false

var preview_container: SubViewportContainer
var preview_viewport: SubViewport
var preview_pivot: Node3D
var preview_mesh_instance: MeshInstance3D
var preview_camera: Camera3D
var dragging := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2.ZERO
	_build_ui()

	LocalizationService.locale_changed.connect(
		_on_locale_changed
	)
	_apply_localized_text()

func _build_ui() -> void:
	var page_margin: MarginContainer = MarginContainer.new()
	page_margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE,
		0
	)
	page_margin.add_theme_constant_override("margin_left", 12)
	page_margin.add_theme_constant_override("margin_right", 12)
	page_margin.add_theme_constant_override("margin_top", 4)
	page_margin.add_theme_constant_override("margin_bottom", 4)
	add_child(page_margin)

	var page: VBoxContainer = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 6)
	page_margin.add_child(page)

	# Compact utility header. Content Studio already provides the page title.
	var header: HBoxContainer = HBoxContainer.new()
	header.custom_minimum_size.y = 28
	page.add_child(header)

	var subtitle: Label = Label.new()
	_bind_text(subtitle, "model_weight.subtitle", "3D model -> orientation setup -> Godot/Jolt throws -> Charakoro weighted profile")
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.modulate = Color(0.82, 0.82, 0.82)
	header.add_child(subtitle)

	var formats: Label = Label.new()
	_bind_text(formats, "model_weight.supported", "Supported: STL  |  OBJ  |  GLB  |  GLTF")
	formats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	formats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	formats.custom_minimum_size.x = 240
	header.add_child(formats)

	# Main 2-column layout:
	# LEFT  = Orientation
	# RIGHT = Model/Profile + Simulation/Result
	var workspace: HSplitContainer = HSplitContainer.new()
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Keep Orientation and the right-side authoring tools close to 1:1.
	# A small left bias preserves enough room for the 3D controls.
	workspace.split_offset = 80
	page.add_child(workspace)

	# ================================================================
	# LEFT - Orientation Setup
	# ================================================================
	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_child(left_panel)

	var left_margin: MarginContainer = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 10)
	left_margin.add_theme_constant_override("margin_right", 10)
	left_margin.add_theme_constant_override("margin_top", 8)
	left_margin.add_theme_constant_override("margin_bottom", 8)
	left_panel.add_child(left_margin)

	var preview_panel: VBoxContainer = VBoxContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_panel.add_theme_constant_override("separation", 6)
	left_margin.add_child(preview_panel)

	var orient_title: Label = Label.new()
	_bind_text(orient_title, "model_weight.orientation", "1. Orientation Setup")
	orient_title.add_theme_font_size_override("font_size", 18)
	preview_panel.add_child(orient_title)

	var instruction: Label = Label.new()
	_bind_text(instruction, "model_weight.orientation_instruction", "Rotate until the HEAD points UP and the FACE looks directly toward you.")
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_panel.add_child(instruction)

	var direction_hint: Label = Label.new()
	_bind_text(direction_hint, "model_weight.direction_hint", "^ HEAD UP      |      FACE -> CAMERA / YOU")
	direction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	direction_hint.modulate = Color(0.84, 0.84, 0.84)
	preview_panel.add_child(direction_hint)

	preview_container = SubViewportContainer.new()
	preview_container.custom_minimum_size = Vector2(420, 300)
	preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_container.stretch = true
	preview_container.mouse_filter = Control.MOUSE_FILTER_STOP
	preview_container.gui_input.connect(_preview_gui_input)
	preview_panel.add_child(preview_container)

	preview_viewport = SubViewport.new()
	preview_viewport.size = Vector2i(760, 420)
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_viewport.transparent_bg = false
	preview_container.add_child(preview_viewport)

	var world_root: Node3D = Node3D.new()
	preview_viewport.add_child(world_root)

	preview_pivot = Node3D.new()
	preview_pivot.name = "PreviewPivot"
	world_root.add_child(preview_pivot)

	preview_camera = Camera3D.new()
	preview_camera.current = true
	preview_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	preview_camera.size = 2.6
	preview_camera.near = 0.01
	preview_camera.far = 100.0
	world_root.add_child(preview_camera)
	preview_camera.look_at_from_position(
		Vector3(0, 0, 3.2),
		Vector3.ZERO,
		Vector3.UP
	)

	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.shadow_enabled = true
	world_root.add_child(light)

	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(25, 150, 0)
	fill.light_energy = 0.55
	world_root.add_child(fill)

	var world_env: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.06, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.75, 0.80)
	env.ambient_light_energy = 0.62
	world_env.environment = env
	world_root.add_child(world_env)

	var appearance_row: HBoxContainer = HBoxContainer.new()
	appearance_row.add_theme_constant_override("separation", 6)
	preview_panel.add_child(appearance_row)

	var color_label: Label = _label("Color")
	_bind_text(color_label, "model_weight.color", "Color")
	appearance_row.add_child(color_label)
	preview_color_option = OptionButton.new()
	preview_color_option.add_item(LocalizationService.tr_key("model_weight.palette.neutral", "Neutral Gray"))
	preview_color_option.add_item(LocalizationService.tr_key("model_weight.palette.pikachu", "Pikachu Yellow"))
	preview_color_option.add_item(LocalizationService.tr_key("model_weight.palette.bulbasaur", "Bulbasaur Green"))
	preview_color_option.add_item(LocalizationService.tr_key("model_weight.palette.squirtle", "Squirtle Blue"))
	preview_color_option.add_item(LocalizationService.tr_key("model_weight.palette.charmander", "Charmander Orange"))
	preview_color_option.add_item(LocalizationService.tr_key("model_weight.palette.eevee", "Eevee Brown"))
	preview_color_option.add_item(LocalizationService.tr_key("model_weight.palette.mew", "Mew Pink"))
	preview_color_option.add_item(LocalizationService.tr_key("model_weight.palette.grimer", "Grimer Purple"))
	preview_color_option.add_item(LocalizationService.tr_key("model_weight.palette.red", "Red"))
	preview_color_option.select(0)
	preview_color_option.item_selected.connect(_on_preview_color_changed)
	appearance_row.add_child(preview_color_option)

	var view_label: Label = _label("View")
	_bind_text(view_label, "model_weight.view", "View")
	appearance_row.add_child(view_label)
	preview_mode_option = OptionButton.new()
	preview_mode_option.add_item(LocalizationService.tr_key("model_weight.view.double_sided", "Double-Sided Solid"))
	preview_mode_option.add_item(LocalizationService.tr_key("model_weight.view.original", "Original Culling"))
	preview_mode_option.select(0)
	preview_mode_option.item_selected.connect(_on_preview_mode_changed)
	appearance_row.add_child(preview_mode_option)

	var view_info: Label = Label.new()
	view_info.text = LocalizationService.tr_key("model_weight.view_info", "Orthographic  |  Opaque")
	view_info.modulate = Color(0.75, 0.75, 0.75)
	appearance_row.add_child(view_info)

	var rotate_row: HBoxContainer = HBoxContainer.new()
	rotate_row.add_theme_constant_override("separation", 5)
	preview_panel.add_child(rotate_row)

	var reset_btn: Button = Button.new()
	_bind_text(reset_btn, "model_weight.reset", "Reset")
	reset_btn.pressed.connect(_reset_preview_orientation)
	rotate_row.add_child(reset_btn)

	var rx: Button = Button.new()
	rx.text = "X +90°"
	rx.pressed.connect(
		func() -> void:
			_rotate_preview(Vector3.RIGHT, deg_to_rad(90))
	)
	rotate_row.add_child(rx)

	var ry: Button = Button.new()
	ry.text = "Y +90°"
	ry.pressed.connect(
		func() -> void:
			_rotate_preview(Vector3.UP, deg_to_rad(90))
	)
	rotate_row.add_child(ry)

	var rz: Button = Button.new()
	rz.text = "Z +90°"
	rz.pressed.connect(
		func() -> void:
			_rotate_preview(Vector3.BACK, deg_to_rad(90))
	)
	rotate_row.add_child(rz)

	var mouse_help: Label = Label.new()
	_bind_text(mouse_help, "model_weight.mouse_help", "Left-drag: rotate  |  Wheel: zoom")
	mouse_help.modulate = Color(0.78, 0.78, 0.78)
	rotate_row.add_child(mouse_help)

	confirm_orientation_button = Button.new()
	_bind_text(confirm_orientation_button, "model_weight.confirm_orientation", "Confirm Orientation")
	confirm_orientation_button.custom_minimum_size.y = 36
	confirm_orientation_button.disabled = true
	confirm_orientation_button.pressed.connect(_confirm_orientation)
	preview_panel.add_child(confirm_orientation_button)

	orientation_state = Label.new()
	_bind_text(orientation_state, "model_weight.orientation_not_confirmed", LocalizationService.tr_key("model_weight.orientation_not_confirmed", "Orientation: not confirmed"))
	preview_panel.add_child(orientation_state)

	# ================================================================
	# RIGHT - Model/Profile then Simulation/Result
	# ================================================================
	var right_stack: VBoxContainer = VBoxContainer.new()
	right_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_stack.add_theme_constant_override("separation", 6)
	workspace.add_child(right_stack)

	# ------------------------------------------------
	# Model & Charakoro Profile
	# ------------------------------------------------
	var model_panel: PanelContainer = PanelContainer.new()
	model_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_stack.add_child(model_panel)

	var model_margin: MarginContainer = MarginContainer.new()
	model_margin.add_theme_constant_override("margin_left", 10)
	model_margin.add_theme_constant_override("margin_right", 10)
	model_margin.add_theme_constant_override("margin_top", 8)
	model_margin.add_theme_constant_override("margin_bottom", 8)
	model_panel.add_child(model_margin)

	var model_box: VBoxContainer = VBoxContainer.new()
	model_box.add_theme_constant_override("separation", 6)
	model_margin.add_child(model_box)

	var model_title: Label = Label.new()
	_bind_text(model_title, "model_weight.profile_section", "2. Model & Charakoro Profile")
	model_title.add_theme_font_size_override("font_size", 18)
	model_box.add_child(model_title)

	var file_row: HBoxContainer = HBoxContainer.new()
	file_row.add_theme_constant_override("separation", 6)
	model_box.add_child(file_row)

	path_edit = LineEdit.new()
	_bind_placeholder(path_edit, "model_weight.choose_model", "Choose a supported 3D model...")
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_edit.editable = false
	file_row.add_child(path_edit)

	var browse: Button = Button.new()
	_bind_text(browse, "model_weight.import_model", "Import Model")
	browse.custom_minimum_size.x = 120
	browse.pressed.connect(_browse)
	file_row.add_child(browse)

	var meta_row: HBoxContainer = HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 8)
	model_box.add_child(meta_row)

	var id_group: VBoxContainer = VBoxContainer.new()
	id_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_row.add_child(id_group)
	var pokemon_id_label: Label = _label("Pokémon ID")
	_bind_text(pokemon_id_label, "model_weight.pokemon_id", "Pokémon ID")
	id_group.add_child(pokemon_id_label)
	id_edit = LineEdit.new()
	id_edit.placeholder_text = "squirtle"
	id_edit.text_changed.connect(_on_id_changed)
	id_group.add_child(id_edit)

	var output_group: VBoxContainer = VBoxContainer.new()
	output_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_row.add_child(output_group)
	var profile_filename_label: Label = _label("Profile Filename")
	_bind_text(profile_filename_label, "model_weight.profile_filename", "Profile Filename")
	output_group.add_child(profile_filename_label)
	output_name_edit = LineEdit.new()
	output_name_edit.placeholder_text = "squirtle_model_custom.json"
	output_group.add_child(output_name_edit)

	var size_group: VBoxContainer = VBoxContainer.new()
	size_group.custom_minimum_size.x = 120
	meta_row.add_child(size_group)
	var max_size_label: Label = _label("Max Size (mm)")
	_bind_text(max_size_label, "model_weight.max_size", "Max Size (mm)")
	size_group.add_child(max_size_label)
	size_spin = SpinBox.new()
	size_spin.min_value = 5
	size_spin.max_value = 100
	size_spin.value = 25
	size_spin.step = 0.5
	size_spin.value_changed.connect(_refresh_normalized_model_info)
	size_group.add_child(size_spin)

	import_state_label = Label.new()
	_bind_text(import_state_label, "model_weight.model_not_imported", "Model: not imported")
	import_state_label.modulate = Color(0.78, 0.78, 0.78)
	model_box.add_child(import_state_label)

	model_info_label = RichTextLabel.new()
	model_info_label.bbcode_enabled = true
	model_info_label.fit_content = true
	model_info_label.custom_minimum_size.y = 40
	model_info_label.text = (
		"[color=#BFC3C9]"
		+ LocalizationService.tr_key(
			"model_weight.info_after_import",
			"Model information will appear after import."
		)
		+ "[/color]"
	)
	model_box.add_child(model_info_label)

	# ------------------------------------------------
	# Simulation + Result
	# ------------------------------------------------
	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_stack.add_child(right_panel)

	var right_margin: MarginContainer = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 10)
	right_margin.add_theme_constant_override("margin_right", 10)
	right_margin.add_theme_constant_override("margin_top", 8)
	right_margin.add_theme_constant_override("margin_bottom", 8)
	right_panel.add_child(right_margin)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	right_margin.add_child(right)

	var sim_title: Label = Label.new()
	_bind_text(sim_title, "model_weight.simulation", "3. Simulation")
	sim_title.add_theme_font_size_override("font_size", 18)
	right.add_child(sim_title)

	var sim_options: HBoxContainer = HBoxContainer.new()
	sim_options.add_theme_constant_override("separation", 8)
	right.add_child(sim_options)

	var mode_group: VBoxContainer = VBoxContainer.new()
	mode_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sim_options.add_child(mode_group)
	var mode_label: Label = _label("Mode")
	_bind_text(mode_label, "model_weight.mode", "Mode")
	mode_group.add_child(mode_label)
	mode_option = OptionButton.new()
	mode_option.add_item(LocalizationService.tr_key("model_weight.mode.quick", "Quick"))
	mode_option.add_item(LocalizationService.tr_key("model_weight.mode.normal", "Normal"))
	mode_option.add_item(LocalizationService.tr_key("model_weight.mode.accurate", "Accurate"))
	mode_option.select(1)
	mode_option.item_selected.connect(_on_mode_changed)
	mode_group.add_child(mode_option)

	var throws_group: VBoxContainer = VBoxContainer.new()
	throws_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sim_options.add_child(throws_group)
	var max_throws_label: Label = _label("Max Throws")
	_bind_text(max_throws_label, "model_weight.max_throws", "Max Throws")
	throws_group.add_child(max_throws_label)
	throws_spin = SpinBox.new()
	throws_spin.min_value = 100
	throws_spin.max_value = 100000
	throws_spin.value = 2000
	throws_spin.step = 100
	throws_group.add_child(throws_spin)

	mode_note = Label.new()
	mode_note.text = LocalizationService.tr_key("model_weight.mode_note.normal", "Normal: 2,000 max throws, 64 parallel bodies, adaptive early-stop.")
	mode_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_note.modulate = Color(0.80, 0.80, 0.80)
	right.add_child(mode_note)

	ready_state_label = Label.new()
	ready_state_label.text = LocalizationService.tr_key("model_weight.status_initial", "Status: import a model and confirm orientation")
	ready_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(ready_state_label)

	generate_button = Button.new()
	_bind_text(generate_button, "model_weight.generate", "Generate Weight JSON")
	generate_button.custom_minimum_size.y = 38
	generate_button.disabled = true
	generate_button.pressed.connect(_generate)
	right.add_child(generate_button)

	progress = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.custom_minimum_size.y = 20
	right.add_child(progress)

	status = Label.new()
	_bind_text(status, "model_weight.ready", "Ready.")
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(status)

	right.add_child(HSeparator.new())

	var result_title: Label = Label.new()
	_bind_text(result_title, "model_weight.result", "Result")
	result_title.add_theme_font_size_override("font_size", 16)
	right.add_child(result_title)

	result_box = RichTextLabel.new()
	result_box.fit_content = false
	result_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_box.custom_minimum_size.y = 110
	right.add_child(result_box)

	# ================================================================
	# File dialog
	# ================================================================
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray([
		"*.stl ; STL mesh",
		"*.obj ; Wavefront OBJ",
		"*.glb ; Binary glTF",
		"*.gltf ; glTF"
	])
	file_dialog.file_selected.connect(_load_selected)
	add_child(file_dialog)

func _bind_text(
	control: Control,
	key: String,
	default_text: String
) -> void:
	localized_controls.append({
		"control": control,
		"property": "text",
		"key": key,
		"default": default_text
	})
	control.set(
		"text",
		LocalizationService.tr_key(
			key,
			default_text
		)
	)


func _bind_placeholder(
	control: Control,
	key: String,
	default_text: String
) -> void:
	localized_controls.append({
		"control": control,
		"property": "placeholder_text",
		"key": key,
		"default": default_text
	})
	control.set(
		"placeholder_text",
		LocalizationService.tr_key(
			key,
			default_text
		)
	)


func _on_locale_changed(
	_locale: String
) -> void:
	_apply_localized_text()
	_refresh_localized_options()
	_refresh_dynamic_localized_state()

	if (
		imported_mesh == null
		and model_info_label != null
	):
		model_info_label.text = (
			"[color=#BFC3C9]"
			+ LocalizationService.tr_key(
				"model_weight.info_after_import",
				"Model information will appear after import."
			)
			+ "[/color]"
		)


func _refresh_localized_options() -> void:
	if preview_color_option != null:
		var color_index: int = preview_color_option.selected
		var color_keys: Array[Array] = [
			["model_weight.palette.neutral", "Neutral Gray"],
			["model_weight.palette.pikachu", "Pikachu Yellow"],
			["model_weight.palette.bulbasaur", "Bulbasaur Green"],
			["model_weight.palette.squirtle", "Squirtle Blue"],
			["model_weight.palette.charmander", "Charmander Orange"],
			["model_weight.palette.eevee", "Eevee Brown"],
			["model_weight.palette.mew", "Mew Pink"],
			["model_weight.palette.grimer", "Grimer Purple"],
			["model_weight.palette.red", "Red"]
		]
		for i: int in range(mini(preview_color_option.item_count, color_keys.size())):
			preview_color_option.set_item_text(i, LocalizationService.tr_key(String(color_keys[i][0]), String(color_keys[i][1])))
		preview_color_option.select(color_index)

	if preview_mode_option != null:
		var view_index: int = preview_mode_option.selected
		preview_mode_option.set_item_text(0, LocalizationService.tr_key("model_weight.view.double_sided", "Double-Sided Solid"))
		preview_mode_option.set_item_text(1, LocalizationService.tr_key("model_weight.view.original", "Original Culling"))
		preview_mode_option.select(view_index)

	if mode_option != null:
		var mode_index: int = mode_option.selected
		mode_option.set_item_text(0, LocalizationService.tr_key("model_weight.mode.quick", "Quick"))
		mode_option.set_item_text(1, LocalizationService.tr_key("model_weight.mode.normal", "Normal"))
		mode_option.set_item_text(2, LocalizationService.tr_key("model_weight.mode.accurate", "Accurate"))
		mode_option.select(mode_index)


func _refresh_dynamic_localized_state() -> void:
	if mode_option != null:
		_refresh_mode_note(mode_option.selected)
	if imported_mesh == null:
		if orientation_state != null:
			orientation_state.text = LocalizationService.tr_key("model_weight.orientation_not_confirmed", LocalizationService.tr_key("model_weight.orientation_not_confirmed", "Orientation: not confirmed"))
		if ready_state_label != null:
			ready_state_label.text = LocalizationService.tr_key("model_weight.status_initial", "Status: import a model and confirm orientation")


func _refresh_mode_note(index: int) -> void:
	if mode_note == null:
		return
	if index == 0:
		mode_note.text = LocalizationService.tr_key("model_weight.mode_note.quick", "Quick: 500 throws, 64 parallel bodies, fast settle thresholds.")
	elif index == 1:
		mode_note.text = LocalizationService.tr_key("model_weight.mode_note.normal", "Normal: 2,000 max throws, 64 parallel bodies, adaptive early-stop.")
	else:
		mode_note.text = LocalizationService.tr_key("model_weight.mode_note.accurate", "Accurate: 10,000 max throws, 64 parallel bodies, stricter settle + convergence.")


func _apply_localized_text() -> void:
	for entry: Dictionary in localized_controls:
		var control: Variant = entry.get(
			"control",
			null
		)
		if not is_instance_valid(control):
			continue

		(control as Object).set(
			StringName(
				entry.get(
					"property",
					"text"
				)
			),
			LocalizationService.tr_key(
				String(
					entry.get(
						"key",
						""
					)
				),
				String(
					entry.get(
						"default",
						""
					)
				)
			)
		)


func _label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l

func _on_id_changed(new_text: String) -> void:
	var clean_id: String = new_text.strip_edges().to_lower()
	if output_name_edit == null:
		return

	# Only auto-update while the filename is empty or still follows the prior automatic pattern.
	var current: String = output_name_edit.text.strip_edges()
	if current.is_empty() or current.ends_with("_model_custom.json"):
		output_name_edit.text = clean_id + "_model_custom.json"

func _sanitize_output_filename(raw_name: String, fallback_id: String) -> String:
	var filename: String = raw_name.strip_edges()

	if filename.is_empty():
		filename = fallback_id + "_model_custom.json"

	# Strip path components: output must always stay inside the output folder.
	filename = filename.get_file()

	# Replace characters that are troublesome on common desktop filesystems.
	var invalid_chars := ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]
	for ch in invalid_chars:
		filename = filename.replace(ch, "_")

	if not filename.to_lower().ends_with(".json"):
		filename += ".json"

	if filename == ".json":
		filename = fallback_id + "_model_custom.json"

	return filename

func _vector_key(v: Vector3, epsilon: float = 0.00001) -> String:
	# Quantization allows non-indexed STL triangle vertices with the same
	# coordinates to be recognized as the same topological vertex.
	var qx: int = int(round(v.x / epsilon))
	var qy: int = int(round(v.y / epsilon))
	var qz: int = int(round(v.z / epsilon))
	return "%d,%d,%d" % [qx, qy, qz]

func _edge_key(a: String, b: String) -> String:
	if a < b:
		return a + "|" + b
	return b + "|" + a

func _analyze_mesh(mesh: ArrayMesh, source_path: String) -> Dictionary:
	var triangle_count: int = 0
	var source_vertex_entries: int = 0
	var unique_vertices: Dictionary = {}
	var edge_counts: Dictionary = {}

	for surface_index in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_index)
		var verts: PackedVector3Array = PackedVector3Array(
			arrays[Mesh.ARRAY_VERTEX]
		)
		var index_data: Variant = arrays[Mesh.ARRAY_INDEX]
		var indices: PackedInt32Array = PackedInt32Array()
		if index_data != null:
			indices = PackedInt32Array(index_data)

		var triangle_vertices: Array[Vector3] = []

		if indices.is_empty():
			source_vertex_entries += verts.size()
			triangle_vertices.resize(verts.size())
			for i in range(verts.size()):
				triangle_vertices[i] = verts[i]
		else:
			source_vertex_entries += indices.size()
			triangle_vertices.resize(indices.size())
			for i in range(indices.size()):
				var idx: int = indices[i]
				if idx >= 0 and idx < verts.size():
					triangle_vertices[i] = verts[idx]

		var usable_count: int = triangle_vertices.size() - (
			triangle_vertices.size() % 3
		)

		for i in range(0, usable_count, 3):
			var a: Vector3 = triangle_vertices[i]
			var b: Vector3 = triangle_vertices[i + 1]
			var c: Vector3 = triangle_vertices[i + 2]

			var ka: String = _vector_key(a)
			var kb: String = _vector_key(b)
			var kc: String = _vector_key(c)

			unique_vertices[ka] = true
			unique_vertices[kb] = true
			unique_vertices[kc] = true

			var e1: String = _edge_key(ka, kb)
			var e2: String = _edge_key(kb, kc)
			var e3: String = _edge_key(kc, ka)

			edge_counts[e1] = int(edge_counts.get(e1, 0)) + 1
			edge_counts[e2] = int(edge_counts.get(e2, 0)) + 1
			edge_counts[e3] = int(edge_counts.get(e3, 0)) + 1

			triangle_count += 1

	var boundary_edges: int = 0
	var non_manifold_edges: int = 0

	for count_value in edge_counts.values():
		var edge_count: int = int(count_value)
		if edge_count == 1:
			boundary_edges += 1
		elif edge_count != 2:
			non_manifold_edges += 1

	var watertight: bool = (
		triangle_count > 0
		and boundary_edges == 0
		and non_manifold_edges == 0
	)

	var aabb: AABB = mesh.get_aabb()
	var source_max: float = maxf(
		aabb.size.x,
		maxf(aabb.size.y, aabb.size.z)
	)

	var normalized_scale: float = 1.0
	if source_max > 0.0:
		normalized_scale = float(size_spin.value) / source_max

	var normalized_size: Vector3 = aabb.size * normalized_scale

	return {
		"format": source_path.get_extension().to_upper(),
		"triangle_count": triangle_count,
		"unique_vertex_count": unique_vertices.size(),
		"source_vertex_entries": source_vertex_entries,
		"surface_count": mesh.get_surface_count(),
		"source_size": aabb.size,
		"normalized_size": normalized_size,
		"boundary_edges": boundary_edges,
		"non_manifold_edges": non_manifold_edges,
		"watertight": watertight
	}

func _format_vec3(v: Vector3) -> String:
	return "{x} x {y} x {z}" .format({
		"x": LocalizationService.format_decimal(v.x, 2),
		"y": LocalizationService.format_decimal(v.y, 2),
		"z": LocalizationService.format_decimal(v.z, 2)
	})

func _update_model_info_display(info: Dictionary) -> void:
	if info.is_empty():
		model_info_label.text = "[color=#BFC3C9]" + LocalizationService.tr_key("model_weight.info_unavailable", "Model information unavailable.") + "[/color]"
		return

	var mesh_state: String
	if bool(info["watertight"]):
		mesh_state = "[color=#79C98B]" + LocalizationService.tr_key("model_weight.watertight", "[OK] Watertight") + "[/color]"
	elif int(info["non_manifold_edges"]) > 0:
		mesh_state = "[color=#E6A85C]" + LocalizationService.tr_key("model_weight.non_manifold", "WARNING Non-manifold mesh") + "[/color] " + LocalizationService.tr_format(
			"model_weight.mesh_edges",
			{"open": int(info["boundary_edges"]), "non_manifold": int(info["non_manifold_edges"])},
			"(open edges: {open}, non-manifold edges: {non_manifold})"
		)
	else:
		mesh_state = "[color=#E6A85C]" + LocalizationService.tr_key("model_weight.open_mesh", "WARNING Open / non-watertight mesh") + "[/color] " + LocalizationService.tr_format(
			"model_weight.open_edges",
			{"open": int(info["boundary_edges"])},
			"(open edges: {open})"
		)

	model_info_label.text = LocalizationService.tr_format(
		"model_weight.model_summary_locale",
		{
			"format": str(info["format"]),
			"mesh_state": mesh_state,
			"triangles": LocalizationService.format_count(
				"format.count.triangle.one", "format.count.triangle.other",
				int(info["triangle_count"]), "{count} triangle", "{count} triangles"
			),
			"vertices": LocalizationService.format_count(
				"format.count.vertex.one", "format.count.vertex.other",
				int(info["unique_vertex_count"]), "{count} unique vertex", "{count} unique vertices"
			),
			"original": _format_vec3(info["source_size"]),
			"normalized": _format_vec3(info["normalized_size"])
		},
		"[b]{format}[/b]    |    {mesh_state}    |    {triangles}    |    {vertices}\nOriginal bounds: {original}   ->   Normalized: {normalized} mm"
	)



func _refresh_normalized_model_info(_value: float) -> void:
	if imported_mesh == null or imported_model_path.is_empty():
		return
	imported_mesh_info = _analyze_mesh(
		imported_mesh,
		imported_model_path
	)
	_update_model_info_display(imported_mesh_info)

func _browse() -> void:
	file_dialog.popup_centered_ratio(0.82)

func _load_selected(path: String) -> void:
	path_edit.text = path
	imported_model_path = path
	imported_mesh_info = {}
	model_info_label.text = ("[color=#BFC3C9]" + LocalizationService.tr_key("model_weight.analyzing", "Analyzing model...") + "[/color]")
	var base := path.get_file().get_basename().to_lower()
	base = base.replace(" plakoro", "").replace("_plakoro", "").replace("-plakoro", "")
	base = base.replace(" ", "_").replace("-", "_")
	id_edit.text = base
	output_name_edit.text = base + "_model_custom.json"

	orientation_confirmed = false
	confirmed_orientation = Basis.IDENTITY
	orientation_state.text = LocalizationService.tr_key("model_weight.orientation_not_confirmed", "Orientation: not confirmed")
	import_state_label.text = LocalizationService.tr_key("model_weight.model_importing", "Model: importing...")
	ready_state_label.text = LocalizationService.tr_key("model_weight.status_importing", "Status: importing model...")
	generate_button.disabled = true
	confirm_orientation_button.disabled = true
	result_box.text = ""
	progress.value = 0
	status.text = LocalizationService.tr_key("model_weight.importing", "Importing model...")
	await get_tree().process_frame

	imported_mesh = _import_to_mesh(path)

	if imported_mesh == null:
		status.text = LocalizationService.tr_key("model_weight.import_failed", "Import failed. Supported formats: STL, OBJ, GLB, GLTF.")
		import_state_label.text = LocalizationService.tr_key("model_weight.model_import_failed", "Model: import failed")
		model_info_label.text = ("[color=#E07070]" + LocalizationService.tr_key("model_weight.analysis_import_failed", "Model analysis unavailable because import failed.") + "[/color]")
		ready_state_label.text = LocalizationService.tr_key("model_weight.status_import_failed", "Status: model import failed")
		_clear_preview()
		return

	imported_mesh_info = _analyze_mesh(imported_mesh, path)
	_update_model_info_display(imported_mesh_info)

	_set_preview_mesh(imported_mesh)
	confirm_orientation_button.disabled = false

	if bool(imported_mesh_info["watertight"]):
		import_state_label.text = LocalizationService.tr_key("model_weight.model_imported", "Model: imported [OK]")
	else:
		import_state_label.text = LocalizationService.tr_key("model_weight.model_imported_warning", "Model: imported with mesh warning WARNING")

	ready_state_label.text = LocalizationService.tr_key("model_weight.status_confirm_orientation", "Status: confirm orientation")
	status.text = LocalizationService.tr_key("model_weight.imported_confirm", "Imported. Confirm model orientation before generating.")

func _import_to_mesh(path: String) -> ArrayMesh:
	var ext := path.get_extension().to_lower()
	if ext == "stl":
		return STLImporter.new().load_mesh(path)
	if ext == "obj":
		return OBJImporter.new().load_mesh(path)
	if ext == "glb" or ext == "gltf":
		var scene := GLTFImporter.new().load_scene(path)
		if scene == null:
			return null
		return _combine_scene_meshes(scene)
	return null

func _combine_scene_meshes(root_node: Node) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_node_meshes(root_node, Transform3D.IDENTITY, st)
	var result := st.commit()
	root_node.queue_free()
	return result

func _append_node_meshes(node: Node, parent_xf: Transform3D, st: SurfaceTool) -> void:
	var xf := parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform

	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for s in range(mi.mesh.get_surface_count()):
			var arr := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = PackedVector3Array(arr[Mesh.ARRAY_VERTEX])
			var index_data: Variant = arr[Mesh.ARRAY_INDEX]
			var indices: PackedInt32Array = PackedInt32Array()
			if index_data != null:
				indices = PackedInt32Array(index_data)

			if indices.is_empty():
				for v in verts:
					st.add_vertex(xf * v)
			else:
				for idx in indices:
					st.add_vertex(xf * verts[idx])

	for c in node.get_children():
		_append_node_meshes(c, xf, st)

func _preview_color(index: int) -> Color:
	match index:
		1:
			return Color("#F2C94C") # yellow
		2:
			return Color("#78B879") # green
		3:
			return Color("#63A9D8") # blue
		4:
			return Color("#E99555") # orange
		5:
			return Color("#A97957") # brown
		6:
			return Color("#E7A7C4") # pink
		7:
			return Color("#9165A8") # purple
		8:
			return Color("#D65C5C") # red
		_:
			return Color("#B9BEC8") # neutral gray

func _on_preview_mode_changed(index: int) -> void:
	if preview_material == null:
		return

	if index == 0:
		# Render both triangle sides. This is important for community STL/OBJ
		# meshes with inconsistent winding or reversed normals.
		preview_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	else:
		preview_material.cull_mode = BaseMaterial3D.CULL_BACK

func _on_preview_color_changed(index: int) -> void:
	if preview_material != null:
		preview_material.albedo_color = _preview_color(index)

func _create_preview_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()

	# Solid, opaque preview. This is deliberately independent of source textures
	# so STL/OBJ/GLB can all be inspected with the same readable shading.
	material.albedo_color = _preview_color(
		preview_color_option.selected if preview_color_option != null else 0
	)
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 0.92
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = false

	return material

func _clear_preview() -> void:
	if preview_mesh_instance != null and is_instance_valid(preview_mesh_instance):
		preview_mesh_instance.queue_free()
	preview_mesh_instance = null
	preview_material = null

func _set_preview_mesh(mesh: ArrayMesh) -> void:
	_clear_preview()
	preview_pivot.transform = Transform3D.IDENTITY

	var display_mesh := _center_and_scale_mesh(mesh, 1.7)
	preview_mesh_instance = MeshInstance3D.new()
	preview_mesh_instance.mesh = display_mesh

	preview_material = _create_preview_material()
	preview_mesh_instance.material_override = preview_material

	preview_pivot.add_child(preview_mesh_instance)

func _preview_gui_input(event: InputEvent) -> void:
	if imported_mesh == null:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			dragging = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			preview_camera.size = maxf(0.5, preview_camera.size * 0.90)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			preview_camera.size = minf(10.0, preview_camera.size * 1.10)

	elif event is InputEventMouseMotion and dragging:
		var mm := event as InputEventMouseMotion
		preview_pivot.rotate_y(-mm.relative.x * 0.01)
		preview_pivot.rotate_object_local(Vector3.RIGHT, -mm.relative.y * 0.01)
		_mark_orientation_dirty()

func _rotate_preview(axis: Vector3, angle: float) -> void:
	if imported_mesh == null:
		return
	preview_pivot.rotate_object_local(axis, angle)
	_mark_orientation_dirty()

func _reset_preview_orientation() -> void:
	if imported_mesh == null:
		return
	preview_pivot.transform = Transform3D.IDENTITY
	preview_camera.look_at_from_position(
		Vector3(0, 0, 3.2),
		Vector3.ZERO,
		Vector3.UP
	)
	preview_camera.size = 2.6
	_mark_orientation_dirty()

func _mark_orientation_dirty() -> void:
	if orientation_confirmed:
		orientation_confirmed = false
		orientation_state.text = LocalizationService.tr_key("model_weight.orientation_changed", "Orientation: changed - confirm again")
		ready_state_label.text = LocalizationService.tr_key("model_weight.status_orientation_changed", "Status: orientation changed - confirm again")
		generate_button.disabled = true

func _confirm_orientation() -> void:
	if imported_mesh == null:
		return

	confirmed_orientation = preview_pivot.transform.basis.orthonormalized()
	orientation_confirmed = true
	orientation_state.text = LocalizationService.tr_key("model_weight.orientation_confirmed", "Orientation: confirmed [OK]")
	ready_state_label.text = LocalizationService.tr_key("model_weight.status_ready", "Status: ready to generate [OK]")
	generate_button.disabled = false
	status.text = LocalizationService.tr_key("model_weight.orientation_ready", "Orientation confirmed. Ready to generate.")

func _center_and_scale_mesh(mesh: ArrayMesh, target_max_dimension: float) -> ArrayMesh:
	var aabb: AABB = mesh.get_aabb()
	var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_dim <= 0.0:
		return null

	var factor: float = target_max_dimension / max_dim
	var center: Vector3 = aabb.position + aabb.size * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for s in range(mesh.get_surface_count()):
		var arr := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = PackedVector3Array(arr[Mesh.ARRAY_VERTEX])
		var index_data: Variant = arr[Mesh.ARRAY_INDEX]
		var indices: PackedInt32Array = PackedInt32Array()
		if index_data != null:
			indices = PackedInt32Array(index_data)

		if indices.is_empty():
			for v in verts:
				st.add_vertex((v - center) * factor)
		else:
			for idx in indices:
				st.add_vertex((verts[idx] - center) * factor)

	st.generate_normals()
	return st.commit()

func _build_canonical_simulation_mesh(mesh: ArrayMesh, target_mm: float) -> ArrayMesh:
	var aabb: AABB = mesh.get_aabb()
	var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_dim <= 0.0:
		return null

	var factor: float = target_mm / max_dim
	var center: Vector3 = aabb.position + aabb.size * 0.5

	# User rotates model in preview until:
	#   head = preview +Y
	#   face = preview +Z (toward camera)
	#
	# Then bake that rotation and convert preview coordinates into the
	# project canonical orientation:
	#   HEAD_UP   = +Z
	#   FACE_UP   = +Y
	#   HEAD_LEFT = +X
	var bake_basis: Basis = PREVIEW_TO_CANONICAL * confirmed_orientation

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for s in range(mesh.get_surface_count()):
		var arr := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = PackedVector3Array(arr[Mesh.ARRAY_VERTEX])
		var index_data: Variant = arr[Mesh.ARRAY_INDEX]
		var indices: PackedInt32Array = PackedInt32Array()
		if index_data != null:
			indices = PackedInt32Array(index_data)

		if indices.is_empty():
			for v in verts:
				var centered: Vector3 = (v - center) * factor
				st.add_vertex(bake_basis * centered)
		else:
			for idx in indices:
				var centered: Vector3 = (verts[idx] - center) * factor
				st.add_vertex(bake_basis * centered)

	st.generate_normals()
	return st.commit()

func _on_mode_changed(index: int) -> void:
	if index == 0:
		throws_spin.value = 500
	elif index == 1:
		throws_spin.value = 2000
	else:
		throws_spin.value = 10000
	_refresh_mode_note(index)



func _simulation_profile() -> Dictionary:
	var index: int = mode_option.selected

	if index == 0:
		return {
			"name": "Quick",
			"batch_size": 64,
			"settle_linear": 0.04,
			"settle_angular": 0.20,
			"settle_time": 0.20,
			"timeout": 2.0,
			"early_stop": false,
			"min_throws": 500,
			"checkpoint": 500,
			"threshold": 0.0,
			"stable_checks_required": 0
		}

	if index == 2:
		return {
			"name": "Accurate",
			"batch_size": 64,
			"settle_linear": 0.02,
			"settle_angular": 0.10,
			"settle_time": 0.40,
			"timeout": 5.0,
			"early_stop": true,
			"min_throws": 4000,
			"checkpoint": 1000,
			"threshold": 0.0075,
			"stable_checks_required": 2
		}

	return {
		"name": "Normal",
		"batch_size": 64,
		"settle_linear": 0.03,
		"settle_angular": 0.15,
		"settle_time": 0.25,
		"timeout": 3.0,
		"early_stop": true,
		"min_throws": 1000,
		"checkpoint": 500,
		"threshold": 0.015,
		"stable_checks_required": 2
	}

func _make_throw_body(shared_shape: Shape3D) -> RigidBody3D:
	var body: RigidBody3D = RigidBody3D.new()
	body.continuous_cd = true
	body.freeze = true

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shared_shape
	collision.scale = Vector3.ONE * 0.001 # normalized mesh is millimeters
	body.add_child(collision)

	var pm: PhysicsMaterial = PhysicsMaterial.new()
	pm.friction = 0.35
	pm.bounce = 0.35
	body.physics_material_override = pm

	add_child(body)
	return body

func _make_body_pool(shared_shape: Shape3D, count: int) -> Array[RigidBody3D]:
	var pool: Array[RigidBody3D] = []
	for i in range(count):
		pool.append(_make_throw_body(shared_shape))
	return pool

func _reset_throw_body(body: RigidBody3D) -> void:
	body.freeze = true
	body.sleeping = false
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO

	body.position = Vector3(
		rng.randf_range(-0.015, 0.015),
		0.15,
		rng.randf_range(-0.015, 0.015)
	)
	body.quaternion = _random_quaternion()

	body.linear_velocity = _random_unit_vector() * rng.randf_range(0.0, 0.45)
	body.angular_velocity = _random_unit_vector() * rng.randf_range(4.0, 20.0)
	body.freeze = false
	body.sleeping = false

func _run_throw_batch(
	pool: Array[RigidBody3D],
	active_count: int,
	profile: Dictionary
) -> Array[String]:
	var results: Array[String] = []
	results.resize(active_count)

	var settled_time: Array[float] = []
	var finished: Array[bool] = []
	settled_time.resize(active_count)
	finished.resize(active_count)

	for i in range(active_count):
		settled_time[i] = 0.0
		finished[i] = false
		_reset_throw_body(pool[i])

	# Keep unused pool bodies frozen and out of the way.
	for i in range(active_count, pool.size()):
		pool[i].freeze = true
		pool[i].position = Vector3(0.0, -10.0, 0.0)

	await get_tree().physics_frame

	var elapsed: float = 0.0
	var finished_count: int = 0
	var timeout: float = float(profile["timeout"])
	var settle_linear: float = float(profile["settle_linear"])
	var settle_angular: float = float(profile["settle_angular"])
	var settle_required: float = float(profile["settle_time"])

	while elapsed < timeout and finished_count < active_count:
		await get_tree().physics_frame
		var dt: float = 1.0 / float(Engine.physics_ticks_per_second)
		elapsed += dt

		for i in range(active_count):
			if finished[i]:
				continue

			var body: RigidBody3D = pool[i]

			if body.linear_velocity.length() < settle_linear \
			and body.angular_velocity.length() < settle_angular:
				settled_time[i] += dt
				if settled_time[i] >= settle_required:
					results[i] = _classify(body.global_transform.basis)
					finished[i] = true
					finished_count += 1
					body.freeze = true
			else:
				settled_time[i] = 0.0

	# Timeout does not discard a throw: classify its current orientation.
	for i in range(active_count):
		if not finished[i]:
			results[i] = _classify(pool[i].global_transform.basis)
			pool[i].freeze = true

	return results

func _probability_snapshot(counts: Dictionary, samples: int) -> Dictionary:
	var snapshot: Dictionary = {}
	if samples <= 0:
		return snapshot

	for orientation in ORIENTATIONS:
		snapshot[orientation] = float(counts[orientation]) / float(samples)
	return snapshot

func _max_probability_delta(a: Dictionary, b: Dictionary) -> float:
	if a.is_empty() or b.is_empty():
		return INF

	var largest: float = 0.0
	for orientation in ORIENTATIONS:
		largest = maxf(
			largest,
			absf(float(a[orientation]) - float(b[orientation]))
		)
	return largest

func _generate() -> void:
	if not orientation_confirmed:
		status.text = LocalizationService.tr_key("model_weight.confirm_first", "Confirm orientation first.")
		return

	generate_button.disabled = true
	mode_option.disabled = true
	throws_spin.editable = false

	var pokemon: String = id_edit.text.strip_edges().to_lower()
	if pokemon.is_empty():
		status.text = LocalizationService.tr_key("model_weight.pokemon_required", "Pokémon ID is required.")
		generate_button.disabled = false
		mode_option.disabled = false
		throws_spin.editable = true
		return

	var mesh: ArrayMesh = _build_canonical_simulation_mesh(
		imported_mesh,
		float(size_spin.value)
	)
	if mesh == null:
		status.text = LocalizationService.tr_key("model_weight.mesh_build_failed", "Could not build canonical simulation mesh.")
		generate_button.disabled = false
		mode_option.disabled = false
		throws_spin.editable = true
		return

	status.text = LocalizationService.tr_key("model_weight.building_collision", "Building convex collision shape once...")
	await get_tree().process_frame

	# PERFORMANCE: create the expensive convex hull only once.
	var shared_shape: Shape3D = mesh.create_convex_shape(true, true)
	if shared_shape == null:
		status.text = LocalizationService.tr_key("model_weight.collision_failed", "Could not create convex collision shape.")
		generate_button.disabled = false
		mode_option.disabled = false
		throws_spin.editable = true
		return

	var profile: Dictionary = _simulation_profile()
	var max_throws: int = int(throws_spin.value)
	var batch_size: int = mini(int(profile["batch_size"]), max_throws)

	var counts: Dictionary = {}
	for orientation in ORIENTATIONS:
		counts[orientation] = 0

	rng.seed = 20260811 + abs(pokemon.hash())

	var floor_body: StaticBody3D = _make_floor()
	add_child(floor_body)

	# PERFORMANCE: create the RigidBody3D pool once, then reset/reuse it.
	var body_pool: Array[RigidBody3D] = _make_body_pool(shared_shape, batch_size)
	await get_tree().physics_frame

	var completed: int = 0
	var early_stopped: bool = false
	var previous_snapshot: Dictionary = {}
	var stable_checks: int = 0
	var next_checkpoint: int = int(profile["checkpoint"])

	while completed < max_throws:
		var this_batch: int = mini(batch_size, max_throws - completed)
		var batch_results: Array[String] = await _run_throw_batch(
			body_pool,
			this_batch,
			profile
		)

		for result in batch_results:
			counts[result] += 1

		completed += this_batch
		progress.value = float(completed) / float(max_throws) * 100.0
		status.text = LocalizationService.tr_format(
			"model_weight.progress_locale",
			{
				"pokemon": pokemon,
				"mode": String(profile["name"]),
				"completed": LocalizationService.format_count(
					"format.count.throw.one", "format.count.throw.other",
					completed, "{count} throw", "{count} throws"
				),
				"total": LocalizationService.format_count(
					"format.count.throw.one", "format.count.throw.other",
					max_throws, "{count} throw", "{count} throws"
				)
			},
			"{pokemon} / {mode}: {completed} / {total}"
		)

		if bool(profile["early_stop"]) and completed >= next_checkpoint:
			var current_snapshot: Dictionary = _probability_snapshot(counts, completed)

			if not previous_snapshot.is_empty():
				var delta: float = _max_probability_delta(
					previous_snapshot,
					current_snapshot
				)

				if completed >= int(profile["min_throws"]) \
				and delta <= float(profile["threshold"]):
					stable_checks += 1
				else:
					stable_checks = 0

				status.text += LocalizationService.tr_format(
					"model_weight.convergence",
					{"delta": LocalizationService.format_decimal(delta * 100.0, 3), "stable": stable_checks, "required": int(profile["stable_checks_required"])},
					" | convergence delta {delta}% ({stable}/{required})"
				)

				if stable_checks >= int(profile["stable_checks_required"]):
					early_stopped = true
					break

			previous_snapshot = current_snapshot
			while next_checkpoint <= completed:
				next_checkpoint += int(profile["checkpoint"])

		await get_tree().process_frame

	for body in body_pool:
		body.queue_free()
	floor_body.queue_free()

	progress.value = 100.0

	var weights: Dictionary = {}
	var result_text: String = ""
	result_text += LocalizationService.tr_format("model_weight.result_mode", {"mode": String(profile["name"])}, "Mode: {mode}") + "\n"
	result_text += LocalizationService.tr_format(
		"model_weight.throws_used",
		{"throws": LocalizationService.format_integer(completed)},
		"Throws used: {throws}"
	)
	if early_stopped:
		result_text += LocalizationService.tr_key("model_weight.converged_early", " (converged early)")
	result_text += "\n\n"

	for orientation in ORIENTATIONS:
		var p: float = float(counts[orientation]) / float(completed)
		weights[orientation] = snapped(p * 6.0, 0.0001)
		result_text += LocalizationService.tr_format(
			"model_weight.result_orientation",
			{
				"orientation": orientation,
				"percent": LocalizationService.format_decimal(p * 100.0, 2),
				"weight": LocalizationService.format_decimal(weights[orientation], 4)
			},
			"{orientation}  {percent}%   weight {weight}"
		) + "\n"

	var output: Dictionary = {
		"schema_version": "2.0",
		"id": pokemon + "_model_custom",
		"roll_mode": "weighted",
		"orientation_weights": weights,
		"scene_path": "",
		"physics_profile": {},
		"model_analysis": {
			"source": "model_weight_generator",
			"model_file": imported_model_path.get_file(),
			"normalized_max_size_mm": float(size_spin.value),
			"watertight": bool(imported_mesh_info.get("watertight", false)),
			"triangle_count": int(imported_mesh_info.get("triangle_count", 0))
		}
	}

	var out_dir: String = _output_dir()
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(out_dir)
	)

	var output_filename: String = _sanitize_output_filename(
		output_name_edit.text,
		pokemon
	)
	output_name_edit.text = output_filename

	var out_path: String = out_dir.path_join(output_filename)
	var output_file: FileAccess = FileAccess.open(
		out_path,
		FileAccess.WRITE
	)

	if output_file != null:
		output_file.store_string(JSON.stringify(output, "\t"))
		result_box.text = result_text
		status.text = LocalizationService.tr_format(
			"model_weight.saved_profile_locale",
			{
				"path": out_path,
				"throws": LocalizationService.format_count(
					"format.count.throw.one", "format.count.throw.other",
					completed, "{count} throw", "{count} throws"
				),
				"convergence": (" | " + LocalizationService.tr_key("model_weight.converged_early", "converged early").strip_edges()) if early_stopped else ""
			},
			"Saved Charakoro profile: {path} | {throws}{convergence}"
		)
	else:
		status.text = LocalizationService.tr_key("model_weight.write_failed", "Could not write output file.")

	generate_button.disabled = false
	mode_option.disabled = false
	throws_spin.editable = true

func _output_dir() -> String:
	return "user://user_database/kyokoro_profiles"

func _make_floor() -> StaticBody3D:
	var floor_body: StaticBody3D = StaticBody3D.new()

	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2, 0.02, 2)
	cs.shape = box
	cs.position.y = -0.01
	floor_body.add_child(cs)

	var pm: PhysicsMaterial = PhysicsMaterial.new()
	pm.friction = 0.35
	pm.bounce = 0.35
	floor_body.physics_material_override = pm

	return floor_body

func _classify(b: Basis) -> String:
	var scores := {
		"HEAD_LEFT": b.x.dot(Vector3.UP),
		"HEAD_RIGHT": (-b.x).dot(Vector3.UP),
		"FACE_UP": b.y.dot(Vector3.UP),
		"FACE_DOWN": (-b.y).dot(Vector3.UP),
		"HEAD_UP": b.z.dot(Vector3.UP),
		"HEAD_DOWN": (-b.z).dot(Vector3.UP)
	}

	var best := "HEAD_UP"
	var score := -INF

	for k in scores:
		if float(scores[k]) > score:
			score = float(scores[k])
			best = k

	return best

func _random_unit_vector() -> Vector3:
	var z: float = rng.randf_range(-1.0, 1.0)
	var a: float = rng.randf_range(0.0, TAU)
	var r: float = sqrt(maxf(0.0, 1.0 - z * z))
	return Vector3(r * cos(a), z, r * sin(a))

func _random_quaternion() -> Quaternion:
	var u1: float = rng.randf()
	var u2: float = rng.randf()
	var u3: float = rng.randf()

	return Quaternion(
		sqrt(1.0 - u1) * sin(TAU * u2),
		sqrt(1.0 - u1) * cos(TAU * u2),
		sqrt(u1) * sin(TAU * u3),
		sqrt(u1) * cos(TAU * u3)
	).normalized()
