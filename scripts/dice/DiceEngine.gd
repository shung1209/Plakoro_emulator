extends RefCounted


const ENERGY_DIE_ROLLER: Script = preload(
    "res://scripts/dice/EnergyDieRoller.gd"
)

const KYOKORO_ROLLER: Script = preload(
    "res://scripts/dice/KyokoroRoller.gd"
)

const DICE_RESULT_DATA: Script = preload(
    "res://scripts/battle/data/DiceRollResultData.gd"
)

const ROLL_RECORD_DATA: Script = preload(
    "res://scripts/dice/data/DiceRollRecordData.gd"
)


var reference_data: Variant = null
var rng: RandomNumberGenerator = (
	RandomNumberGenerator.new()
)

var random_seed: int = 0
var roll_index: int = 0
var history: Array = []


func _init(
	source_reference_data: Variant,
	initial_random_seed: int = 2026
) -> void:
	reference_data = source_reference_data
	reset(initial_random_seed)


func reset(
	new_random_seed: int
) -> void:
	random_seed = new_random_seed
	roll_index = 0
	history.clear()
	rng.seed = random_seed


func roll_battle_dice(
	energy_die_profiles: Array,
	kyokoro_profile: Variant,
	energy_dice_count_modifier: int = 0,
	kyokoro_enabled: bool = true,
	forced_kyokoro_orientation: StringName = &""
) -> Variant:
	if energy_die_profiles.is_empty():
		push_error(
            "DiceEngine: at least one energy die profile is required."
		)
		return null

	if (
		kyokoro_enabled
		and kyokoro_profile == null
	):
		push_error(
            "DiceEngine: Charakoro profile is null."
		)
		return null

	var dice_result: Variant = DICE_RESULT_DATA.new()
	var record: Variant = ROLL_RECORD_DATA.new()

	record.random_seed = random_seed
	record.roll_index = roll_index

	var requested_dice_count: int = max(
		energy_die_profiles.size()
		+ energy_dice_count_modifier,
		0
	)

	var actual_dice_count: int = requested_dice_count

	for die_index: int in range(
		actual_dice_count
	):
		# Positive modifiers are extra rolls. Reuse the three configured
		# Enerkoro in stable round-robin order for every extra roll.
		var profile_index: int = (
			die_index % energy_die_profiles.size()
		)
		var profile: Variant = (
			energy_die_profiles[profile_index]
		)

		if profile == null:
			push_error(
                "DiceEngine: energy die profile %d is null."
				% die_index
			)
			return null

		if not profile.validate(reference_data):
			return null

		var rolled_face: Variant = (
			ENERGY_DIE_ROLLER.roll(
				profile,
				rng
			)
		)

		if rolled_face == null:
			return null

		record.energy_die_ids.append(
			StringName(profile.id)
		)
		record.energy_die_face_ids.append(
			StringName(rolled_face.id)
		)

		for raw_energy: Variant in (
			rolled_face.energies
		):
			var energy_type: StringName = StringName(
				raw_energy
			)
			var current_count: int = int(
				dice_result.energy_counts.get(
					energy_type,
					0
				)
			)

			dice_result.energy_counts[
				energy_type
			] = current_count + 1

	if kyokoro_enabled:
		dice_result.kyokoro_orientation = (
			forced_kyokoro_orientation
			if forced_kyokoro_orientation != &""
			else KYOKORO_ROLLER.roll(
				kyokoro_profile,
				reference_data,
				rng
			)
		)

		if dice_result.kyokoro_orientation == &"":
			return null
	else:
		dice_result.kyokoro_orientation = &""

	record.energy_counts = (
		dice_result.energy_counts.duplicate(true)
	)
	record.kyokoro_profile_id = (
		StringName(
			kyokoro_profile.id
		)
		if kyokoro_profile != null
		else &""
	)
	record.kyokoro_orientation = (
		dice_result.kyokoro_orientation
	)

	history.append(record)
	roll_index += 1

	return dice_result


func get_history() -> Array:
	return history.duplicate()



func roll_kyokoro_only(
	kyokoro_profile: Variant
) -> StringName:
	if kyokoro_profile == null:
		push_error(
			"DiceEngine: Charakoro profile is null."
		)
		return &""

	return KYOKORO_ROLLER.roll(
		kyokoro_profile,
		reference_data,
		rng
	)


func roll_kyokoro_count(
	kyokoro_profile: Variant,
	count: int
) -> Array[StringName]:
	var results: Array[StringName] = []

	for _index: int in range(
		max(
			count,
			0
		)
	):
		var orientation: StringName = (
			roll_kyokoro_only(
				kyokoro_profile
			)
		)

		if orientation == &"":
			break

		results.append(
			orientation
		)

	return results


func roll_kyokoro_until_fail(
	kyokoro_profile: Variant,
	success_orientations: Array[StringName],
	max_rolls: int = 32
) -> Array[StringName]:
	var results: Array[StringName] = []

	for _index: int in range(
		max(
			max_rolls,
			0
		)
	):
		var orientation: StringName = (
			roll_kyokoro_only(
				kyokoro_profile
			)
		)

		if orientation == &"":
			break

		results.append(
			orientation
		)

		if not success_orientations.has(
			orientation
		):
			break

	return results
