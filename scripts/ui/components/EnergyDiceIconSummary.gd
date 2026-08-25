extends HBoxContainer


const DIE_PREVIEW: Script = preload(
    "res://scripts/ui/components/EnergyDieIconPreview.gd"
)


func setup(
    setup_data: Variant,
    compact: bool = true
) -> void:
    add_theme_constant_override(
        "separation",
        10
    )

    if setup_data == null:
        var missing: Label = Label.new()
        missing.text = LocalizationService.tr_key(
            "enerkoro_builder.setup_unavailable",
            "Enerkoro setup unavailable."
        )
        add_child(missing)
        return

    for index: int in range(
        setup_data.dice.size()
    ):
        var preview: PanelContainer = PanelContainer.new()
        preview.set_script(
            DIE_PREVIEW
        )
        preview.setup(
            setup_data.dice[index],
            index + 1,
            compact
        )
        preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        add_child(preview)
