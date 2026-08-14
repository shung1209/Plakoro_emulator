extends RefCounted


const KIND_MOVE_DAMAGE: StringName = &"move_damage"
const KIND_EFFECT_DAMAGE: StringName = &"effect_damage"
const KIND_WEAKNESS_DAMAGE: StringName = &"weakness_damage"
const KIND_SELF_DAMAGE: StringName = &"self_damage"
const KIND_HP_UPDATE: StringName = &"hp_update"


static func build_target_damage_queue(
    resolution_events: Array,
    hp_before: int,
    hp_after: int
) -> Array[Dictionary]:
    var queue: Array[Dictionary] = []
    var displayed_hp: int = max(
        hp_before,
        0
    )
    var final_hp: int = max(
        hp_after,
        0
    )
    var remaining_damage: int = max(
        displayed_hp - final_hp,
        0
    )
    var effect_trigger_index: int = 0
    var weakness_trigger_index: int = 0

    for raw_event: Variant in resolution_events:
        if remaining_damage <= 0:
            break

        if not raw_event is Dictionary:
            continue

        var event: Dictionary = (
            raw_event as Dictionary
        )
        var kind: StringName = StringName(
            event.get(
                "kind",
                &"damage"
            )
        )
        var requested_amount: int = max(
            int(
                event.get(
                    "amount",
                    0
                )
            ),
            0
        )
        var applied_amount: int = min(
            requested_amount,
            remaining_damage
        )

        if applied_amount <= 0:
            continue

        if kind == KIND_EFFECT_DAMAGE:
            effect_trigger_index += 1
        elif kind == KIND_WEAKNESS_DAMAGE:
            weakness_trigger_index += 1

        var next_hp: int = max(
            final_hp,
            displayed_hp - applied_amount
        )

        queue.append(
            {
                "kind": kind,
                "label": String(
                    event.get(
                        "label",
                        "Damage"
                    )
                ),
                "amount": applied_amount,
                "stage": StringName(
                    event.get(
                        "stage",
                        &""
                    )
                ),
                "effect_trigger_index": (
                    effect_trigger_index
                    if kind == KIND_EFFECT_DAMAGE
                    else 0
                ),
                "weakness_trigger_index": (
                    weakness_trigger_index
                    if kind == KIND_WEAKNESS_DAMAGE
                    else 0
                )
            }
        )
        queue.append(
            {
                "kind": KIND_HP_UPDATE,
                "label": "HP Update",
                "hp_before": displayed_hp,
                "hp_after": next_hp,
                "amount": applied_amount,
                "source_kind": kind,
                "effect_trigger_index": (
                    effect_trigger_index
                    if kind == KIND_EFFECT_DAMAGE
                    else 0
                ),
                "weakness_trigger_index": (
                    weakness_trigger_index
                    if kind == KIND_WEAKNESS_DAMAGE
                    else 0
                )
            }
        )

        displayed_hp = next_hp
        remaining_damage -= applied_amount

    if displayed_hp != final_hp:
        var reconcile_amount: int = max(
            displayed_hp - final_hp,
            0
        )

        queue.append(
            {
                "kind": &"reconcile_damage",
                "label": "Effect Damage",
                "amount": reconcile_amount,
                "stage": &"fallback"
            }
        )
        queue.append(
            {
                "kind": KIND_HP_UPDATE,
                "label": "HP Update",
                "hp_before": displayed_hp,
                "hp_after": final_hp,
                "amount": reconcile_amount,
                "source_kind": &"reconcile_damage"
            }
        )

    return queue


static func build_self_damage_queue(
    self_damage_events: Array,
    hp_before: int,
    hp_after: int
) -> Array[Dictionary]:
    var queue: Array[Dictionary] = []
    var displayed_hp: int = max(
        hp_before,
        0
    )
    var final_hp: int = max(
        hp_after,
        0
    )
    var remaining_damage: int = max(
        displayed_hp - final_hp,
        0
    )
    var self_damage_index: int = 0

    for raw_event: Variant in self_damage_events:
        if remaining_damage <= 0:
            break

        if not raw_event is Dictionary:
            continue

        var event: Dictionary = raw_event as Dictionary
        var requested_amount: int = max(
            int(
                event.get(
                    "amount",
                    0
                )
            ),
            0
        )
        var applied_amount: int = min(
            requested_amount,
            remaining_damage
        )

        if applied_amount <= 0:
            continue

        self_damage_index += 1

        var next_hp: int = max(
            final_hp,
            displayed_hp - applied_amount
        )

        queue.append(
            {
                "kind": KIND_SELF_DAMAGE,
                "label": String(
                    event.get(
                        "label",
                        "Self Damage"
                    )
                ),
                "amount": applied_amount,
                "reason": StringName(
                    event.get(
                        "reason",
                        &"self_damage"
                    )
                ),
                "self_damage_index": self_damage_index
            }
        )
        queue.append(
            {
                "kind": KIND_HP_UPDATE,
                "label": "HP Update",
                "hp_before": displayed_hp,
                "hp_after": next_hp,
                "amount": applied_amount,
                "source_kind": KIND_SELF_DAMAGE,
                "self_damage_index": self_damage_index
            }
        )

        displayed_hp = next_hp
        remaining_damage -= applied_amount

    if displayed_hp != final_hp:
        var reconcile_amount: int = max(
            displayed_hp - final_hp,
            0
        )
        queue.append(
            {
                "kind": KIND_SELF_DAMAGE,
                "label": "Self Damage",
                "amount": reconcile_amount,
                "reason": &"fallback",
                "self_damage_index": 0
            }
        )
        queue.append(
            {
                "kind": KIND_HP_UPDATE,
                "label": "HP Update",
                "hp_before": displayed_hp,
                "hp_after": final_hp,
                "amount": reconcile_amount,
                "source_kind": KIND_SELF_DAMAGE,
                "self_damage_index": 0
            }
        )

    return queue


static func validate_damage_order(
    queue: Array[Dictionary]
) -> bool:
    var phase: int = 0

    for step: Dictionary in queue:
        var kind: StringName = StringName(
            step.get(
                "kind",
                &""
            )
        )

        if kind == KIND_HP_UPDATE:
            continue

        if kind == KIND_MOVE_DAMAGE:
            if phase > 0:
                return false
            phase = 1
        elif kind == KIND_EFFECT_DAMAGE:
            if phase > 2:
                return false
            phase = 2
        elif kind == KIND_WEAKNESS_DAMAGE:
            if phase > 3:
                return false
            phase = 3
        elif kind == KIND_SELF_DAMAGE:
            phase = 4

    return true



static func build_full_damage_queue(
    target_events: Array,
    target_hp_before: int,
    target_hp_after: int,
    self_damage_events: Array,
    actor_hp_before: int,
    actor_hp_after: int
) -> Array[Dictionary]:
    var queue: Array[Dictionary] = build_target_damage_queue(
        target_events,
        target_hp_before,
        target_hp_after
    )

    queue.append_array(
        build_self_damage_queue(
            self_damage_events,
            actor_hp_before,
            actor_hp_after
        )
    )

    return queue
