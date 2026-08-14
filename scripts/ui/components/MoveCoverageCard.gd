extends PanelContainer


const ENERGY_COST_CHIP: Script = preload(
    "res://scripts/ui/components/EnergyCostChip.gd"
)


var _title_label: Label = null
var _cost_row: HBoxContainer = null
var _probability_label: Label = null
var _detail_label: Label = null


func _ready() -> void:
    _build_ui()


func display_result(result: Variant) -> void:
    if result == null:
        return

    if not is_node_ready():
        await ready

    var move_name_id: String = String(
        result.move_name_id
    )
    _title_label.text = GameContentLocalizationService.text(
        "move",
        move_name_id,
        "name",
        String(result.move_name)
    )

    _refresh_required_energy(
        result.required_energy
    )

    _probability_label.text = LocalizationService.tr_format(
        "enerkoro_builder.coverage_success",
        {
            "value": LocalizationService.format_decimal(
                float(result.success_probability) * 100.0,
                1
            )
        },
        "{value}% success"
    )

    match result.get_rating_id():
        &"excellent":
            _probability_label.modulate = Color(
                0.39,
                0.85,
                0.52,
                1.0
            )
        &"acceptable":
            _probability_label.modulate = Color(
                1.0,
                0.82,
                0.32,
                1.0
            )
        _:
            _probability_label.modulate = Color(
                1.0,
                0.42,
                0.42,
                1.0
            )

    var lines: Array[String] = []

    if result.most_missing_energy != &"":
        lines.append(
            LocalizationService.tr_format(
                "enerkoro_builder.coverage_most_missing",
                {
                    "energy": GameContentLocalizationService.localize_type(
                        result.most_missing_energy
                    )
                },
                "Most missing: {energy}"
            )
        )

    lines.append(
        LocalizationService.tr_format(
            "enerkoro_builder.coverage_average_shortfall",
            {
                "value": LocalizationService.format_decimal(
                    float(result.average_shortfall),
                    2
                )
            },
            "Average shortfall: {value}"
        )
    )

    _detail_label.text = "\n".join(
        lines
    )


func _build_ui() -> void:
    custom_minimum_size = Vector2(
        250,
        148
    )

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override(
        "separation",
        5
    )
    add_child(
        box
    )

    _title_label = Label.new()
    _title_label.add_theme_font_size_override(
        "font_size",
        18
    )
    box.add_child(
        _title_label
    )

    var requirement_line: HBoxContainer = HBoxContainer.new()
    requirement_line.add_theme_constant_override(
        "separation",
        8
    )
    box.add_child(
        requirement_line
    )

    var requirement_label: Label = Label.new()
    requirement_label.text = LocalizationService.tr_key(
        "enerkoro_builder.coverage_requires",
        "Requires:"
    )
    requirement_line.add_child(
        requirement_label
    )

    _cost_row = HBoxContainer.new()
    _cost_row.add_theme_constant_override(
        "separation",
        8
    )
    requirement_line.add_child(
        _cost_row
    )

    _probability_label = Label.new()
    _probability_label.add_theme_font_size_override(
        "font_size",
        22
    )
    box.add_child(
        _probability_label
    )

    _detail_label = Label.new()
    _detail_label.autowrap_mode = (
        TextServer.AUTOWRAP_WORD_SMART
    )
    box.add_child(
        _detail_label
    )


func _refresh_required_energy(
    required_energy: Dictionary
) -> void:
    for child: Node in _cost_row.get_children():
        child.queue_free()

    if required_energy.is_empty():
        var none_label: Label = Label.new()
        none_label.text = LocalizationService.tr_key(
            "enerkoro_builder.coverage_none",
            "(none)"
        )
        _cost_row.add_child(
            none_label
        )
        return

    var keys: Array = required_energy.keys()
    keys.sort()

    for raw_energy: Variant in keys:
        var energy_type: StringName = StringName(
            raw_energy
        )
        var chip: HBoxContainer = HBoxContainer.new()
        chip.set_script(
            ENERGY_COST_CHIP
        )
        chip.setup(
            energy_type,
            int(
                required_energy[raw_energy]
            ),
            22
        )
        chip.tooltip_text = (
            GameContentLocalizationService.localize_type(
                energy_type
            )
        )
        _cost_row.add_child(
            chip
        )
