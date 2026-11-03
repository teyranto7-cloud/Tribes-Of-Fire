extends SceneTree
const Player = preload("res://Player/Player.gd")
var failures: int = 0
var checks: int = 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var room := Node3D.new()
	root.add_child(room)
	var ground := StaticBody3D.new()
	room.add_child(ground)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	var player = Player.new()
	player.local_control = false
	room.add_child(player)
	player.position = Vector3(0, 0.2, 0)
	for frame in range(30):
		await physics_frame
	check(player.is_on_floor(), "Player settles on physical ground")
	for frame in range(60):
		player.set_intent({"move": [5.0, 0.0], "yaw": 0.0, "sprint": false})
		await physics_frame
	check(player.position.x > 3 and player.position.x < 4.5, "Server movement clamps diagonal/oversized intent to walk speed")
	check(player.is_on_floor(), "Walking maintains ground contact")
	for frame in range(90):
		await physics_frame
	check(Vector2(player.velocity.x, player.velocity.z).length() < 0.01, "Expired intent stops player")
	var initial_stamina: float = player.stamina
	check(player.attack(), "Authoritative attack succeeds")
	check(is_equal_approx(player.stamina, initial_stamina - 8), "Attack costs eight stamina")
	check(not player.attack(), "Cooldown blocks repeated attack")
	player.vitals.hp = 50
	for frame in range(200):
		await physics_frame
	check(player.vitals.hp == 50, "Player does not advance vitals twice")
	var replica = Player.new()
	replica.authoritative = false
	replica.local_control = false
	room.add_child(replica)
	replica.apply_state(player.export_state())
	await physics_frame
	check(replica.vitals.hp == 50, "Replica receives authoritative vitals")
	check(replica.position.distance_to(player.position) < 0.1, "Replica initializes from server position")
	check(not replica.attack(), "Replica cannot authorize attack")
	player.queue_free()
	replica.queue_free()
	await process_frame
	print("PLAYER_CHECKS=%d FAILED=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
