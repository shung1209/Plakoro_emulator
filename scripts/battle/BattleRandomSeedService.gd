extends RefCounted


static var _sequence: int = 0


static func create_live_seed() -> int:
    _sequence += 1

    var rng: RandomNumberGenerator = (
        RandomNumberGenerator.new()
    )
    rng.randomize()

    var random_part: int = int(
        rng.randi()
    )
    var tick_part: int = int(
        Time.get_ticks_usec()
    )
    var sequence_part: int = (
        _sequence * 1103515245
    )

    var result: int = (
        random_part
        ^ tick_part
        ^ sequence_part
    )

    if result == 0:
        result = 1

    return result


static func derive_seed(
    base_seed: int,
    salt: int
) -> int:
    var result: int = (
        base_seed
        ^ salt
        ^ 0x5F3759DF
    )

    if result == 0:
        result = 1

    return result
