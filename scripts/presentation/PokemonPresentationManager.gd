extends RefCounted

const RESOLVER: Script = preload(
    "res://scripts/presentation/PresentationAssetResolver.gd"
)
const USER_ASSETS: Script = preload(
    "res://scripts/presentation/UserAssetService.gd"
)

const PORTRAIT_SIZE: int = 200

static func present(
    target: Control,
    pokemon_id: StringName,
    display_name: String,
    _compact: bool = false
) -> Dictionary:
    _clear_target(target)
    var resolved: Dictionary = RESOLVER.resolve_pokemon(pokemon_id)

    if StringName(resolved["mode"]) == &"image_2d":
        if _present_image(target, String(resolved["image_path"]), display_name):
            return resolved

    _present_placeholder(target, display_name, pokemon_id)
    resolved["mode"] = &"placeholder"
    return resolved

static func _present_image(target: Control, path: String, display_name: String) -> bool:
    var relative_path: String = ""
    if path.begins_with(USER_ASSETS.USER_ROOT + "/"):
        relative_path = path.trim_prefix(USER_ASSETS.USER_ROOT + "/")
    elif path.begins_with(USER_ASSETS.BUILTIN_ROOT + "/"):
        relative_path = path.trim_prefix(USER_ASSETS.BUILTIN_ROOT + "/")
    else:
        return false

    var texture: Texture2D = USER_ASSETS.load_texture(relative_path)
    if texture == null:
        return false

    var center: CenterContainer = CenterContainer.new()
    center.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    target.add_child(center)

    var image: TextureRect = TextureRect.new()
    image.texture = texture
    image.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    image.tooltip_text = display_name
    center.add_child(image)
    return true

static func _present_placeholder(target: Control, display_name: String, pokemon_id: StringName) -> void:
    var label: Label = Label.new()
    label.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
    label.text = display_name + "\n" + String(pokemon_id) + "\n\nPNG missing"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.modulate.a = 0.68
    target.add_child(label)

static func _clear_target(target: Control) -> void:
    if target == null:
        return
    for child: Node in target.get_children():
        child.queue_free()
