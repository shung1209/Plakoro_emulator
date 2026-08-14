extends RefCounted


const PROFILE: Script = preload(
    "res://scripts/ui/responsive/UIResponsiveProfile.gd"
)


static func get_profile(
    control: Control
) -> StringName:
    if control == null:
        return PROFILE.PROFILE_FULL

    return PROFILE.from_width(
        control.get_viewport_rect().size.x
    )


static func apply_margin(
    margin: MarginContainer,
    profile: StringName
) -> void:
    if margin == null:
        return

    var horizontal: float = (
        PROFILE.horizontal_margin(
            profile
        )
    )
    var vertical: float = (
        PROFILE.vertical_margin(
            profile
        )
    )

    margin.add_theme_constant_override(
        "margin_left",
        int(horizontal)
    )
    margin.add_theme_constant_override(
        "margin_right",
        int(horizontal)
    )
    margin.add_theme_constant_override(
        "margin_top",
        int(vertical)
    )
    margin.add_theme_constant_override(
        "margin_bottom",
        int(vertical)
    )


static func apply_action_row(
    row: HBoxContainer,
    profile: StringName
) -> void:
    if row == null:
        return

    row.custom_minimum_size.y = (
        PROFILE.action_height(
            profile
        )
    )
    row.add_theme_constant_override(
        "separation",
        PROFILE.section_spacing(
            profile
        )
    )


static func apply_button(
    button: Button,
    profile: StringName,
    full_width: float = 150.0
) -> void:
    if button == null:
        return

    match profile:
        PROFILE.PROFILE_FULL:
            button.custom_minimum_size = Vector2(
                full_width,
                46
            )
        PROFILE.PROFILE_COMPACT:
            button.custom_minimum_size = Vector2(
                max(120.0, full_width * 0.82),
                42
            )
        _:
            button.custom_minimum_size = Vector2(
                max(105.0, full_width * 0.72),
                40
            )


static func apply_split(
    split: SplitContainer,
    profile: StringName,
    viewport_width: float,
    full_ratio: float = 0.5
) -> void:
    if split == null:
        return

    var ratio: float = full_ratio

    match profile:
        PROFILE.PROFILE_FULL:
            ratio = full_ratio
        PROFILE.PROFILE_COMPACT:
            ratio = 0.50
        _:
            ratio = 0.50

    split.split_offset = int(
        viewport_width * ratio
    )


static func apply_grid_columns(
    grid: GridContainer,
    profile: StringName,
    full_columns: int,
    compact_columns: int = 1
) -> void:
    if grid == null:
        return

    if profile == PROFILE.PROFILE_FULL:
        grid.columns = full_columns
    else:
        grid.columns = compact_columns
