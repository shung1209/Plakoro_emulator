extends HBoxContainer


const ENERGY_COST_CHIP: Script = preload(
    "res://scripts/ui/components/EnergyCostChip.gd"
)


func setup(
    move_card: Variant,
    icon_size: int = 22
) -> void:
    if move_card == null:
        setup_cost_entries(
            [],
            icon_size
        )
        return

    var entries: Array = []

    for cost: Variant in move_card.energy_costs:
        entries.append(
            {
                "energy_type": StringName(
                    cost.energy_type
                ),
                "count": int(
                    cost.count
                )
            }
        )

    setup_cost_entries(
        entries,
        icon_size
    )


func setup_cost_entries(
    raw_costs: Array,
    icon_size: int = 22
) -> void:
    add_theme_constant_override(
        "separation",
        8
    )

    for child: Node in get_children():
        child.queue_free()

    if raw_costs.is_empty():
        var none_label: Label = Label.new()
        none_label.text = "None"
        none_label.modulate.a = 0.70
        add_child(
            none_label
        )
        return

    for raw_cost: Variant in raw_costs:
        var energy_type: StringName = &"normal"
        var count: int = 0

        if raw_cost is Dictionary:
            energy_type = StringName(
                (raw_cost as Dictionary).get(
                    "energy_type",
                    "normal"
                )
            )
            count = int(
                (raw_cost as Dictionary).get(
                    "count",
                    0
                )
            )
        elif raw_cost != null:
            energy_type = StringName(
                raw_cost.energy_type
            )
            count = int(
                raw_cost.count
            )

        if count <= 0:
            continue

        var chip: HBoxContainer = HBoxContainer.new()
        chip.set_script(
            ENERGY_COST_CHIP
        )
        chip.setup(
            energy_type,
            count,
            icon_size
        )
        add_child(
            chip
        )
