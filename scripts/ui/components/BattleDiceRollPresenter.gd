extends HBoxContainer


const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)
const THEME_FACTORY: Script = preload(
    "res://scripts/ui/theme/PlakoroThemeFactory.gd"
)

const ENERGY_TYPES: Array[StringName] = [
    &"grass",
    &"fire",
    &"water",
    &"electric",
    &"psychic",
    &"fighting",
    &"dark",
    &"steel",
    &"flying"
]

const ORIENTATIONS: Array[StringName] = [
    &"FACE_UP",
    &"FACE_DOWN",
    &"HEAD_UP",
    &"HEAD_DOWN",
    &"HEAD_LEFT",
    &"HEAD_RIGHT"
]

const ICON_SIZE: int = 62
const DOUBLE_ICON_SIZE: int = 42

const SLOT_IDLE_BACKGROUND: Color = Color(0.030, 0.040, 0.065, 0.96)
const SLOT_IDLE_BORDER: Color = Color(0.24, 0.33, 0.48, 0.88)
const SLOT_ROLLING_BACKGROUND: Color = Color(0.080, 0.065, 0.055, 0.98)
const SLOT_ROLLING_BORDER: Color = Color(1.0, 0.73, 0.24, 1.0)
const SLOT_LANDED_BACKGROUND: Color = Color(0.055, 0.085, 0.105, 1.0)
const SLOT_LANDED_BORDER: Color = Color(0.35, 0.86, 1.0, 1.0)


var _slot_panels: Array[PanelContainer] = []
var _icon_rows: Array[HBoxContainer] = []
var _labels: Array[Label] = []
var _slot_energy_colors: Array[Color] = []
var _slot_states: Array[StringName] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
    add_theme_constant_override(
        "separation",
        14
    )

    _rng.randomize()

    if _icon_rows.is_empty():
        _build_slots()


func _build_slots() -> void:
    for child: Node in get_children():
        child.queue_free()

    _slot_panels.clear()
    _icon_rows.clear()
    _labels.clear()
    _slot_energy_colors.clear()
    _slot_states.clear()

    for index: int in range(4):
        var panel: PanelContainer = PanelContainer.new()
        panel.custom_minimum_size = Vector2(
            104,
            108
        )
        panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        panel.add_theme_stylebox_override(
            "panel",
            _slot_style(
                _state_background(&"idle"),
                _state_border(&"idle"),
                1
            )
        )
        add_child(panel)
        _slot_panels.append(panel)

        var box: VBoxContainer = VBoxContainer.new()
        box.alignment = BoxContainer.ALIGNMENT_CENTER
        box.add_theme_constant_override(
            "separation",
            5
        )
        panel.add_child(box)

        var icon_row: HBoxContainer = HBoxContainer.new()
        icon_row.custom_minimum_size = Vector2(
            86,
            66
        )
        icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
        icon_row.add_theme_constant_override(
            "separation",
            3
        )
        box.add_child(icon_row)

        var label: Label = Label.new()
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.add_theme_font_size_override(
            "font_size",
            13
        )
        label.add_theme_color_override(
            "font_color",
            THEME_FACTORY.COLOR_TEXT_MUTED
        )
        label.text = (
            LocalizationService.tr_format(
            "battle.dice.energy_index",
            {"index": index + 1},
            "Energy {index}"
        )
            if index < 3
            else "Charakoro"
        )
        box.add_child(label)

        _icon_rows.append(icon_row)
        _labels.append(label)
        var slot_color: Color = Color(0.0, 0.0, 0.0, 0.0)
        if index < 3:
            slot_color = _element_background_color(
                StringName(THEME_FACTORY.get_enerkoro_color_type(index))
            )
        _slot_energy_colors.append(slot_color)
        _slot_states.append(&"idle")


func set_custom_slot_color_types(color_types: Array[String]) -> void:
    if _slot_panels.is_empty():
        _build_slots()
    for index: int in range(mini(3, color_types.size())):
        _slot_energy_colors[index] = _element_background_color(
            StringName(color_types[index])
        )
    for index: int in range(_slot_panels.size()):
        var state: StringName = &"idle"
        if index < _slot_states.size():
            state = _slot_states[index]
        _set_slot_visual(index, state)


func reset_display() -> void:
    if _icon_rows.is_empty():
        _build_slots()

    for index: int in range(
        _icon_rows.size()
    ):
        _clear_icon_row(
            _icon_rows[index]
        )

    for index: int in range(
        _slot_panels.size()
    ):
        _slot_panels[index].visible = true
        _reset_slot_transform(index)
        _set_slot_visual(index, &"idle")

    for index: int in range(
        _labels.size()
    ):
        _labels[index].text = (
            LocalizationService.tr_format(
            "battle.dice.energy_index",
            {"index": index + 1},
            "Energy {index}"
        )
            if index < 3
            else "Charakoro"
        )


func play_result(
    dice_result: Variant,
    energy_profiles: Array = [],
    roll_record: Variant = null
) -> void:
    if _icon_rows.is_empty():
        _build_slots()

    var final_dice: Array[Array] = (
        _resolve_final_energy_dice(
            dice_result,
            energy_profiles,
            roll_record
        )
    )

    var final_orientation: StringName = (
        _extract_orientation(
            dice_result
        )
    )

    var kyokoro_enabled: bool = (
        final_orientation != &""
    )

    var base_batch: Array[Array] = []
    var base_count: int = min(
        3,
        final_dice.size()
    )

    for index: int in range(base_count):
        base_batch.append(
            final_dice[index]
        )

    await _play_base_batch(
        base_batch,
        final_orientation,
        kyokoro_enabled
    )

    # Extra dice always animate after the base roll. A presentation batch
    # never shows more than three Enerkoro at once.
    var extra_cursor: int = 3

    while extra_cursor < final_dice.size():
        await get_tree().create_timer(
            0.20
        ).timeout

        var batch: Array[Array] = []
        var batch_end: int = min(
            extra_cursor + 3,
            final_dice.size()
        )

        for index: int in range(
            extra_cursor,
            batch_end
        ):
            batch.append(
                final_dice[index]
            )

        await _play_extra_batch(
            batch,
            extra_cursor - 2
        )

        extra_cursor = batch_end


func play_opponent_enerkoro_result(
    dice_result: Variant,
    energy_profiles: Array,
    roll_record: Variant
) -> void:
    if (
        dice_result == null
        or energy_profiles.is_empty()
    ):
        return

    if _icon_rows.is_empty():
        _build_slots()

    await get_tree().create_timer(
        0.20
    ).timeout

    var final_dice: Array[Array] = (
        _resolve_final_energy_dice(
            dice_result,
            energy_profiles,
            roll_record
        )
    )

    var batch: Array[Array] = []

    for index: int in range(
        min(
            3,
            final_dice.size()
        )
    ):
        batch.append(
            final_dice[index]
        )

    for index: int in range(3):
        _slot_panels[index].visible = (
            index < batch.size()
        )

    _slot_panels[3].visible = false

    await _animate_batch(
        batch,
        &"",
        [0.58, 0.88, 1.18, 0.0],
        [
            batch.size() > 0,
            batch.size() > 1,
            batch.size() > 2,
            false
        ],
        0
    )

    for index: int in range(
        min(
            3,
            batch.size()
        )
    ):
        _labels[index].text = (
            "Opponent Enerkoro "
            + str(
                index + 1
            )
        )


func play_opponent_kyokoro_roll(
    orientation: StringName
) -> void:
    if orientation == &"":
        return

    if _icon_rows.is_empty():
        _build_slots()

    await get_tree().create_timer(
        0.20
    ).timeout

    for index: int in range(3):
        _slot_panels[index].visible = false

    _slot_panels[3].visible = true

    await _animate_batch(
        [],
        orientation,
        [0.0, 0.0, 0.0, 0.90],
        [
            false,
            false,
            false,
            true
        ],
        0
    )

    _labels[3].text = (
        "Opponent Charakoro  |  "
        + String(
            orientation
        ).replace(
            "_",
            " "
        ).capitalize()
    )


func play_kyokoro_sequence(
    orientations: Array
) -> void:
    if orientations.is_empty():
        return

    if _icon_rows.is_empty():
        _build_slots()

    for raw_orientation: Variant in orientations:
        var orientation: StringName = StringName(
            raw_orientation
        )

        await get_tree().create_timer(
            0.18
        ).timeout

        for index: int in range(3):
            _slot_panels[index].visible = false

        _slot_panels[3].visible = true

        await _animate_batch(
            [],
            orientation,
            [0.0, 0.0, 0.0, 0.82],
            [
                false,
                false,
                false,
                true
            ],
            0
        )


func _play_base_batch(
    final_dice: Array[Array],
    final_orientation: StringName,
    kyokoro_enabled: bool = true
) -> void:
    for index: int in range(3):
        _slot_panels[index].visible = (
            index < final_dice.size()
        )

    _slot_panels[3].visible = true

    if not kyokoro_enabled:
        _clear_icon_row(
            _icon_rows[3]
        )
        _labels[3].text = (
            "Charakoro Disabled"
        )

    await _animate_batch(
        final_dice,
        final_orientation,
        [0.58, 0.88, 1.18, 1.55],
        [
            final_dice.size() > 0,
            final_dice.size() > 1,
            final_dice.size() > 2,
            kyokoro_enabled
        ],
        0
    )


func _play_extra_batch(
    final_dice: Array[Array],
    extra_number_start: int
) -> void:
    for index: int in range(3):
        _slot_panels[index].visible = (
            index < final_dice.size()
        )

    _slot_panels[3].visible = false

    await _animate_batch(
        final_dice,
        &"",
        [0.52, 0.78, 1.04, 0.0],
        [
            final_dice.size() > 0,
            final_dice.size() > 1,
            final_dice.size() > 2,
            false
        ],
        extra_number_start
    )


func _animate_batch(
    final_dice: Array[Array],
    final_orientation: StringName,
    stop_times: Array,
    active: Array,
    extra_number_start: int
) -> void:
    var elapsed: float = 0.0
    var next_flip: Array[float] = [
        0.0,
        0.0,
        0.0,
        0.0
    ]
    var stopped: Array[bool] = [
        not bool(active[0]),
        not bool(active[1]),
        not bool(active[2]),
        not bool(active[3])
    ]

    for index: int in range(4):
        if bool(active[index]):
            _set_slot_visual(index, &"rolling")
            _slot_panels[index].pivot_offset = (
                _slot_panels[index].size * 0.5
            )

    while not (
        stopped[0]
        and stopped[1]
        and stopped[2]
        and stopped[3]
    ):
        var delta: float = get_process_delta_time()

        if delta <= 0.0:
            delta = 0.016

        elapsed += delta

        for index: int in range(4):
            if stopped[index]:
                continue

            if elapsed >= float(stop_times[index]):
                if index < 3:
                    _set_energy_slot(
                        index,
                        final_dice[index]
                    )

                    if extra_number_start > 0:
                        _labels[index].text = (
                            "Extra "
                            + str(
                                extra_number_start + index
                            )
                            + "  |  "
                            + _labels[index].text
                        )
                else:
                    _set_orientation_slot(
                        index,
                        final_orientation
                    )

                stopped[index] = true
                _reset_slot_transform(index)
                _set_slot_visual(index, &"landed")
                _pulse_slot(index)
                continue

            var slot: PanelContainer = _slot_panels[index]
            slot.pivot_offset = slot.size * 0.5
            slot.rotation = sin(
                elapsed * 22.0 + float(index) * 1.7
            ) * 0.045
            var bounce: float = 1.0 + abs(
                sin(elapsed * 15.0 + float(index))
            ) * 0.035
            slot.scale = Vector2.ONE * bounce

            if elapsed >= next_flip[index]:
                var progress: float = clamp(
                    elapsed / float(stop_times[index]),
                    0.0,
                    1.0
                )
                var interval: float = lerp(
                    0.055,
                    0.20,
                    progress * progress
                )

                next_flip[index] = (
                    elapsed + interval
                )

                if index < 3:
                    _set_energy_slot(
                        index,
                        _random_energy_face()
                    )
                else:
                    _set_orientation_slot(
                        index,
                        ORIENTATIONS[
                            _rng.randi_range(
                                0,
                                ORIENTATIONS.size() - 1
                            )
                        ]
                    )

        await get_tree().process_frame


func _resolve_final_energy_dice(
    dice_result: Variant,
    energy_profiles: Array,
    roll_record: Variant
) -> Array[Array]:
    # Preferred path: DiceEngine history records the exact face ID rolled for
    # each die. StructuredEnergyDieProfile can map that face/orientation back
    # to its one- or two-energy result. This preserves the real per-die result.
    var exact: Array[Array] = (
        _extract_from_roll_record(
            energy_profiles,
            roll_record
        )
    )

    if not exact.is_empty():
        return exact

    # Compatibility path: DiceRollResultData exposes aggregate energy_counts.
    # If an exact roll record is unavailable (for example through a service
    # boundary), reconstruct three display slots deterministically so that
    # the icons always equal the ACTUAL aggregate result. Never use random
    # final Energy icons.
    return _build_slots_from_energy_counts(
        _extract_energy_counts(
            dice_result
        )
    )


func _extract_from_roll_record(
    energy_profiles: Array,
    roll_record: Variant
) -> Array[Array]:
    var result: Array[Array] = []

    if (
        roll_record == null
        or energy_profiles.is_empty()
    ):
        return result

    var raw_face_ids: Variant = _get_property(
        roll_record,
        &"energy_die_face_ids",
        null
    )

    if not raw_face_ids is Array:
        return result

    var face_ids: Array = raw_face_ids as Array

    for index: int in range(
        face_ids.size()
    ):
        var profile: Variant = energy_profiles[
            index % energy_profiles.size()
        ]

        if profile == null:
            return []

        var face_id: StringName = StringName(
            face_ids[index]
        )
        var face_result: Variant = null

        if profile.has_method(
            "get_face_result"
        ):
            face_result = profile.get_face_result(
                face_id
            )

        var energies: Array[StringName] = (
            _energies_from_face_result(
                face_result
            )
        )

        if energies.is_empty() and profile.has_method(
            "get_all_faces"
        ):
            for face: Variant in profile.get_all_faces():
                if StringName(
                    _get_property(
                        face,
                        &"id",
                        &""
                    )
                ) != face_id:
                    continue

                energies = _collect_known_energies(
                    _get_property(
                        face,
                        &"energies",
                        []
                    )
                )
                break

        if energies.is_empty():
            return []

        result.append(
            energies
        )

    return result


func _energies_from_face_result(
    face_result: Variant
) -> Array[StringName]:
    if face_result == null:
        return []

    if face_result is Dictionary:
        return _collect_known_energies(
            (face_result as Dictionary).get(
                "energies",
                []
            )
        )

    return _collect_known_energies(
        _get_property(
            face_result,
            &"energies",
            []
        )
    )


func _extract_energy_counts(
    dice_result: Variant
) -> Dictionary:
    var raw: Variant = _get_property(
        dice_result,
        &"energy_counts",
        {}
    )

    if raw is Dictionary:
        return (
            raw as Dictionary
        ).duplicate(true)

    return {}


func _build_slots_from_energy_counts(
    counts: Dictionary
) -> Array[Array]:
    var flattened: Array[StringName] = []

    # Stable energy order makes the fallback deterministic.
    for energy_type: StringName in ENERGY_TYPES:
        var count: int = int(
            counts.get(
                energy_type,
                counts.get(
                    String(energy_type),
                    0
                )
            )
        )

        for _copy: int in range(
            max(0, count)
        ):
            flattened.append(
                energy_type
            )

    # A normal three-die roll has 3-6 energy symbols because HEAD_UP and
    # HEAD_DOWN are double-energy faces. Distribute them across exactly three
    # visual die slots while preserving the aggregate counts.
    var slots: Array[Array] = [
        [],
        [],
        []
    ]

    if flattened.is_empty():
        return slots

    var remaining: int = flattened.size()
    var cursor: int = 0

    for slot_index: int in range(3):
        var slots_left: int = 3 - slot_index
        var take: int = 1

        if remaining > slots_left:
            take = 2

        for _item: int in range(take):
            if cursor >= flattened.size():
                break

            slots[slot_index].append(
                flattened[cursor]
            )
            cursor += 1
            remaining -= 1

    # In unusual modifier cases with more than six total symbols, keep the
    # first three dice readable while still avoiding invented Energy results.
    while cursor < flattened.size():
        slots[2].append(
            flattened[cursor]
        )
        cursor += 1

    return slots


func _set_energy_slot(
    index: int,
    energies: Array
) -> void:
    var icon_row: HBoxContainer = _icon_rows[index]
    _clear_icon_row(icon_row)

    var known: Array[StringName] = (
        _collect_known_energies(
            energies
        )
    )

    if known.is_empty():
        _labels[index].text = LocalizationService.tr_key(
            "battle.dice.no_energy",
            LocalizationService.tr_key(
            "battle.dice.no_energy",
            "No Energy"
        )
        )
        return

    var icon_size: int = (
        ICON_SIZE
        if known.size() == 1
        else DOUBLE_ICON_SIZE
    )

    for energy_type: StringName in known:
        var texture: Texture2D = (
            ICONS.load_energy_icon(
                energy_type
            )
        )

        var icon: TextureRect = TextureRect.new()
        icon.texture = texture
        icon.custom_minimum_size = Vector2(
            icon_size,
            icon_size
        )
        icon.expand_mode = (
            TextureRect.EXPAND_IGNORE_SIZE
        )
        icon.stretch_mode = (
            TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        )
        icon.tooltip_text = GameContentLocalizationService.localize_type(
            energy_type
        )
        icon_row.add_child(icon)

    var localized_energy_names: Array[String] = []
    for energy_type: StringName in known:
        localized_energy_names.append(
            GameContentLocalizationService.localize_type(
                energy_type
            )
        )
    _labels[index].text = " + ".join(
        localized_energy_names
    )


func _set_orientation_slot(
    index: int,
    orientation: StringName
) -> void:
    if index >= 0 and index < _slot_energy_colors.size():
        _slot_energy_colors[index] = Color(0.0, 0.0, 0.0, 0.0)
    var icon_row: HBoxContainer = _icon_rows[index]
    _clear_icon_row(icon_row)

    var texture: Texture2D = (
        ICONS.load_kyokoro_icon(
            orientation
        )
    )

    var icon: TextureRect = TextureRect.new()
    icon.texture = texture
    icon.custom_minimum_size = Vector2(
        ICON_SIZE,
        ICON_SIZE
    )
    icon.expand_mode = (
        TextureRect.EXPAND_IGNORE_SIZE
    )
    icon.stretch_mode = (
        TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    )
    icon.tooltip_text = LocalizationService.tr_key(
        "orientation." + String(orientation),
        String(orientation).replace("_", " ").capitalize()
    )
    icon_row.add_child(icon)

    _labels[index].text = LocalizationService.tr_key(
        "orientation." + String(orientation),
        String(orientation).replace("_", " ").capitalize()
    )


func _pulse_slot(
    index: int
) -> void:
    var panel: PanelContainer = _slot_panels[index]
    panel.pivot_offset = panel.size * 0.5
    panel.scale = Vector2(0.84, 0.84)

    var tween: Tween = create_tween()
    tween.tween_property(
        panel,
        "scale",
        Vector2.ONE,
        0.24
    ).set_trans(
        Tween.TRANS_BACK
    ).set_ease(
        Tween.EASE_OUT
    )


func _reset_slot_transform(index: int) -> void:
    if index < 0 or index >= _slot_panels.size():
        return
    _slot_panels[index].rotation = 0.0
    _slot_panels[index].scale = Vector2.ONE


func _set_slot_visual(index: int, state: StringName) -> void:
    if index < 0 or index >= _slot_panels.size():
        return

    if index < _slot_states.size():
        _slot_states[index] = state

    var background: Color = _state_background(&"idle")
    var border: Color = _state_border(&"idle")
    var border_width: int = 1
    var use_custom_color: bool = (
        index < 3
        and index < _slot_energy_colors.size()
        and _slot_energy_colors[index].a > 0.0
    )

    if use_custom_color:
        var custom: Color = _slot_energy_colors[index]
        if state == &"rolling":
            background = custom.lightened(0.05)
            border = SLOT_ROLLING_BORDER
            border_width = 2
        elif state == &"landed":
            background = custom
            border = custom.lightened(0.34)
            border_width = 2
        else:
            background = custom.darkened(0.10)
            border = custom.lightened(0.24)
    elif state == &"rolling":
        background = _state_background(&"rolling")
        border = _state_border(&"rolling")
        border_width = 2
    elif state == &"landed":
        background = _state_background(&"landed")
        border = _state_border(&"landed")
        border_width = 2

    if index < _labels.size():
        _labels[index].add_theme_color_override(
            "font_color",
            Color(0.97, 0.985, 1.0, 1.0)
            if use_custom_color
            else THEME_FACTORY.COLOR_TEXT_MUTED
        )

    _slot_panels[index].add_theme_stylebox_override(
        "panel",
        _slot_style(background, border, border_width)
    )


func _slot_style(
    background: Color,
    border: Color,
    border_width: int
) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(12)
    style.set_content_margin_all(8.0)
    style.shadow_color = Color(0.11, 0.15, 0.25, 0.45)
    style.shadow_size = 6
    return style


func _state_background(state: StringName) -> Color:
    # This presenter is part of the fixed Dark battle arena, even when the
    # surrounding application theme is Warm.
    if state == &"rolling":
        return SLOT_ROLLING_BACKGROUND
    if state == &"landed":
        return SLOT_LANDED_BACKGROUND
    return SLOT_IDLE_BACKGROUND


func _state_border(state: StringName) -> Color:
    if state == &"rolling":
        return SLOT_ROLLING_BORDER
    if state == &"landed":
        return SLOT_LANDED_BORDER
    return SLOT_IDLE_BORDER


func _blend_element_colors(energies: Array[StringName]) -> Color:
    if energies.is_empty():
        return Color(0.0, 0.0, 0.0, 0.0)

    var total := Vector3.ZERO
    var count: int = 0
    for energy_type: StringName in energies:
        var color: Color = _element_background_color(energy_type)
        if color.a <= 0.0:
            continue
        total += Vector3(color.r, color.g, color.b)
        count += 1

    if count <= 0:
        return Color(0.0, 0.0, 0.0, 0.0)

    var blended := total / float(count)
    return Color(blended.x, blended.y, blended.z, 0.98)


func _element_background_color(energy_type: StringName) -> Color:
    # Dark, saturated variants of the Energy colors keep white labels readable
    # while still making each landed die immediately identifiable.
    match energy_type:
        &"fire":
            return Color("7a2434")
        &"water":
            return Color("17517f")
        &"grass":
            return Color("265f3b")
        &"electric":
            return Color("6b5714")
        &"psychic":
            return Color("70275f")
        &"fighting":
            return Color("7b431f")
        &"dark":
            return Color("342a4f")
        &"steel":
            return Color("4f596b")
        &"flying":
            return Color("275b6b")
    return Color(0.0, 0.0, 0.0, 0.0)


func _random_energy_face() -> Array:
    # Intermediate animation only. The final result is NEVER random.
    if _rng.randf() < 0.24:
        return [
            ENERGY_TYPES[
                _rng.randi_range(
                    0,
                    ENERGY_TYPES.size() - 1
                )
            ],
            ENERGY_TYPES[
                _rng.randi_range(
                    0,
                    ENERGY_TYPES.size() - 1
                )
            ]
        ]

    return [
        ENERGY_TYPES[
            _rng.randi_range(
                0,
                ENERGY_TYPES.size() - 1
            )
        ]
    ]


func _extract_orientation(
    dice_result: Variant
) -> StringName:
    for property_name: StringName in [
        &"kyokoro_orientation",
        &"orientation",
        &"orientation_id",
        &"kyokoro_result"
    ]:
        var raw: Variant = _get_property(
            dice_result,
            property_name,
            null
        )

        var candidate: StringName = (
            _find_orientation(
                raw
            )
        )

        if candidate != &"":
            return candidate

    return &""


func _find_orientation(
    value: Variant
) -> StringName:
    if value == null:
        return &""

    if value is String or value is StringName:
        var candidate: StringName = StringName(
            String(value).to_upper()
        )

        if ORIENTATIONS.has(candidate):
            return candidate

        return &""

    if value is Dictionary:
        for item: Variant in (
            value as Dictionary
        ).values():
            var found: StringName = _find_orientation(
                item
            )

            if found != &"":
                return found

    if value is Object:
        for property_name: StringName in [
            &"orientation",
            &"orientation_id",
            &"kyokoro_orientation",
            &"result"
        ]:
            var found: StringName = _find_orientation(
                _get_property(
                    value,
                    property_name,
                    null
                )
            )

            if found != &"":
                return found

    return &""


func _collect_known_energies(
    value: Variant
) -> Array[StringName]:
    var result: Array[StringName] = []

    if value is Array:
        for raw: Variant in value:
            var candidate: StringName = StringName(
                String(raw).to_lower()
            )

            if ENERGY_TYPES.has(
                candidate
            ):
                result.append(candidate)

    elif value is String or value is StringName:
        var candidate: StringName = StringName(
            String(value).to_lower()
        )

        if ENERGY_TYPES.has(candidate):
            result.append(candidate)

    return result


func _clear_icon_row(
    row: HBoxContainer
) -> void:
    for child: Node in row.get_children():
        row.remove_child(child)
        child.queue_free()


func _string_names(
    values: Array[StringName]
) -> Array[String]:
    var result: Array[String] = []

    for value: StringName in values:
        result.append(
            String(value)
        )

    return result


static func _get_property(
    object: Variant,
    property_name: StringName,
    default_value: Variant
) -> Variant:
    if object == null:
        return default_value

    if object is Dictionary:
        var dictionary: Dictionary = object as Dictionary

        if dictionary.has(property_name):
            return dictionary[property_name]

        var string_key: String = String(
            property_name
        )

        if dictionary.has(string_key):
            return dictionary[string_key]

        return default_value

    if not object is Object:
        return default_value

    for property_info: Dictionary in (
        object.get_property_list()
    ):
        if StringName(
            property_info.get(
                "name",
                ""
            )
        ) == property_name:
            return object.get(
                property_name
            )

    return default_value
