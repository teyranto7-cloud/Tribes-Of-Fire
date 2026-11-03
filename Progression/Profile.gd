extends RefCounted
const Balance = preload("res://Game/Balance.gd")
const SKILLS := ["gathering", "hunting", "building", "cooking", "combat", "crafting", "cold", "farming", "fishing"]
var skills: Dictionary = {}
var learned: Array = []
func _init() -> void:
	for skill in SKILLS: skills[skill] = 0.0
func award(skill: String, amount: float) -> void:
	if skill in SKILLS and is_finite(amount) and amount > 0:
		skills[skill] = minf(1000000, float(skills.get(skill, 0)) + amount)
func level(skill: String) -> int:
	return mini(Balance.integer("progression", "maximum_level", 20), int(sqrt(float(skills.get(skill, 0)) / maxf(1, Balance.number("progression", "xp_per_level", 25)))))
func state() -> Dictionary:
	return {"skills": skills.duplicate(), "learned": learned.duplicate()}
func restore(record: Dictionary) -> void:
	if not valid(record): return
	skills = record["skills"].duplicate()
	learned = record["learned"].duplicate()
static func technologies() -> Dictionary:
	return Balance.section("technologies")
static func era(known: Array) -> int:
	var current := 0
	var definitions := technologies()
	for technology in known:
		if definitions.has(technology): current = maxi(current, int(definitions[technology]["era"]))
	return current
static func valid(record: Dictionary) -> bool:
	if not record.get("skills") is Dictionary or record["skills"].size() != SKILLS.size() or not record.get("learned") is Array or record["learned"].size() > technologies().size(): return false
	for skill in SKILLS:
		var xp: Variant = record["skills"].get(skill)
		if not (xp is int or xp is float) or not is_finite(float(xp)) or xp < 0 or xp > 1000000: return false
	var seen: Array = []
	for technology in record["learned"]:
		if not technology is String or not technologies().has(technology) or technology in seen: return false
		seen.append(technology)
	return true
