extends RefCounted
## Server-side combat decisions. Damage is returned to the authoritative runtime.
const Catalog = preload("res://Items/Catalog.gd")
var elapsed: float = 0.0
var cooldowns: Dictionary = {}
var dodge_cooldowns: Dictionary = {}

func tick(delta: float) -> void:
	if is_finite(delta) and delta > 0:
		elapsed += delta

func try_attack(body: Node3D, inventory, heavy: bool = false, ranged: bool = false) -> Dictionary:
	if not is_instance_valid(body) or not bool(body.get("authoritative")) or body.vitals.hp <= 0:
		return {"ok": false, "reason": "authority"}
	var key: int = body.get_instance_id()
	if float(cooldowns.get(key, 0)) > elapsed or body.attack_time > 0:
		return {"ok": false, "reason": "cooldown"}
	if bool(body.get("blocking")) or float(body.get("dodging")) > 0:
		return {"ok": false, "reason": "defending"}
	var weapon: String = inventory.equipped_item("hand")
	var definition: Dictionary = Catalog.get_item(weapon)
	if definition.is_empty():
		return {"ok": false, "reason": "weapon"}
	var is_bow := weapon == "bow"
	if ranged != is_bow:
		return {"ok": false, "reason": "weapon_type"}
	var cost := 18.0 if heavy else 8.0
	if is_bow:
		cost = 12.0
	if body.stamina < cost:
		return {"ok": false, "reason": "stamina"}
	if is_bow and not inventory.consume("arrow", 1):
		return {"ok": false, "reason": "ammunition"}
	var base_damage: int = Catalog.damage(weapon)
	if base_damage <= 0:
		return {"ok": false, "reason": "not_a_weapon"}
	var damage := clampi(roundi(base_damage * (1.3 if heavy else 1.0)), 1, 35)
	var cooldown := 0.95 if heavy else 0.6
	if is_bow:
		cooldown = 1.1
	var reach := 2.8 if weapon == "spear" else 2.3
	if is_bow:
		reach = 24.0
	body.stamina -= cost
	body.attack_time = 0.55
	cooldowns[key] = elapsed + cooldown
	inventory.wear_equipment("hand", 1)
	return {"ok": true, "damage": damage, "range": reach,
		"kind": "ranged" if is_bow else ("heavy" if heavy else "light"),
		"weapon": weapon, "cooldown": cooldown}

func select_target(body: Node3D, targets: Array, reach: float):
	if not is_instance_valid(body) or not is_finite(reach) or reach <= 0:
		return null
	var selected = null
	var nearest := reach
	var facing: Vector3 = -body.global_basis.z
	for target in targets:
		if not is_instance_valid(target) or target == body or not target is Node3D:
			continue
		var hp: int = int(target.hp) if "hp" in target else int(target.vitals.hp)
		if hp <= 0:
			continue
		var offset: Vector3 = target.global_position - body.global_position
		var distance := offset.length()
		if distance < 0.01 or distance > nearest:
			continue
		var planar := Vector3(offset.x, 0, offset.z).normalized()
		if planar.dot(facing) < (0.88 if reach > 10 else 0.35):
			continue
		var query := PhysicsRayQueryParameters3D.create(body.global_position + Vector3.UP,
			target.global_position + Vector3.UP * 0.7, 1)
		if body is CollisionObject3D:
			query.exclude = [body.get_rid()]
		var obstruction := body.get_world_3d().direct_space_state.intersect_ray(query)
		if not obstruction.is_empty():
			continue
		selected = target
		nearest = distance
	return selected

static func mitigate(raw: int, inventory, blocking: bool = false, dodging: bool = false) -> int:
	if raw <= 0 or dodging:
		return 0
	var protection: float = Catalog.armor(inventory.equipped_item("armor"))
	var result := maxi(1, ceili(raw * (1.0 - clampf(protection, 0.0, 0.65))))
	if blocking:
		result = maxi(1, ceili(result * (0.25 if inventory.equipped_item("offhand") == "shield" else 0.55)))
	if protection > 0:
		inventory.wear_equipment("armor", 1)
	if blocking and inventory.equipped_item("offhand") == "shield":
		inventory.wear_equipment("offhand", 1)
	return result

func set_guard(body, enabled: bool) -> void:
	if body != null and bool(body.get("authoritative")):
		body.blocking = enabled and body.vitals.hp > 0 and body.stamina >= 2.0

func dodge(body) -> bool:
	if body == null or not bool(body.get("authoritative")) or body.vitals.hp <= 0 or body.stamina < 20:
		return false
	var key: int = body.get_instance_id()
	if float(dodge_cooldowns.get(key, 0)) > elapsed or float(body.get("dodging")) > 0:
		return false
	body.stamina -= 20
	body.blocking = false
	body.dodging = 0.55
	dodge_cooldowns[key] = elapsed + 1.3
	return true
