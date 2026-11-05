extends RefCounted
## Transient server-timed pings; never reveal another player's terrain discoveries.
var entries: Dictionary = {}
var cooldowns: Dictionary = {}

func create(actor: String, at: Vector2, origin: Vector3, profile: Dictionary, tribes, now: float) -> bool:
	if tribes.tribe_of(actor).is_empty() or now < float(cooldowns.get(actor, 0)) or not at.is_finite(): return false
	if at.distance_to(Vector2(origin.x, origin.z)) > 250.0: return false
	var cell := "%d,%d" % [floori(at.x / 20.0), floori(at.y / 20.0)]
	if not profile.get("cells", {}).has(cell): return false
	entries[actor] = {"owner": actor, "position": [at.x, at.y], "remaining": 20.0}
	cooldowns[actor] = now + 2.0
	return true

func advance(delta: float, online: Array) -> void:
	for actor in entries.keys():
		entries[actor]["remaining"] = maxf(0, float(entries[actor]["remaining"]) - maxf(0, delta))
		if entries[actor]["remaining"] <= 0 or actor not in online: entries.erase(actor)
	for actor in cooldowns.keys():
		if actor not in online: cooldowns.erase(actor)

func visible(actor: String, tribes, blocked: Dictionary = {}) -> Array:
	var own: String = tribes.tribe_of(actor)
	if own.is_empty(): return []
	var result: Array = []
	for sender in entries:
		if actor in blocked.get(sender, []) or sender in blocked.get(actor, []): continue
		var other: String = tribes.tribe_of(sender)
		if not other.is_empty() and (own == other or tribes.relations.get(tribes.pair_key(own, other), {}).get("status") == "allied"):
			result.append(entries[sender].duplicate(true))
	return result
