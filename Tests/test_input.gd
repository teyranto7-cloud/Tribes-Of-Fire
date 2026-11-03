extends SceneTree
const MainScene = preload("res://Scenes/Main.tscn")
const Store = preload("res://Persistence/Store.gd")
var checks: int = 0
var failed: int = 0
var game
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
func run() -> void:
	game = MainScene.instantiate()
	root.add_child(game)
	game.save_folder = "user://input-tests/%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	while not game.ready_world:
		await process_frame
	check(game.menu_camera.current, "Menu possui camera antes da primeira jornada")
	game.new_game(718991)
	await frames(30)
	check(game.player != null and game.player.enabled and game.player.camera.current,
		"Nova jornada cria personagem e ativa camera e controles")
	var origin: Vector3 = game.player.position
	Input.action_press("right")
	await frames(30)
	Input.action_release("right")
	check(game.player.position.x > origin.x + 1.0,
		"Input real atravessa Main, Session e fisica autoritativa")
	await frames(15)
	game.hud.show_panel("inventory")
	check(not game.player.enabled and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"Inventario libera cursor e bloqueia controles")
	var paused_origin: Vector3 = game.player.position
	Input.action_press("right")
	await frames(30)
	Input.action_release("right")
	check(absf(game.player.position.x - paused_origin.x) < 0.1,
		"Input de movimento no inventario nao desloca personagem")
	game.hud.show_panel("")
	check(game.player.enabled, "Fechar inventario reativa controles")
	Input.action_press("left")
	await frames(30)
	Input.action_release("left")
	check(game.player.position.x < paused_origin.x - 1.0,
		"Movimento volta a funcionar depois do inventario")
	check(game.player.is_on_floor(), "Colisao com terreno se mantem no fluxo real")
	print("INPUT CHECKS=%d FAILED=%d" % [checks, failed])
	await game.quit_game(0 if failed == 0 else 1,false)
