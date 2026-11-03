extends SceneTree
## Real game integration fixture. Only the server seeds twelve wood on the first connection.
var game: Node
var server: bool = false
var restoring: bool = false
var age: float = 0.0
var first_key: String = ""
var seen: Dictionary = {}
var finish: bool = false
var verified: bool = false
var stop_after: float = -1.0

func _initialize() -> void:
	server = "--server" in OS.get_cmdline_user_args()
	restoring = "--restore-check" in OS.get_cmdline_user_args()
	call_deferred("_start")

func _start() -> void:
	game = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)

func _process(delta: float) -> bool:
	age += delta
	if age > 20.0:
		push_error("Reconnect integration timed out")
		quit(1)
		return false
	if game == null or not game.ready_world or not game.running:
		return false
	if stop_after >= 0 and age > stop_after and not finish:
		finish = true
		game.quit_game()
	if server:
		for id in game.players:
			if seen.has(id):
				continue
			seen[id] = true
			var key: String = game.session.player_key(id)
			if restoring:
				if game.inventories[id].count("wood") != 12:
					push_error("Inventory not restored after server restart")
					quit(1)
					return false
				print("RECONNECT_RESTART_SERVER_PASS inventory=12")
				stop_after = age + 1.0
			elif seen.size() == 1:
				first_key = key
				game.inventories[id].add("wood", 12)
			elif seen.size() == 2:
				if key != first_key or game.inventories[id].count("wood") != 12:
					push_error("Reconnected peer did not reclaim the same inventory")
					quit(1)
					return false
				print("RECONNECT_SERVER_PASS stable_identity=true inventory=12")
				stop_after = age + 1.0
	elif game.player != null and game.inventory.count("wood") == 12 and not verified:
		verified = true
		print("RECONNECT_CLIENT_PASS id=%d inventory=12" % game.session.local_id)
		game.quit_game()
	return false
