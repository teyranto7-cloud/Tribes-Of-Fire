extends RefCounted
## Reliable deltas keep owner-filtered snapshots intact without resending unchanged fields.
const MAX_DEPTH := 8
static func difference(previous: Dictionary, current: Dictionary, depth: int = 0) -> Dictionary:
	var changed: Dictionary = {}
	var removed: Array = []
	var children: Dictionary = {}
	for key in previous:
		if not current.has(key): removed.append(key)
	for key in current:
		if previous.has(key) and previous[key] == current[key]: continue
		if depth < MAX_DEPTH and previous.get(key) is Dictionary and current[key] is Dictionary:
			children[key] = difference(previous[key], current[key], depth + 1)
		else:
			changed[key] = current[key]
	return {"set": changed, "remove": removed, "children": children}
static func apply(previous: Dictionary, patch: Dictionary, depth: int = 0) -> Dictionary:
	if depth > MAX_DEPTH + 1 or not patch.get("set") is Dictionary or not patch.get("remove") is Array or not patch.get("children") is Dictionary:
		return {}
	var result := previous.duplicate(true)
	for key in patch["remove"]: result.erase(key)
	for key in patch["set"]: result[key] = patch["set"][key]
	for key in patch["children"]:
		if not result.get(key) is Dictionary or not patch["children"][key] is Dictionary: return {}
		result[key] = apply(result[key], patch["children"][key], depth + 1)
	return result
