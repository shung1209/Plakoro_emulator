extends RefCounted

const USER_ASSETS: Script = preload(
    "res://scripts/presentation/UserAssetService.gd"
)
const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)
const POKEMON_PRESENTATION: Script = preload(
    "res://scripts/presentation/PokemonPresentationAssetService.gd"
)


static func resolve_pokemon(pokemon_id: StringName) -> Dictionary:
    var safe_id: String = String(pokemon_id).strip_edges().to_lower()
    var species_id: String = ""

    if not safe_id.is_empty():
        var document: Dictionary = POKEMON_AUTHORING.load_by_id(safe_id)
        if not document.is_empty():
            species_id = String(
                document.get("species_id", "")
            ).strip_edges().to_lower()

    var image_path: String = POKEMON_PRESENTATION.resolve_pokemon_image_path(
        safe_id,
        species_id
    )

    return {
        "pokemon_id": pokemon_id,
        "species_id": species_id,
        "mode": &"image_2d" if not image_path.is_empty() else &"placeholder",
        "model_path": "",
        "image_path": image_path
    }
