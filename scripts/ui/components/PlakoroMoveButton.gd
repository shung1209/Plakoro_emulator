extends Button


const EFFECT_PRESENTATION: Script = preload(
    "res://scripts/presentation/MoveKyokoroEffectPresentationService.gd"
)
const POPUP_SCRIPT: Script = preload(
    "res://scripts/ui/components/KyokoroEffectPopup.gd"
)
const MOVE_ENERGY_COST_ROW: Script = preload(
    "res://scripts/ui/components/MoveEnergyCostRow.gd"
)
const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)
const NINJA_ATTACK_FONT = preload(
	"res://assets/fonts/NinjaAttack/NinjaAttack-ALEaA.ttf"
)

const MOVE_CARD_ASSET_ROOT: String = "res://assets/move_cards"
const FALLBACK_CARD_PATH: String = (
    MOVE_CARD_ASSET_ROOT + "/background.png"
)


var move_card: Variant = null
var _hover_popup: Popup = null
var _hover_popup_card: Control = null
var _hover_request_serial: int = 0
var _availability_label: Label = null
var _card_content_root: Control = null
var _battle_damage_text: String = "-"
var _battle_coverage_text: String = "-"
var _is_large_preview: bool = false
var _web_info_popup: PopupPanel = null
var _web_popup_allow_use: bool = false
var _battle_usable: bool = true
var _battle_unavailable_reason: String = ""
var _hover_preview_enabled: bool = true

signal web_move_use_requested(move_card_id: StringName)

const BATTLE_HOVER_DELAY_SECONDS: float = 0.35
const BATTLE_HOVER_LAYOUT_DEBUG: bool = false


func set_move_card(
    value: Variant
) -> void:
    move_card = value
    tooltip_text = ""

    # Web uses click/tap popups only. Do not connect hover preview signals,
    # otherwise a mouse click can leave both the hover and click popups open.
    if OS.has_feature("web"):
        _hover_request_serial += 1
        _hide_manual_battle_hover_popup()
        return

    if not _hover_preview_enabled:
        return

    if not mouse_entered.is_connected(
        _on_battle_hover_entered
    ):
        mouse_entered.connect(
            _on_battle_hover_entered
        )

    if not mouse_exited.is_connected(
        _on_battle_hover_exited
    ):
        mouse_exited.connect(
            _on_battle_hover_exited
        )


func set_hover_preview_enabled(enabled: bool) -> void:
    _hover_preview_enabled = enabled
    var enter_callable := Callable(self, "_on_battle_hover_entered")
    var exit_callable := Callable(self, "_on_battle_hover_exited")
    if not enabled:
        _hover_request_serial += 1
        _hide_manual_battle_hover_popup()
        if mouse_entered.is_connected(enter_callable):
            mouse_entered.disconnect(enter_callable)
        if mouse_exited.is_connected(exit_callable):
            mouse_exited.disconnect(exit_callable)
    elif not OS.has_feature("web"):
        if not mouse_entered.is_connected(enter_callable):
            mouse_entered.connect(enter_callable)
        if not mouse_exited.is_connected(exit_callable):
            mouse_exited.connect(exit_callable)


func setup_battle_summary(
    value: Variant,
    damage_text: String,
    coverage_text: String
) -> void:
    _battle_damage_text = damage_text
    _battle_coverage_text = coverage_text
    set_move_card(
        value
    )

    text = ""

    for child: Node in get_children():
        child.queue_free()

    var card_template := load(FALLBACK_CARD_PATH) as Texture2D
    if card_template != null:
        _setup_generated_card_summary(
            card_template,
            damage_text,
            coverage_text
        )
        return

    var box: VBoxContainer = VBoxContainer.new()
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT,
        Control.PRESET_MODE_MINSIZE,
        8
    )
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override(
        "separation",
        4
    )
    add_child(
        box
    )

    var title: Label = Label.new()
    title.text = GameContentLocalizationService.localize_move(
        move_card
    )
    title.horizontal_alignment = (
        HORIZONTAL_ALIGNMENT_CENTER
    )
    title.add_theme_font_size_override(
        "font_size",
        22
    )
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(
        title
    )

    var stat_row: HBoxContainer = HBoxContainer.new()
    stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
    stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stat_row.add_theme_constant_override(
        "separation",
        8
    )
    box.add_child(
        stat_row
    )

    var cost_row: HBoxContainer = HBoxContainer.new()
    cost_row.set_script(
        MOVE_ENERGY_COST_ROW
    )
    cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cost_row.setup(
        move_card,
        26
    )
    stat_row.add_child(
        cost_row
    )

    var damage_label: Label = Label.new()
    damage_label.text = LocalizationService.tr_format(
        "battle.move_damage_short",
        {"damage": damage_text},
        "DMG {damage}"
    )
    damage_label.add_theme_font_size_override(
        "font_size",
        17
    )
    damage_label.add_theme_font_override("font", NINJA_ATTACK_FONT)
    damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stat_row.add_child(
        damage_label
    )

    _availability_label = Label.new()
    _availability_label.name = "MoveAvailabilityLabel"
    _availability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _availability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _availability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _availability_label.max_lines_visible = 2
    _availability_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _availability_label.add_theme_font_size_override(
        "font_size",
        15
    )
    _availability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _availability_label.text = LocalizationService.tr_format(
        "battle.move_success",
        {"coverage": coverage_text},
        "[OK] Success {coverage}"
    )
    _availability_label.modulate.a = 0.88
    box.add_child(_availability_label)


func setup_large_card_preview(
    value: Variant,
    damage_text: String,
    coverage_text: String
) -> void:
    _is_large_preview = true
    move_card = value
    text = ""
    tooltip_text = ""
    focus_mode = Control.FOCUS_NONE
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    for child: Node in get_children():
        child.queue_free()

    var card_template := load(FALLBACK_CARD_PATH) as Texture2D
    if card_template != null:
        _setup_generated_card_summary(
            card_template,
            damage_text,
            coverage_text
        )


func _setup_generated_card_summary(
    template: Texture2D,
    damage_text: String,
    coverage_text: String
) -> void:
    var compact: bool = custom_minimum_size.x < 220.0
    var large: bool = custom_minimum_size.x >= 500.0
    var phone_card: bool = GameFlow.phone_mode and not large
    if phone_card:
        custom_minimum_size.y = get_phone_recommended_height()

    _card_content_root = Control.new()
    _card_content_root.name = "GeneratedMoveCard"
    _card_content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _card_content_root.clip_contents = true
    _card_content_root.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    _card_content_root.offset_left = 5.0
    _card_content_root.offset_top = 5.0
    _card_content_root.offset_right = -5.0
    _card_content_root.offset_bottom = -31.0
    add_child(_card_content_root)

    var background := TextureRect.new()
    background.name = "MoveCardBackground"
    background.texture = template
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_SCALE
    background.modulate = _attack_type_card_color(
        StringName(move_card.attack_type)
    )
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _card_content_root.add_child(background)

    var sheen := ColorRect.new()
    sheen.name = "CardSheen"
    sheen.color = Color(1.0, 1.0, 1.0, 0.10)
    sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    sheen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    sheen.anchor_bottom = 0.49
    _card_content_root.add_child(sheen)

    _add_card_icon(
        _card_content_root,
        ICONS.load_energy_icon(StringName(move_card.attack_type)),
        Vector4(0.025, 0.05, 0.145, 0.34)
    )

    var owner_id: String = String(move_card.owner_id)
    var owner_name: String = GameContentLocalizationService.text(
        "pokemon",
        owner_id,
        "name",
        owner_id.replace("_", " ").capitalize()
    )
    _add_card_label(
        _card_content_root,
        owner_name,
        Vector4(0.16, 0.035, 0.68, 0.17),
        18 if large else (9 if compact else 10),
        HORIZONTAL_ALIGNMENT_LEFT,
        Color.WHITE
    )
    var move_name_label: Label = _add_card_label(
        _card_content_root,
        GameContentLocalizationService.localize_move(move_card),
        Vector4(0.14, 0.15, 0.80, 0.43),
        34 if large else (24 if phone_card else (20 if compact else 24)),
        HORIZONTAL_ALIGNMENT_CENTER,
        Color.WHITE,
        5 if large else 3,
        Color(0.02, 0.03, 0.05, 0.98)
    )
    move_name_label.name = "MoveName"
    var damage_label: Label = _add_card_label(
        _card_content_root,
        damage_text,
        Vector4(0.80, 0.13, 0.97, 0.43),
        38 if large else (19 if compact else 23),
        HORIZONTAL_ALIGNMENT_CENTER,
        Color(1.0, 0.25, 0.20),
        5 if large else 3,
        Color.WHITE
    )
    damage_label.name = "MoveDamage"
    damage_label.add_theme_font_override("font", NINJA_ATTACK_FONT)

    _add_energy_cost_icons(_card_content_root, compact, large)
    _add_effect_rows(_card_content_root, compact, large, phone_card)

    var card_code: String = String(
        move_card.source.get("card_code", "")
    ).strip_edges()
    if not card_code.is_empty():
        _add_card_label(
            _card_content_root,
            card_code,
            Vector4(0.76, 0.87, 0.96, 0.98),
            11 if large else 7,
            HORIZONTAL_ALIGNMENT_RIGHT,
            Color(0.84, 0.87, 0.92, 0.85)
        )

    var status_panel := PanelContainer.new()
    status_panel.name = "MoveCardStatus"
    status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    status_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    status_panel.offset_left = 9.0
    status_panel.offset_top = -28.0
    status_panel.offset_right = -9.0
    status_panel.offset_bottom = -5.0

    var status_style := StyleBoxFlat.new()
    status_style.bg_color = Color(0.06, 0.08, 0.13, 0.88)
    status_style.border_color = Color(1.0, 1.0, 1.0, 0.48)
    status_style.set_border_width_all(1)
    status_style.set_corner_radius_all(7)
    status_style.content_margin_left = 6.0
    status_style.content_margin_right = 6.0
    status_style.content_margin_top = 2.0
    status_style.content_margin_bottom = 2.0
    status_panel.add_theme_stylebox_override("panel", status_style)
    add_child(status_panel)

    _availability_label = Label.new()
    _availability_label.name = "MoveAvailabilityLabel"
    _availability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _availability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _availability_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    _availability_label.add_theme_font_size_override("font_size", 12)
    _availability_label.add_theme_color_override("font_color", Color.WHITE)
    _availability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _availability_label.text = LocalizationService.tr_format(
        "battle.move_success",
        {"coverage": coverage_text},
        "[OK] Success {coverage}"
    )
    status_panel.add_child(_availability_label)


func set_web_popup_allow_use(enabled: bool) -> void:
    _web_popup_allow_use = enabled


func _open_web_move_info_popup() -> void:
    # Defensive cleanup: Web must have exactly one move popup.
    _hover_request_serial += 1
    _hide_manual_battle_hover_popup()
    if move_card == null:
        return
    if _web_info_popup != null and is_instance_valid(_web_info_popup):
        _web_info_popup.queue_free()
        _web_info_popup = null

    var viewport_size: Vector2 = get_viewport_rect().size
    var max_card_width: float = maxf(320.0, viewport_size.x - 40.0)
    var max_by_height: float = maxf(320.0, (viewport_size.y - 120.0) * 2.0)
    var card_width: float = minf(760.0, minf(max_card_width, max_by_height))
    var card_height: float = card_width * 0.5 + 31.0

    var popup := PopupPanel.new()
    popup.name = "WebMoveInfoPopup"
    popup.exclusive = true
    popup.transparent_bg = false
    add_child(popup)
    _web_info_popup = popup
    popup.popup_hide.connect(_on_web_info_popup_hidden)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    popup.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    margin.add_child(box)

    var preview := Button.new()
    preview.name = "MoveInfoPreview"
    preview.set_script(get_script())
    preview.custom_minimum_size = Vector2(card_width, card_height)
    preview.size = Vector2(card_width, card_height)
    preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview.focus_mode = Control.FOCUS_NONE
    box.add_child(preview)
    preview.setup_large_card_preview(
        move_card,
        _battle_damage_text,
        _battle_coverage_text
    )

    var action_row := HBoxContainer.new()
    action_row.alignment = BoxContainer.ALIGNMENT_CENTER
    action_row.add_theme_constant_override("separation", 12)
    box.add_child(action_row)

    var close_button := Button.new()
    close_button.text = LocalizationService.tr_key(
        "common.close",
        "Close"
    )
    close_button.custom_minimum_size = Vector2(160.0, 50.0)
    close_button.pressed.connect(popup.hide)
    action_row.add_child(close_button)

    if _web_popup_allow_use:
        var use_button := Button.new()
        use_button.text = LocalizationService.tr_key(
            "common.use",
            "Use"
        )
        use_button.custom_minimum_size = Vector2(160.0, 50.0)
        use_button.disabled = not _battle_usable
        if not _battle_usable and not _battle_unavailable_reason.is_empty():
            use_button.tooltip_text = _battle_unavailable_reason
        use_button.pressed.connect(_on_web_popup_use_pressed)
        action_row.add_child(use_button)

    popup.popup_centered(
        Vector2i(
            int(card_width + 20.0),
            int(card_height + 88.0)
        )
    )


func _on_web_popup_use_pressed() -> void:
    if not _battle_usable or move_card == null:
        return
    if _web_info_popup != null and is_instance_valid(_web_info_popup):
        _web_info_popup.hide()
    web_move_use_requested.emit(StringName(move_card.id))


func _on_web_info_popup_hidden() -> void:
    if _web_info_popup != null and is_instance_valid(_web_info_popup):
        _web_info_popup.queue_free()
    _web_info_popup = null


func _add_card_label(
    parent: Control,
    value: String,
    anchors: Vector4,
    font_size: int,
    alignment: HorizontalAlignment,
    color: Color,
    outline_size: int = 1,
    outline_color: Color = Color(0.02, 0.03, 0.05, 0.95),
    wrap: bool = false,
    max_lines: int = 1
) -> Label:
    var label := Label.new()
    label.text = value
    label.horizontal_alignment = alignment
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", outline_color)
    label.add_theme_constant_override("outline_size", outline_size)
    label.autowrap_mode = (
        TextServer.AUTOWRAP_WORD_SMART
        if wrap
        else TextServer.AUTOWRAP_OFF
    )
    label.max_lines_visible = max_lines
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    _set_fractional_rect(label, anchors)
    parent.add_child(label)
    return label


func _add_card_icon(
    parent: Control,
    texture: Texture2D,
    anchors: Vector4
) -> TextureRect:
    var icon := TextureRect.new()
    icon.texture = texture
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _set_fractional_rect(icon, anchors)
    parent.add_child(icon)
    return icon


func _set_fractional_rect(control: Control, anchors: Vector4) -> void:
    control.anchor_left = anchors.x
    control.anchor_top = anchors.y
    control.anchor_right = anchors.z
    control.anchor_bottom = anchors.w
    control.offset_left = 0.0
    control.offset_top = 0.0
    control.offset_right = 0.0
    control.offset_bottom = 0.0


func _add_energy_cost_icons(
    parent: Control,
    compact: bool,
    large: bool
) -> void:
    var costs := HBoxContainer.new()
    costs.name = "EnergyCosts"
    costs.alignment = BoxContainer.ALIGNMENT_END
    costs.mouse_filter = Control.MOUSE_FILTER_IGNORE
    costs.add_theme_constant_override("separation", 1)

    # Energy cost icons must reflect the real move cost. Older Web cards
    # capped each energy type at four icons, which made 5-Energy moves look
    # cheaper than they actually are. Give high-cost rows a little more room
    # and render every required Energy icon.
    var total_energy_icons: int = 0
    for raw_cost: Variant in move_card.energy_costs:
        if raw_cost != null:
            total_energy_icons += maxi(0, int(raw_cost.count))

    var cost_left_anchor: float = 0.60
    if total_energy_icons >= 5:
        cost_left_anchor = 0.52
    if total_energy_icons >= 7:
        cost_left_anchor = 0.44

    _set_fractional_rect(
        costs,
        Vector4(cost_left_anchor, 0.02, 0.97, 0.17)
    )
    parent.add_child(costs)

    for raw_cost: Variant in move_card.energy_costs:
        if raw_cost == null:
            continue
        var count: int = maxi(1, int(raw_cost.count))
        for _index: int in range(count):
            var icon := TextureRect.new()
            icon.texture = ICONS.load_energy_icon(
                StringName(raw_cost.energy_type)
            )
            var icon_size: float = (
                30.0 if large else (13.0 if compact else 16.0)
            )
            if total_energy_icons >= 7:
                icon_size = 24.0 if large else (11.0 if compact else 14.0)
            icon.custom_minimum_size = Vector2(
                icon_size,
                icon_size
            )
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
            costs.add_child(icon)


func _add_effect_rows(
    parent: Control,
    compact: bool,
    large: bool,
    phone_card: bool = false
) -> void:
    var preview: Dictionary = EFFECT_PRESENTATION.build_preview(move_card)
    var move_effect_lines: Array = preview.get("move_effect_lines", [])
    var trigger_groups: Array = preview.get("trigger_groups", [])
    var effects := VBoxContainer.new()
    effects.name = "CardEffectGroups"
    effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
    effects.add_theme_constant_override(
        "separation",
        4 if large else (0 if phone_card else 1)
    )
    _set_fractional_rect(
        effects,
        Vector4(0.025, 0.46, 0.965, 0.96)
        if phone_card
        else Vector4(0.025, 0.52, 0.965, 0.92)
    )
    parent.add_child(effects)

    for move_effect_index: int in range(move_effect_lines.size()):
        var move_effect_text: String = (
            GameContentLocalizationService.localize_move_effect_text(
                move_card,
                move_effect_index,
                String(move_effect_lines[move_effect_index])
            )
        ).strip_edges()
        if move_effect_text.is_empty():
            continue
        var move_effect_label := Label.new()
        move_effect_label.name = "MoveEffect%d" % (move_effect_index + 1)
        move_effect_label.text = move_effect_text
        _style_effect_label(
            move_effect_label,
            compact,
            large,
            4 if phone_card else 2,
            phone_card
        )
        if phone_card:
            move_effect_label.text_overrun_behavior = (
                TextServer.OVERRUN_NO_TRIMMING
            )
        var move_effect_color: Color = _attack_type_card_color(
            StringName(move_card.attack_type)
        )
        move_effect_label.add_theme_color_override(
            "font_color",
            _solid_energy_text_color(move_effect_color)
        )
        move_effect_label.add_theme_font_size_override(
            "font_size",
            20 if large else (15 if phone_card else (13 if compact else 15))
        )
        move_effect_label.add_theme_color_override(
            "font_outline_color",
            _solid_energy_outline_color(move_effect_color)
        )
        move_effect_label.add_theme_constant_override("outline_size", 2)

        var move_effect_panel := PanelContainer.new()
        move_effect_panel.name = (
            "MoveEffectPanel%d" % (move_effect_index + 1)
        )
        move_effect_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var move_effect_style := StyleBoxFlat.new()
        move_effect_style.bg_color = move_effect_color
        move_effect_style.set_content_margin_all(2.0)
        move_effect_style.content_margin_left = 5.0
        move_effect_style.content_margin_right = 5.0
        move_effect_panel.add_theme_stylebox_override(
            "panel",
            move_effect_style
        )
        move_effect_panel.add_child(move_effect_label)
        effects.add_child(move_effect_panel)

    if trigger_groups.is_empty() and move_effect_lines.is_empty():
        var description := Label.new()
        description.text = (
            GameContentLocalizationService.localize_move_description(
                move_card
            )
        ).strip_edges()
        if description.text.is_empty():
            description.text = String(preview.get("detail", ""))
        _style_effect_label(description, compact, large, 4, phone_card)
        effects.add_child(description)
        return

    var group_count: int = trigger_groups.size()
    for index: int in range(group_count):
        var raw_group: Variant = trigger_groups[index]
        if not raw_group is Dictionary:
            continue
        var group: Dictionary = raw_group as Dictionary
        var row := HBoxContainer.new()
        row.name = "EffectGroup%d" % (index + 1)
        row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.size_flags_vertical = Control.SIZE_EXPAND_FILL
        row.add_theme_constant_override(
            "separation",
            12 if large else 3
        )
        effects.add_child(row)

        var icons := GridContainer.new()
        icons.name = "EffectFaces"
        icons.columns = 3
        icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
        icons.custom_minimum_size.x = (
            102.0 if large else (58.0 if phone_card else 47.0)
        )
        icons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        icons.add_theme_constant_override("h_separation", 2 if large else 1)
        icons.add_theme_constant_override(
            "v_separation",
            2 if large else (0 if phone_card else 1)
        )
        row.add_child(icons)

        var orientations: Array = group.get("orientations", [])
        for raw_orientation: Variant in orientations.slice(0, 6):
            var icon := TextureRect.new()
            icon.texture = ICONS.load_kyokoro_icon(
                StringName(raw_orientation)
            )
            icon.custom_minimum_size = (
                Vector2(30.0, 30.0)
                if large
                else (
                    Vector2(18.0, 18.0)
                    if phone_card
                    else Vector2(
                        16.0 if compact else 18.0,
                        16.0 if compact else 18.0
                    )
                )
            )
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
            icons.add_child(icon)

        var effect_text: String = (
            GameContentLocalizationService.localize_effect_text(
                move_card,
                index,
                String(group.get("effect_text", ""))
            )
        ).strip_edges()
        var effect_label := Label.new()
        effect_label.text = effect_text
        _style_effect_label(
            effect_label,
            compact,
            large,
            2 if group_count > 1 else 3,
            phone_card
        )
        effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(effect_label)


func _style_effect_label(
    label: Label,
    compact: bool,
    large: bool,
    max_lines: int,
    phone_card: bool = false
) -> void:
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.max_lines_visible = max_lines
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    label.add_theme_font_size_override(
        "font_size",
        17 if large else (15 if phone_card else (12 if compact else 15))
    )
    if phone_card:
        label.add_theme_constant_override("line_spacing", -3)
    label.add_theme_color_override("font_color", Color.WHITE)
    label.add_theme_color_override(
        "font_outline_color",
        Color(0.02, 0.03, 0.05, 0.95)
    )
    label.add_theme_constant_override("outline_size", 1)


func _attack_type_card_color(attack_type: StringName) -> Color:
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
            return Color("397983")
        &"steel":
            return Color("8995aa")
        &"flying":
            return Color("62b9cf")
        _:
            return Color("a8a8a8")


func _solid_energy_text_color(background: Color) -> Color:
    var luminance: float = (
        background.r * 0.299
        + background.g * 0.587
        + background.b * 0.114
    )
    return Color("10182b") if luminance >= 0.48 else Color.WHITE


func _solid_energy_outline_color(background: Color) -> Color:
    var text_color: Color = _solid_energy_text_color(background)
    if text_color == Color.WHITE:
        return Color(0.02, 0.03, 0.05, 0.95)
    return Color(1.0, 1.0, 1.0, 0.72)


func get_phone_recommended_height() -> float:
    if move_card == null:
        return 150.0
    var move_effects: Variant = move_card.source.get("move_effect_text", [])
    if move_effects is Array and not move_effects.is_empty():
        return 190.0
    return 150.0



func set_battle_availability(
    usable: bool,
    reason: String,
    coverage_text: String
) -> void:
    _battle_usable = usable
    _battle_unavailable_reason = reason
    if _availability_label == null:
        return

    if usable:
        _availability_label.text = LocalizationService.tr_format(
            "battle.move_available",
            {"coverage": coverage_text},
            "[OK] Available  |  Success {coverage}"
        )
        _availability_label.modulate = Color(0.72, 1.0, 0.78, 0.95)
        if _card_content_root != null:
            _card_content_root.modulate = Color.WHITE
    else:
        _availability_label.text = (
            "X"
            + (" " + reason if not reason.is_empty() else "")
        )
        _availability_label.modulate = Color(1.0, 0.68, 0.68, 0.95)
        if _card_content_root != null:
            _card_content_root.modulate = Color(0.56, 0.56, 0.56, 0.82)


func _on_battle_hover_entered() -> void:
    if OS.has_feature("web"):
        _hover_request_serial += 1
        _hide_manual_battle_hover_popup()
        return
    if move_card == null:
        return

    _hover_request_serial += 1
    var request_serial: int = _hover_request_serial

    await get_tree().create_timer(
        BATTLE_HOVER_DELAY_SECONDS
    ).timeout

    if (
        request_serial != _hover_request_serial
        or not is_hovered()
        or move_card == null
    ):
        return

    await _show_manual_battle_hover_popup()


func _on_battle_hover_exited() -> void:
    if OS.has_feature("web"):
        _hover_request_serial += 1
        _hide_manual_battle_hover_popup()
        return
    _hover_request_serial += 1
    _hide_manual_battle_hover_popup()


func _show_manual_battle_hover_popup() -> void:
    if OS.has_feature("web"):
        _hide_manual_battle_hover_popup()
        return
    _hide_manual_battle_hover_popup()

    var screen_size: Vector2i = DisplayServer.screen_get_size()
    var popup_width: float = minf(
        680.0,
        maxf(460.0, float(screen_size.x) - 48.0)
    )
    var popup_size := Vector2(
        popup_width,
        popup_width * 0.5 + 31.0
    )

    _hover_popup = Popup.new()
    _hover_popup.name = "BattleMoveCardPopup"
    _hover_popup.transparent_bg = true
    _hover_popup.borderless = true
    add_child(_hover_popup)

    var preview_card := Button.new()
    preview_card.name = "LargeMoveCardPreview"
    preview_card.set_script(get_script())
    preview_card.custom_minimum_size = popup_size
    preview_card.size = popup_size
    preview_card.position = Vector2.ZERO
    preview_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview_card.focus_mode = Control.FOCUS_NONE
    _hover_popup.add_child(preview_card)
    _hover_popup_card = preview_card

    preview_card.setup_large_card_preview(
        move_card,
        _battle_damage_text,
        _battle_coverage_text
    )

    var popup_position: Vector2 = _calculate_hover_position(
        get_screen_position(),
        popup_size,
        screen_size
    )
    _hover_popup.popup(
        Rect2i(
            Vector2i(popup_position),
            Vector2i(popup_size)
        )
    )


func _show_legacy_battle_hover_popup() -> void:
    _hide_manual_battle_hover_popup()

    var preview: Dictionary = (
        EFFECT_PRESENTATION.build_preview(
            move_card
        )
    )
    var move_data: Dictionary = (
        _build_presentation_move_data(
            move_card
        )
    )
    var move_name_id: String = String(
        move_card.move_name_id
    )
    move_data["display_name"] = GameContentLocalizationService.localize_move(
        move_card
    )
    if move_data.has("attack_type"):
        move_data["attack_type"] = GameContentLocalizationService.localize_type(
            move_data["attack_type"]
        )

    var localized_trigger_groups: Array = []
    var raw_trigger_groups: Array = preview.get(
        "trigger_groups",
        []
    )
    for index: int in range(raw_trigger_groups.size()):
        var raw_group: Variant = raw_trigger_groups[index]
        if not raw_group is Dictionary:
            continue
        var localized_group: Dictionary = (
            raw_group as Dictionary
        ).duplicate(true)
        localized_group["effect_text"] = (
            GameContentLocalizationService.localize_effect_text(
                move_card,
                index,
                String(
                    localized_group.get(
                        "effect_text",
                        ""
                    )
                )
            )
        )
        localized_trigger_groups.append(localized_group)

    var localized_detail: String = (
        GameContentLocalizationService.localize_move_description(
            move_card
        )
    )
    if localized_detail.is_empty():
        localized_detail = String(
            preview.get(
                "detail",
                ""
            )
        )

    _hover_popup = Popup.new()
    _hover_popup.name = "BattleMoveHoverPopup"
    _hover_popup.transparent_bg = true
    _hover_popup.borderless = true
    add_child(
        _hover_popup
    )

    _hover_popup_card = PanelContainer.new()
    _hover_popup_card.name = "BattleMoveHoverCard"
    _hover_popup_card.set_script(
        POPUP_SCRIPT
    )
    _hover_popup_card.set_anchors_preset(
        Control.PRESET_TOP_LEFT
    )
    _hover_popup_card.size_flags_horizontal = (
        Control.SIZE_SHRINK_BEGIN
    )
    _hover_popup_card.size_flags_vertical = (
        Control.SIZE_SHRINK_BEGIN
    )

    # Keep the visible card fully transparent during the first layout frame.
    # The Control still participates in Container layout while alpha = 0.
    _hover_popup_card.modulate.a = 0.0

    _hover_popup.add_child(
        _hover_popup_card
    )

    var estimated_size: Vector2 = (
        _hover_popup_card.setup_battle_popup_move(
            String(
                move_data.get(
                    "id",
                    move_card.id
                )
            ),
            move_data,
            localized_trigger_groups,
            localized_detail
        )
    )

    if (
        _hover_popup == null
        or not is_instance_valid(
            _hover_popup
        )
        or _hover_popup_card == null
        or not is_instance_valid(
            _hover_popup_card
        )
    ):
        return

    var screen_size: Vector2i = DisplayServer.screen_get_size()
    var anchor_position: Vector2 = get_screen_position()

    # First position is based on the estimate. It is invisible, so minor
    # adjustment after exact measurement cannot flash on-screen.
    var first_position: Vector2 = _calculate_hover_position(
        anchor_position,
        estimated_size,
        screen_size
    )

    _hover_popup_card.position = Vector2.ZERO
    _hover_popup_card.size = estimated_size

    _hover_popup.popup(
        Rect2i(
            Vector2i(
                first_position
            ),
            Vector2i(
                estimated_size
            )
        )
    )

    # Critical: once the popup Window has a real width, Godot can correctly
    # calculate autowrapped Label heights. The diagnostic build showed the
    # VBox minimum falling from ~1620 px to ~190 px after this layout pass.
    await get_tree().process_frame
    await get_tree().process_frame

    if (
        _hover_popup == null
        or not is_instance_valid(
            _hover_popup
        )
        or _hover_popup_card == null
        or not is_instance_valid(
            _hover_popup_card
        )
    ):
        return

    var actual_size: Vector2 = (
        _hover_popup_card.get_content_fitted_size()
    )
    var final_position: Vector2 = _calculate_hover_position(
        anchor_position,
        actual_size,
        screen_size
    )

    _hover_popup.size = Vector2i(
        actual_size
    )
    _hover_popup.position = Vector2i(
        final_position
    )

    _hover_popup_card.position = Vector2.ZERO
    _hover_popup_card.custom_minimum_size = actual_size
    _hover_popup_card.size = actual_size

    # Reveal only after both size and position are final.
    _hover_popup_card.modulate.a = 1.0


func _calculate_hover_position(
    anchor_position: Vector2,
    hover_size: Vector2,
    screen_size: Vector2i
) -> Vector2:
    var desired_position: Vector2 = Vector2(
        anchor_position.x + size.x + 10.0,
        anchor_position.y
    )

    if (
        desired_position.x + hover_size.x
        > float(screen_size.x) - 12.0
    ):
        desired_position.x = max(
            12.0,
            anchor_position.x
            - hover_size.x
            - 10.0
        )

    if (
        desired_position.y + hover_size.y
        > float(screen_size.y) - 12.0
    ):
        desired_position.y = max(
            12.0,
            float(screen_size.y)
            - hover_size.y
            - 12.0
        )

    return desired_position


func _debug_hover_layout(
    stage: String
) -> void:
    if not BATTLE_HOVER_LAYOUT_DEBUG:
        return

    var popup_valid: bool = (
        _hover_popup != null
        and is_instance_valid(
            _hover_popup
        )
    )
    var card_valid: bool = (
        _hover_popup_card != null
        and is_instance_valid(
            _hover_popup_card
        )
    )

    var popup_size: Vector2i = Vector2i.ZERO
    var popup_position: Vector2i = Vector2i.ZERO
    var popup_visible: bool = false

    if popup_valid:
        popup_size = _hover_popup.size
        popup_position = _hover_popup.position
        popup_visible = _hover_popup.visible

    var card_snapshot: Dictionary = {}

    if card_valid:
        card_snapshot = (
            _hover_popup_card.debug_layout_snapshot(
                stage
            )
        )

    print("")
    print(
        "[HOVER_LAYOUT_DEBUG] "
        + stage
    )
    print(
        "  popup.valid="
        + str(popup_valid)
        + " visible="
        + str(popup_visible)
        + " position="
        + str(popup_position)
        + " size="
        + str(popup_size)
    )

    if card_valid:
        print(
            "  card.size="
            + str(
                card_snapshot.get(
                    "size",
                    Vector2.ZERO
                )
            )
            + " custom_min="
            + str(
                card_snapshot.get(
                    "custom_minimum_size",
                    Vector2.ZERO
                )
            )
            + " combined_min="
            + str(
                card_snapshot.get(
                    "combined_minimum_size",
                    Vector2.ZERO
                )
            )
        )
        print(
            "  card.anchors="
            + str(
                card_snapshot.get(
                    "anchors",
                    Vector4.ZERO
                )
            )
            + " offsets="
            + str(
                card_snapshot.get(
                    "offsets",
                    Vector4.ZERO
                )
            )
            + " flags="
            + str(
                card_snapshot.get(
                    "size_flags_horizontal",
                    -1
                )
            )
            + "/"
            + str(
                card_snapshot.get(
                    "size_flags_vertical",
                    -1
                )
            )
        )
        print(
            "  child.class="
            + str(
                card_snapshot.get(
                    "first_child_class",
                    "(none)"
                )
            )
            + " size="
            + str(
                card_snapshot.get(
                    "first_child_size",
                    Vector2.ZERO
                )
            )
            + " custom_min="
            + str(
                card_snapshot.get(
                    "first_child_custom_minimum",
                    Vector2.ZERO
                )
            )
            + " combined_min="
            + str(
                card_snapshot.get(
                    "first_child_combined_minimum",
                    Vector2.ZERO
                )
            )
            + " flags="
            + str(
                card_snapshot.get(
                    "first_child_flags_horizontal",
                    -1
                )
            )
            + "/"
            + str(
                card_snapshot.get(
                    "first_child_flags_vertical",
                    -1
                )
            )
        )


func _hide_manual_battle_hover_popup() -> void:
    if (
        _hover_popup != null
        and is_instance_valid(
            _hover_popup
        )
    ):
        _hover_popup.queue_free()

    _hover_popup = null
    _hover_popup_card = null


func _build_presentation_move_data(
    card: Variant
) -> Dictionary:
    var energy_cost: Array[Dictionary] = []

    for raw_cost: Variant in card.energy_costs:
        if raw_cost == null:
            continue

        energy_cost.append(
            {
                "energy_type": String(
                    raw_cost.energy_type
                ),
                "count": int(
                    raw_cost.count
                )
            }
        )

    return {
        "id": String(card.id),
        "move_name_id": String(
            card.move_name_id
        ),
        "owner_id": String(
            card.owner_id
        ),
        "display_name": String(
            card.display_name
        ),
        "move_category": String(
            card.move_category
        ),
        "attack_type": String(
            card.attack_type
        ),
        "energy_cost": energy_cost,
        "printed_damage": (
            card.printed_damage
        ),
        "base_actions": [],
        "special_effects": (
            card.special_effects
        ),
        "source": (
            card.source
        )
    }
