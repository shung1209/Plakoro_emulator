extends RefCounted

# Export-safe manifest for the built-in opcode handlers.
#
# Godot exported PCKs must not rely on enumerating the source .gd directory at
# runtime. Explicit preloads keep every built-in handler reachable by the
# exporter and give the runtime registry a deterministic handler list.

const HANDLER_SCRIPTS: Array[Script] = [
    preload("res://scripts/battle/opcode/handlers/battle/TurnEndHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/condition/ConditionIfHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/damage/DamageAddHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/damage/DamageAddPerEnergyHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/damage/DamageCopyPreviousOpponentMoveHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/damage/DamageCreateHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/damage/DamageDealHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/damage/DamageMultiplyHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/damage/DamageRecoilHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/damage/DamageSetHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/dice/EnergyDiceModifyHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/dice/KyokoroForceNextOrientationHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/hp/HpRestoreHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/move/MoveLockHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/move/MoveRepeatPermissionHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/status/IncomingDamageImmunityHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/status/IncomingDamageModifyHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/status/StatusAddHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/weakness/WeaknessDisableHandler.gd"),
    preload("res://scripts/battle/opcode/handlers/weakness/WeaknessIgnoreCurrentHandler.gd")
]


static func get_scripts() -> Array[Script]:
    return HANDLER_SCRIPTS.duplicate()
