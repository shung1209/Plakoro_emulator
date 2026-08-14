# Battle integration requirement

Milestone 9.3 introduces mixed double-energy faces such as:

```text
electric + steel
```

The older `configure_energy_die(...)` API accepts only one energy identifier
per face. It cannot correctly represent a face containing two different
energies.

Therefore the battle-side integration must use a structured profile:

```gdscript
var setup: Variant = EnergyDiceSetupLoader.load_setup(
    "res://database/dice_setups/pikachu_default.json"
)

var profile: Variant = EnergyDiceSetupAdapter.create_runtime_profile(
    setup.dice[0]
)
```

The next required core patch is:

```gdscript
TeamBuilderService.set_energy_die_profile(
    loadout,
    die_index,
    profile
)
```

and `DiceEngine.roll_battle_dice()` must read each face result as:

```gdscript
{
    "kind": "double",
    "energies": [
        &"electric",
        &"steel"
    ]
}
```

It must add one count for each listed energy.

The setup model, validation, JSON data, probability calculator and viewer are
complete in this package. Do not map a mixed double face into a single
StringName, because that would lose one of the two energy results.
