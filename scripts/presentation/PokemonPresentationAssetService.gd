extends RefCounted

const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)
const USER_ASSETS: Script = preload(
    "res://scripts/presentation/UserAssetService.gd"
)

const IMAGE_DIRECTORY: String = "pokemon/images"

# Preferred built-in image when a species has multiple card variants.
const PREFERRED_BUILTIN_IMAGE_BY_SPECIES: Dictionary = {
    "articuno": "articuno_eb01_a1.png",
    "bulbasaur": "bulbasaur_standard.png",
    "charmander": "charmander_standard.png",
    "eevee": "eevee_standard.png",
    "grimer": "grimer_eb01_a1.png",
    "mew": "mew_standard.png",
    "moltres": "moltres_eb01_a1.png",
    "onix": "onix_eb01_a1.png",
    "pikachu": "pikachu_standard.png",
    "pinsir": "pinsir_eb01_a1.png",
    "squirtle": "squirtle_standard.png",
    "zapdos": "zapdos_eb01_a1.png",
}

static func resolve_pokemon_image_path(
    pokemon_id: String,
    species_id: String = ""
) -> String:
    var safe_id: String = pokemon_id.strip_edges().to_lower()
    if not safe_id.is_empty():
        var exact_relative: String = (
            IMAGE_DIRECTORY + "/" + safe_id + ".png"
        )
        var exact_path: String = USER_ASSETS.resolve(exact_relative)
        if not exact_path.is_empty():
            return exact_path

    if not species_id.strip_edges().is_empty():
        return resolve_species_image_path(species_id)

    return ""


static func load_pokemon_texture(
    pokemon_id: String,
    species_id: String = ""
) -> Texture2D:
    var path: String = resolve_pokemon_image_path(pokemon_id, species_id)
    return _load_resolved_texture(path)


static func resolve_species_image_path(species_id: String) -> String:
    var safe_species: String = species_id.strip_edges().to_lower()
    if safe_species.is_empty():
        return ""

    var standard_relative: String = (
        IMAGE_DIRECTORY + "/" + safe_species + "_standard.png"
    )
    var resolved: String = USER_ASSETS.resolve(standard_relative)
    if not resolved.is_empty():
        return resolved

    var preferred_name: String = String(
        PREFERRED_BUILTIN_IMAGE_BY_SPECIES.get(safe_species, "")
    )
    if not preferred_name.is_empty():
        resolved = USER_ASSETS.resolve(IMAGE_DIRECTORY + "/" + preferred_name)
        if not resolved.is_empty():
            return resolved

    for pokemon_id: String in POKEMON_AUTHORING.list_saved():
        var data: Dictionary = POKEMON_AUTHORING.load_by_id(pokemon_id)
        if String(data.get("species_id", "")).strip_edges().to_lower() != safe_species:
            continue
        resolved = USER_ASSETS.resolve(IMAGE_DIRECTORY + "/" + pokemon_id + ".png")
        if not resolved.is_empty():
            return resolved

    return ""


static func load_species_texture(species_id: String) -> Texture2D:
    return _load_resolved_texture(
        resolve_species_image_path(species_id)
    )


static func _load_resolved_texture(path: String) -> Texture2D:
    if path.is_empty():
        return null
    if path.begins_with(USER_ASSETS.USER_ROOT + "/"):
        var relative: String = path.trim_prefix(USER_ASSETS.USER_ROOT + "/")
        return USER_ASSETS.load_texture(relative)
    if path.begins_with(USER_ASSETS.BUILTIN_ROOT + "/"):
        var relative_builtin: String = path.trim_prefix(USER_ASSETS.BUILTIN_ROOT + "/")
        return USER_ASSETS.load_texture(relative_builtin)
    return null
