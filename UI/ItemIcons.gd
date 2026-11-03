extends RefCounted
static var cache: Dictionary = {}
static func icon(item: String) -> Texture2D:
	if not cache.has(item):
		var path := "res://Assets/UI/Items/" + item + ".svg"
		cache[item] = load(path) if ResourceLoader.exists(path) else null
	return cache[item]
