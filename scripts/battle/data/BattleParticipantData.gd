extends RefCounted


const STATUS_CONTAINER_DATA: Script = preload(
    "res://scripts/battle/status/StatusContainerData.gd"
)
const STATUS_RESOLVER: Script = preload(
    "res://scripts/battle/status/StatusResolver.gd"
)
const BATTLE_EFFECT_CONTAINER_DATA: Script = preload(
    "res://scripts/battle/effects/BattleEffectContainerData.gd"
)


var id: StringName = &""
var display_name: String = ""

var loadout: Variant = null
var pokemon_data: Variant = null

var current_hp: int = 0
var max_hp: int = 0

var last_move_name_id: StringName = &""

var status_container: Variant = (
    STATUS_CONTAINER_DATA.new()
)
var effect_container: Variant = (
    BATTLE_EFFECT_CONTAINER_DATA.new()
)


func initialize(
    participant_id: StringName,
    participant_name: String,
    source_loadout: Variant
) -> void:
    id = participant_id
    display_name = participant_name
    loadout = source_loadout
    pokemon_data = source_loadout.pokemon_data

    max_hp = int(pokemon_data.max_hp)
    current_hp = max_hp

    last_move_name_id = &""
    status_container.clear()
    effect_container.clear()


func is_knocked_out() -> bool:
    return current_hp <= 0


func apply_damage(amount: int) -> int:
    var applied: int = clamp(
        amount,
        0,
        current_hp
    )

    current_hp -= applied
    return applied


func heal(amount: int) -> int:
    var previous_hp: int = current_hp

    current_hp = min(
        current_hp + max(amount, 0),
        max_hp
    )

    return current_hp - previous_hp


func can_use_move(
    move_name_id: StringName
) -> bool:
    if STATUS_RESOLVER.is_move_locked(
        self,
        move_name_id
    ):
        return false

    if move_name_id != last_move_name_id:
        return true

    return STATUS_RESOLVER.has_repeat_permission(
        self,
        move_name_id
    )


func mark_move_used(
    move_name_id: StringName
) -> void:
    if move_name_id == last_move_name_id:
        STATUS_RESOLVER.consume_repeat_permission(
            self,
            move_name_id
        )

    last_move_name_id = move_name_id
