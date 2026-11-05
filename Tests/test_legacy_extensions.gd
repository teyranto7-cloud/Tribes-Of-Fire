extends SceneTree
const Store = preload("res://Persistence/Store.gd")
var checks := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed += 1; push_error(message)
func _initialize() -> void:
	var legacy := {"version": 3, "seed": 1337, "cut": [], "fires": [], "shelters": [], "phase": 450.0,
		"weather": preload("res://Weather/Weather.gd").new().serialize(),
		"players": {"1": {"position": [0, 2, 0], "hp": 100, "inventory": {"axe": 1, "wood": 0, "campfire": 0, "shelter": 0}, "craft_requests": "unsupported-field"}},
		"energy_grid": {"nodes": null}, "automation": "unsupported-field"}
	check(Store.valid(legacy), "Legacy required fields remain readable")
	var migrated := Store.migrate(legacy)
	check(not migrated.has("energy_grid") and not migrated.has("automation"), "Legacy migration discards unsupported unvalidated world extensions")
	check(not migrated["players"]["1"].has("craft_requests"), "Legacy migration discards unsupported request history")
	check(Store.valid(migrated), "Migrated state satisfies the modern schema before gameplay")
	print("LEGACY_EXTENSIONS CHECKS=%d FAILED=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)
