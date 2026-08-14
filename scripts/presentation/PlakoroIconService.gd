extends RefCounted

const USER_ASSETS: Script = preload(
    "res://scripts/presentation/UserAssetService.gd"
)

const ENERGY_PATHS: Dictionary = {
    &"normal": "ui/energy/normal.webp",
    &"grass": "ui/energy/grass.webp",
    &"fire": "ui/energy/fire.webp",
    &"water": "ui/energy/water.webp",
    &"electric": "ui/energy/electric.webp",
    &"psychic": "ui/energy/psychic.webp",
    &"fighting": "ui/energy/fighting.webp",
    &"dark": "ui/energy/dark.webp",
    &"steel": "ui/energy/steel.webp",
    &"flying": "ui/energy/flying.webp"
}

const KYOKORO_PATHS: Dictionary = {
    &"FACE_UP": "ui/kyokoro/face_up.webp",
    &"FACE_DOWN": "ui/kyokoro/face_down.webp",
    &"HEAD_UP": "ui/kyokoro/head_up.webp",
    &"HEAD_DOWN": "ui/kyokoro/head_down.webp",
    &"HEAD_LEFT": "ui/kyokoro/head_left.webp",
    &"HEAD_RIGHT": "ui/kyokoro/head_right.webp"
}


static func load_energy_icon(
    energy_type: StringName
) -> Texture2D:
    return USER_ASSETS.load_texture(
        String(ENERGY_PATHS.get(energy_type, ""))
    )


static func load_kyokoro_icon(
    orientation: StringName
) -> Texture2D:
    return USER_ASSETS.load_texture(
        String(KYOKORO_PATHS.get(orientation, ""))
    )


static func has_energy_icon(
    energy_type: StringName
) -> bool:
    return load_energy_icon(energy_type) != null


static func has_kyokoro_icon(
    orientation: StringName
) -> bool:
    return load_kyokoro_icon(orientation) != null


static func energy_fallback(
    energy_type: StringName
) -> String:
    match energy_type:
        &"normal":
            return "NORMAL"
        &"grass":
            return "GRASS"
        &"fire":
            return "FIRE"
        &"water":
            return "WATER"
        &"electric":
            return "ELECTRIC"
        &"psychic":
            return "PSYCHIC"
        &"fighting":
            return "FIGHTING"
        &"dark":
            return "DARK"
        &"steel":
            return "STEEL"
        &"flying":
            return "FLYING"
        _:
            return String(energy_type).to_upper()
