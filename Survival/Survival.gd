extends RefCounted
## Server-owned needs. Exposure owns regeneration so health is never advanced twice.

const HUNGER_SECONDS := 1800.0
const THIRST_SECONDS := 1200.0
const DAMAGE_INTERVAL := 15.0
static var FOOD:Dictionary=preload("res://Items/Catalog.gd")._statistics("hunger")
var hunger: float = 100.0
var thirst: float = 100.0
var starvation: float = 0.0
var dehydration: float = 0.0
var damage_count: int = 0

func reset() -> void:
	hunger = 100.0
	thirst = 100.0
	starvation = 0.0
	dehydration = 0.0
	damage_count = 0

func is_safe() -> bool:
	return hunger > 0.0 and thirst > 0.0

func advance(delta: float, vitals) -> void:
	if not is_finite(delta) or delta <= 0.0 or vitals.hp <= 0:
		return
	# Only the portion after a need actually reaches zero counts toward damage.
	var hungry_for := maxf(0.0, delta - hunger * HUNGER_SECONDS / 100.0)
	var thirsty_for := maxf(0.0, delta - thirst * THIRST_SECONDS / 100.0)
	hunger = maxf(0.0, hunger - delta * 100.0 / HUNGER_SECONDS)
	thirst = maxf(0.0, thirst - delta * 100.0 / THIRST_SECONDS)
	if hunger > 0.00000001:
		starvation = 0.0
	else:
		hunger = 0.0
		starvation += hungry_for
	if thirst > 0.00000001:
		dehydration = 0.0
	else:
		thirst = 0.0
		dehydration += thirsty_for
	# Independent bounded intervals prevent duplicate damage at variable FPS.
	var hunger_ticks := int(floor((starvation + 0.00000001) / DAMAGE_INTERVAL))
	var thirst_ticks := int(floor((dehydration + 0.00000001) / DAMAGE_INTERVAL))
	starvation = maxf(0.0, starvation - hunger_ticks * DAMAGE_INTERVAL)
	dehydration = maxf(0.0, dehydration - thirst_ticks * DAMAGE_INTERVAL)
	for tick in range(mini(100, hunger_ticks + thirst_ticks)):
		if vitals.hp <= 0:
			break
		vitals.damage(1)
		damage_count += 1

func eat(inventory, item: String = "berries") -> bool:
	if not FOOD.has(item) or hunger >= 100.0:
		return false
	if not inventory.consume(item, 1):
		return false
	hunger = minf(100.0, hunger + float(FOOD[item]))
	starvation = 0.0
	return true

func drink(amount: float = 35.0) -> bool:
	# The server caller must establish a nearby potable source or consume a water item.
	if not is_finite(amount) or amount <= 0.0 or thirst >= 100.0:
		return false
	thirst = minf(100.0, thirst + minf(amount, 100.0))
	dehydration = 0.0
	return true

func cook(inventory, near_fire: bool) -> bool:
	if not near_fire:
		return false
	# Consuming the final raw-meat stack may provide the output slot. A failed
	# output must restore all inputs, equipment and stack layout atomically.
	return inventory.transact({"raw_meat": 1}, {"cooked_meat": 1})

func state() -> Dictionary:
	return {"hunger": hunger, "thirst": thirst, "starvation": starvation,
		"dehydration": dehydration, "damage_count": damage_count}

func restore(data: Dictionary) -> void:
	if not valid(data):
		return
	hunger = float(data["hunger"])
	thirst = float(data["thirst"])
	starvation = float(data["starvation"])
	dehydration = float(data["dehydration"])
	damage_count = int(data.get("damage_count", 0))

static func valid(data: Dictionary) -> bool:
	for key in ["hunger", "thirst", "starvation", "dehydration"]:
		var value: Variant = data.get(key)
		var maximum := 100.0 if key in ["hunger", "thirst"] else DAMAGE_INTERVAL
		if not (value is int or value is float) or not is_finite(float(value)) \
				or float(value) < 0.0 or float(value) > maximum:
			return false
	var damage: Variant = data.get("damage_count", 0)
	return (damage is int or damage is float) and is_finite(float(damage)) \
		and float(damage) >= 0 and float(damage) <= 1000000000 \
		and float(damage) == floorf(float(damage))
