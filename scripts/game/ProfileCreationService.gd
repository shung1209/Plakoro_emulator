extends RefCounted


const POKEMON_AUTHORING: Script = preload(
	"res://scripts/content/PokemonAuthoringService.gd"
)
const CONTENT_PLAYTEST: Script = preload(
	"res://scripts/content/ContentPlaytestBridgeService.gd"
)
const ENERGY_CATALOG: Script = preload(
	"res://scripts/game/EnergyProgressionCatalog.gd"
)
const ENERGY_SAVE: Script = preload(
	"res://scripts/dice/setup/EnergyDiceSetupSaveService.gd"
)

const STARTER_IDS: Array[String] = [
	"charmander_standard",
	"squirtle_standard",
	"bulbasaur_standard"
]


static func create_new_save(
	starter_pokemon_id: StringName,
	starter_energy: StringName
) -> Dictionary:
	var starter_id: String = String(starter_pokemon_id)
	if not STARTER_IDS.has(starter_id):
		return {"success": false, "error": "Unsupported starter."}
	if not ENERGY_CATALOG.get_energy_options(starter_pokemon_id).has(
		String(starter_energy)
	):
		return {"success": false, "error": "Unsupported starter Energy."}
	var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(starter_id)
	if pokemon.is_empty():
		return {"success": false, "error": "Starter data is missing."}
	var all_move_ids: Array[String] = []
	for raw_move_id: Variant in pokemon.get("available_move_card_ids", []):
		var move_id: String = String(raw_move_id)
		if not move_id.is_empty() and not all_move_ids.has(move_id):
			all_move_ids.append(move_id)
	if all_move_ids.size() < 4:
		return {"success": false, "error": "Starter needs at least four Moves."}
	var selected_move_ids: Array[String] = all_move_ids.slice(0, 4)
	var starter_inventory: Dictionary = ENERGY_CATALOG.create_starter_inventory(
		starter_pokemon_id,
		starter_energy
	)
	var initial_setup: Variant = ENERGY_CATALOG.create_balanced_setup(
		starter_inventory
	)
	if initial_setup == null:
		return {"success": false, "error": "Could not build starting Enerkoro."}
	if not ENERGY_SAVE.save_setup(
		initial_setup,
		CONTENT_PLAYTEST.PLAYER_CUSTOM_DICE_PATH
	):
		return {"success": false, "error": "Could not save starting Enerkoro."}
	var loadout_result: Dictionary = CONTENT_PLAYTEST.create_playtest_loadout(
		pokemon,
		selected_move_ids,
		"player_custom"
	)
	if not bool(loadout_result.get("success", false)):
		return {
			"success": false,
			"error": "\n".join(loadout_result.get("errors", []))
		}
	if not PlayerProgress.create_profile(
		starter_pokemon_id,
		all_move_ids,
		starter_energy
	):
		return {"success": false, "error": "Could not save player progress."}
	EncounterSession.clear()
	return {"success": true}
