extends RefCounted
static var cache: Dictionary = {}
static func icon(item: String) -> Texture2D:
	if not cache.has(item):
		var path:String=preload("res://Items/Catalog.gd").get_item(item).get("icon","")
		cache[item] = load(path) if ResourceLoader.exists(path) else null
	return cache[item]
