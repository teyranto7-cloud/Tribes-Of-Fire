extends RefCounted
## Shared immutable balance data. Rules own authority; JSON only defines values.
static var _data: Dictionary = {}
static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://Data/Balance.json"))
		if parsed is Dictionary: _data = parsed
	return _data
static func section(name: String) -> Dictionary:
	var value: Variant = data().get(name, {})
	return value.duplicate(true) if value is Dictionary else {}
static func number(group: String, key: String, fallback: float) -> float:
	var value: Variant = data().get(group, {}).get(key, fallback)
	return float(value) if (value is int or value is float) and is_finite(float(value)) else fallback
static func integer(group: String, key: String, fallback: int) -> int:
	return roundi(number(group, key, fallback))
