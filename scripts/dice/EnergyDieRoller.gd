extends RefCounted


static func roll(
	profile: Variant,
	rng: RandomNumberGenerator
) -> Variant:
	if profile == null:
		push_error(
            "EnergyDieRoller: profile is null."
		)
		return null

	if rng == null:
		push_error(
            "EnergyDieRoller: rng is null."
		)
		return null

	if not profile.has_method("get_all_faces"):
		push_error(
            "EnergyDieRoller: profile does not provide get_all_faces()."
		)
		return null

	var faces: Array = profile.get_all_faces()

	if faces.size() != 6:
		push_error(
            "EnergyDieRoller: profile must contain 6 faces."
		)
		return null

	var total_weight: float = 0.0

	for face: Variant in faces:
		if face == null:
			push_error(
                "EnergyDieRoller: face is null."
			)
			return null

		if not (
			"weight" in face
			and "id" in face
			and "energies" in face
		):
			push_error(
                "EnergyDieRoller: face does not satisfy runtime interface."
			)
			return null

		total_weight += float(face.weight)

	if total_weight <= 0.0:
		push_error(
            "EnergyDieRoller: total face weight must be positive."
		)
		return null

	var rolled_value: float = rng.randf_range(
		0.0,
		total_weight
	)
	var accumulated_weight: float = 0.0

	for face: Variant in faces:
		accumulated_weight += float(face.weight)

		if rolled_value <= accumulated_weight:
			return face

	return faces.back()
