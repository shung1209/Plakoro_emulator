extends RefCounted

# Export-safe list of shipped raw presentation assets.
# .import metadata is intentionally excluded; user:// assets are loaded as raw images.
const FILES: Array[String] = [
    "pokemon/images/articuno_eb01_a1.png",
    "pokemon/images/articuno_eb01_b1.png",
    "pokemon/images/bulbasaur_standard.png",
    "pokemon/images/charmander_standard.png",
    "pokemon/images/eevee_standard.png",
    "pokemon/images/grimer_eb01_a1.png",
    "pokemon/images/grimer_eb01_b1.png",
    "pokemon/images/mew_standard.png",
    "pokemon/images/moltres_eb01_a1.png",
    "pokemon/images/moltres_eb01_b1.png",
    "pokemon/images/onix_eb01_a1.png",
    "pokemon/images/onix_eb01_b1.png",
    "pokemon/images/pikachu_standard.png",
    "pokemon/images/pinsir_eb01_a1.png",
    "pokemon/images/pinsir_eb01_b1.png",
    "pokemon/images/squirtle_standard.png",
    "pokemon/images/zapdos_eb01_a1.png",
    "pokemon/images/zapdos_eb01_b1.png",
    "ui/energy/dark.webp",
    "ui/energy/electric.webp",
    "ui/energy/fighting.webp",
    "ui/energy/fire.webp",
    "ui/energy/flying.webp",
    "ui/energy/grass.webp",
    "ui/energy/normal.webp",
    "ui/energy/psychic.webp",
    "ui/energy/steel.webp",
    "ui/energy/water.webp",
    "ui/kyokoro/face_down.webp",
    "ui/kyokoro/face_up.webp",
    "ui/kyokoro/head_down.webp",
    "ui/kyokoro/head_left.webp",
    "ui/kyokoro/head_right.webp",
    "ui/kyokoro/head_up.webp",
]


static func all_files() -> Array[String]:
    return FILES.duplicate()


static func directories() -> Array[String]:
    var result: Array[String] = []
    for relative_path: String in FILES:
        var directory: String = relative_path.get_base_dir()
        if directory.is_empty():
            continue
        if not result.has(directory):
            result.append(directory)
    return result
