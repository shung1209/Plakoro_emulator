extends Node
const JSON_LOADER: Script = preload("res://scripts/database/JsonLoader.gd")
const REFERENCE_LOADER: Script = preload("res://scripts/database/ReferenceLoader.gd")
const RULES_LOADER: Script = preload("res://scripts/database/RulesLoader.gd")
const MOVE_CARD_PARSER: Script = preload("res://scripts/database/parsers/MoveCardParser.gd")
const POKEMON_PARSER: Script = preload("res://scripts/database/parsers/PokemonParser.gd")
const PROFILE_PARSER: Script = preload("res://scripts/database/parsers/KyokoroProfileParser.gd")
const MOVE_DIR: String = "res://database/move_cards"
const POKEMON_DIR: String = "res://database/pokemon"
const PROFILE_DIR: String = "res://database/kyokoro_profiles"
const USER_MOVE_DIR: String = "user://user_database/move_cards"
const USER_POKEMON_DIR: String = "user://user_database/pokemon"
const USER_PROFILE_DIR: String = "user://user_database/kyokoro_profiles"
var reference_data: Variant = null
var rules: Variant = null
var move_cards: Dictionary = {}
var pokemon: Dictionary = {}
var kyokoro_profiles: Dictionary = {}
var is_loaded: bool = false
var invalid_move_cards: Dictionary = {}
func load_all() -> bool:
	clear(); print("V2: Loading reference data...")
	reference_data = REFERENCE_LOADER.load_all()
	if reference_data == null: return false
	print("V2: Loading battle rules...")
	rules = RULES_LOADER.load_rules()
	if rules == null: return false
	print("V2: Loading Charakoro profiles...")
	if not _load_directory(PROFILE_DIR, PROFILE_PARSER, kyokoro_profiles): return false
	_load_user_directory(
		USER_PROFILE_DIR,
		PROFILE_PARSER,
		kyokoro_profiles,
		"Charakoro profile"
	)
	print("V2: Loading move cards...")
	if not _load_directory(MOVE_DIR, MOVE_CARD_PARSER, move_cards): return false
	_load_user_directory(
		USER_MOVE_DIR,
		MOVE_CARD_PARSER,
		move_cards,
		"Move"
	)
	print("V2: Loading Pokémon...")
	if not _load_directory(POKEMON_DIR, POKEMON_PARSER, pokemon): return false
	_load_user_directory(
		USER_POKEMON_DIR,
		POKEMON_PARSER,
		pokemon,
		"Pokémon"
	)
	if not _resolve_pokemon_references(): return false
	is_loaded = true
	print("V2 database loaded: %d move cards, %d profiles, %d Pokémon." % [move_cards.size(), kyokoro_profiles.size(), pokemon.size()])
	return true
func clear() -> void:
	reference_data = null; rules = null; move_cards.clear(); pokemon.clear(); kyokoro_profiles.clear(); invalid_move_cards.clear(); is_loaded = false
func get_move_card(id: StringName) -> Variant:
	if move_cards.has(id):
		return move_cards[id]

	# Content Studio / direct JSON editing can create or rename a Move while
	# this DatabaseService instance is already alive. Recover that one Move
	# from disk instead of showing "Missing move data" until a scene restart.
	var path: String = (
		MOVE_DIR.path_join(
			String(id) + ".json"
		)
	)

	if not FileAccess.file_exists(path):
		return null

	var raw: Dictionary = JSON_LOADER.load_dictionary(
		path
	)

	if raw.is_empty():
		return null

	var parsed: Variant = MOVE_CARD_PARSER.parse(
		raw,
		path,
		reference_data
	)

	if parsed == null:
		return null

	var parsed_id: StringName = StringName(
		parsed.id
	)

	if parsed_id != id:
		push_warning(
			"Move filename/id mismatch: "
			+ path
			+ " contains id "
			+ String(parsed_id)
		)
		return null

	move_cards[id] = parsed
	return parsed
func get_invalid_move_cards() -> Dictionary:
	return invalid_move_cards.duplicate(
		true
	)


func get_pokemon(id: StringName) -> Variant: return pokemon.get(id, null)
func get_kyokoro_profile(id: StringName) -> Variant: return kyokoro_profiles.get(id, null)
func has_move_card(id: StringName) -> bool: return move_cards.has(id)
func has_pokemon(id: StringName) -> bool: return pokemon.has(id)
func has_kyokoro_profile(id: StringName) -> bool: return kyokoro_profiles.has(id)
func _load_directory(path: String, parser: Script, target: Dictionary) -> bool:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_error("Could not open directory: %s" % path)
		return false

	var names: PackedStringArray = dir.get_files()
	names.sort()

	for name: String in names:
		if name.get_extension().to_lower() != "json":
			continue

		var full: String = path.path_join(name)
		var raw: Dictionary = JSON_LOADER.load_dictionary(full)

		if raw.is_empty():
			if path == MOVE_DIR:
				invalid_move_cards[name.get_basename()] = (
					"Could not load JSON."
				)
				push_warning(
					"Skipping invalid Move JSON: "
					+ full
				)
				continue
			return false

		var parsed: Variant = parser.parse(
			raw,
			full,
			reference_data
		)

		if parsed == null:
			if path == MOVE_DIR:
				invalid_move_cards[
					String(
						raw.get(
							"id",
							name.get_basename()
						)
					)
				] = "Parser rejected the Move document."
				push_warning(
					"Skipping invalid Move document: "
					+ full
				)
				continue
			return false

		var id: StringName = StringName(
			parsed.id
		)

		if id == &"" or target.has(id):
			if path == MOVE_DIR:
				invalid_move_cards[
					name.get_basename()
				] = "Missing or duplicate Move id."
				push_warning(
					"Skipping Move with missing/duplicate id: "
					+ full
				)
				continue
			return false

		target[id] = parsed

	return true
func _load_user_directory(
	path: String,
	parser: Script,
	target: Dictionary,
	content_label: String
) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return

	var names: PackedStringArray = dir.get_files()
	names.sort()

	for name: String in names:
		if name.get_extension().to_lower() != "json":
			continue

		var full: String = path.path_join(name)
		var raw: Dictionary = JSON_LOADER.load_dictionary(full)

		if raw.is_empty():
			push_warning(
				"Skipping invalid user "
				+ content_label
				+ " JSON: "
				+ full
			)
			continue

		var parsed: Variant = parser.parse(
			raw,
			full,
			reference_data
		)

		if parsed == null:
			push_warning(
				"Skipping rejected user "
				+ content_label
				+ ": "
				+ full
			)
			continue

		var id: StringName = StringName(parsed.id)
		if id == &"":
			push_warning(
				"Skipping user "
				+ content_label
				+ " with empty id: "
				+ full
			)
			continue

		# user:// is the editable authoritative override layer.
		target[id] = parsed


func _resolve_pokemon_references() -> bool:
	for p: Variant in pokemon.values():
		p.available_move_cards.clear()

		for card_id: StringName in p.available_move_card_ids:
			if not move_cards.has(card_id):
				if invalid_move_cards.has(
					String(card_id)
				):
					push_warning(
						"Pokémon "
						+ String(p.id)
						+ " references invalid Move "
						+ String(card_id)
						+ "; reference skipped."
					)
					continue
				return false

			var card: Variant = move_cards[
				card_id
			]

			if StringName(card.owner_id) != StringName(
				p.species_id
			):
				return false

			p.available_move_cards.append(
				card
			)

		if not kyokoro_profiles.has(
			p.kyokoro_profile_id
		):
			return false

		p.kyokoro_profile = kyokoro_profiles[
			p.kyokoro_profile_id
		]

	return true
