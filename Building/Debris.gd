extends Node3D
## Bounded cosmetic rigid debris; no damage or player collision.
const Shapes = preload("res://World/Shapes.gd")
var remaining := 3.0
static var live := 0
var counted := false
func setup(tier: String, destroyed: bool, uid: int) -> void:
	if DisplayServer.get_name() == "headless" or live >= 6: queue_free(); return
	counted = true; live += 1
	var rng := RandomNumberGenerator.new(); rng.seed = uid
	var stone := tier in ["stone", "concrete", "metal"]
	var color := Color("#959a8c") if stone else Color("#9b7049")
	for i in range(6 if destroyed else 2):
		var body := RigidBody3D.new(); body.collision_layer = 4; body.collision_mask = 1; body.mass = .2; body.position = Vector3(rng.randf_range(-.3,.3),.9,rng.randf_range(-.2,.2))
		add_child(body)
		var shape := BoxShape3D.new(); shape.size = Vector3(.18,.15,.18) if stone else Vector3(.1,.1,.35)
		Shapes.box(body,shape.size,Vector3.ZERO,color)
		Shapes.collider(body,shape,Vector3.ZERO)
		body.linear_velocity = Vector3(rng.randf_range(-1.8,1.8),rng.randf_range(1,3),rng.randf_range(-1.8,1.8))
		body.angular_velocity = Vector3(rng.randf_range(-4,4),rng.randf_range(-4,4),rng.randf_range(-4,4))
func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0: queue_free()
func _exit_tree() -> void:
	if counted: live -= 1
