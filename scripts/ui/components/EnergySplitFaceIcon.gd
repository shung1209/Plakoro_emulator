extends Control


const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)

const GLYPH_CROP_RATIO: float = 0.15


var first_energy: StringName = &""
var second_energy: StringName = &""
var _display_size: float = 30.0


func setup(
    first: StringName,
    second: StringName,
    display_size: float = 30.0
) -> void:
    name = "EnergySplitFaceIcon"
    first_energy = first
    second_energy = second
    _display_size = display_size
    custom_minimum_size = Vector2(_display_size, _display_size)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_contents = true
    _rebuild_glyphs()


func _rebuild_glyphs() -> void:
    for child: Node in get_children():
        child.queue_free()

    _add_split_background()

    var glyph_size: float = _display_size * 0.38
    var margin: float = _display_size * 0.10
    _add_glyph(
        first_energy,
        Vector2(margin, margin),
        glyph_size
    )
    _add_glyph(
        second_energy,
        Vector2(
            _display_size - glyph_size - margin,
            _display_size - glyph_size - margin
        ),
        glyph_size
    )


func _add_split_background() -> void:
    var background: ColorRect = ColorRect.new()
    background.name = "SplitBackground"
    background.color = Color.WHITE
    background.position = Vector2.ZERO
    background.size = Vector2(_display_size, _display_size)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.material = _create_split_background_material()
    add_child(background)


func _create_split_background_material() -> ShaderMaterial:
    var shader: Shader = Shader.new()
    shader.code = (
        "shader_type canvas_item;\n"
        + "uniform vec4 first_color : source_color;\n"
        + "uniform vec4 second_color : source_color;\n"
        + "void fragment() {\n"
        + "    const float radius = 0.16;\n"
        + "    vec2 q = abs(UV - vec2(0.5)) - vec2(0.5 - radius);\n"
        + "    float distance_to_edge = length(max(q, vec2(0.0))) "
        + "+ min(max(q.x, q.y), 0.0) - radius;\n"
        + "    float edge_alpha = 1.0 - smoothstep(-0.008, 0.008, distance_to_edge);\n"
        + "    vec4 energy_color = (UV.x + UV.y <= 1.0) "
        + "? first_color : second_color;\n"
        + "    float border = 1.0 - smoothstep(0.040, 0.070, -distance_to_edge);\n"
        + "    float diagonal = 1.0 - smoothstep(0.025, 0.050, "
        + "abs(UV.x + UV.y - 1.0));\n"
        + "    vec4 result = mix(energy_color, vec4(1.0), max(border, diagonal));\n"
        + "    COLOR = vec4(result.rgb, result.a * edge_alpha);\n"
        + "}\n"
    )
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter(
        "first_color",
        _energy_color(first_energy)
    )
    material.set_shader_parameter(
        "second_color",
        _energy_color(second_energy)
    )
    return material


func _add_glyph(
    energy_type: StringName,
    position: Vector2,
    glyph_size: float
) -> void:
    var source: Texture2D = ICONS.load_energy_icon(energy_type)
    if source == null:
        return

    var atlas: AtlasTexture = AtlasTexture.new()
    atlas.atlas = source
    var crop: Vector2 = source.get_size() * GLYPH_CROP_RATIO
    atlas.region = Rect2(
        crop,
        source.get_size() - crop * 2.0
    )

    var glyph: TextureRect = TextureRect.new()
    glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    glyph.texture = atlas
    glyph.position = position
    glyph.size = Vector2(glyph_size, glyph_size)
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    glyph.material = _create_white_glyph_material()
    add_child(glyph)


func _create_white_glyph_material() -> ShaderMaterial:
    var shader: Shader = Shader.new()
    shader.code = (
        "shader_type canvas_item;\n"
        + "void fragment() {\n"
        + "    vec4 sample_color = texture(TEXTURE, UV);\n"
        + "    float whiteness = smoothstep(0.72, 0.94, "
        + "min(sample_color.r, min(sample_color.g, sample_color.b)));\n"
        + "    COLOR = vec4(1.0, 1.0, 1.0, sample_color.a * whiteness);\n"
        + "}\n"
    )
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = shader
    return material


func _energy_color(energy_type: StringName) -> Color:
    match energy_type:
        &"grass":
            return Color("34ad62")
        &"fire":
            return Color("ec3154")
        &"water":
            return Color("1684c4")
        &"electric":
            return Color("f4c20d")
        &"psychic":
            return Color("ce3b91")
        &"fighting":
            return Color("e96f14")
        &"dark":
            return Color("087b8d")
        &"steel":
            return Color("8791a8")
        &"flying":
            return Color("53bddc")
        _:
            return Color("8f98aa")
