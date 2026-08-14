extends RefCounted


const FULL_DESKTOP_MIN_WIDTH: float = 1600.0
const COMPACT_DESKTOP_MIN_WIDTH: float = 1280.0

const PROFILE_FULL: StringName = &"desktop_full"
const PROFILE_COMPACT: StringName = &"desktop_compact"
const PROFILE_HANDHELD: StringName = &"handheld"


static func from_width(
    width: float
) -> StringName:
    if width >= FULL_DESKTOP_MIN_WIDTH:
        return PROFILE_FULL

    if width >= COMPACT_DESKTOP_MIN_WIDTH:
        return PROFILE_COMPACT

    return PROFILE_HANDHELD


static func horizontal_margin(
    profile: StringName
) -> float:
    match profile:
        PROFILE_FULL:
            return 24.0
        PROFILE_COMPACT:
            return 16.0
        _:
            return 10.0


static func vertical_margin(
    profile: StringName
) -> float:
    match profile:
        PROFILE_FULL:
            return 24.0
        PROFILE_COMPACT:
            return 14.0
        _:
            return 8.0


static func section_spacing(
    profile: StringName
) -> int:
    match profile:
        PROFILE_FULL:
            return 12
        PROFILE_COMPACT:
            return 8
        _:
            return 6


static func title_size(
    profile: StringName
) -> int:
    match profile:
        PROFILE_FULL:
            return 30
        PROFILE_COMPACT:
            return 25
        _:
            return 21


static func body_font_size(
    profile: StringName
) -> int:
    match profile:
        PROFILE_FULL:
            return 16
        PROFILE_COMPACT:
            return 14
        _:
            return 13


static func action_height(
    profile: StringName
) -> float:
    match profile:
        PROFILE_FULL:
            return 50.0
        PROFILE_COMPACT:
            return 46.0
        _:
            return 42.0


static func icon_size(
    profile: StringName
) -> int:
    match profile:
        PROFILE_FULL:
            return 26
        PROFILE_COMPACT:
            return 22
        _:
            return 19
