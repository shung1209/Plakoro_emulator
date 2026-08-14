extends RefCounted


static func should_present_resolution(
    energy_sufficient: bool,
    turn_success: bool
) -> bool:
    return energy_sufficient and turn_success


static func should_use_step_queue(
    presentation_mode: StringName,
    energy_sufficient: bool,
    turn_success: bool
) -> bool:
    return (
        presentation_mode == &"step_by_step"
        and should_present_resolution(
            energy_sufficient,
            turn_success
        )
    )


static func result_reveal_is_after_resolution() -> bool:
    # BattleGameUI awaits _present_turn_damage() before checking is_finished.
    return true
