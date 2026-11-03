extends SceneTree
var checks: int = 0
var failed: int = 0
var started: int = Time.get_ticks_usec()
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)
	checks += 1
	if game.ready_world or game.runtime != null:
		failed += 1
		push_error("Early-close fixture must stop during asynchronous world loading")
	game.quit_game()
	checks += 1
	if not game.quitting:
		failed += 1
		push_error("Closing during loading must enter shutdown without a null-runtime exception")
	print("STARTUP_CLOSE CHECKS=%d FAILED=%d" % [checks, failed])
	if failed > 0:
		quit(1)
		return

func _process(_delta: float) -> bool:
	if Time.get_ticks_usec() - started > 4000000:
		push_error("Early shutdown failed to close its process")
		quit(1)
	return false
