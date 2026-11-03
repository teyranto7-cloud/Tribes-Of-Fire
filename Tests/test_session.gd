extends SceneTree
## Run with Tools/test_network.py: real ENet server plus two separate client processes.

const SessionScript = preload("res://Networking/Session.gd")
var session: Node
var server: bool = false
var port: int = 24679
var age: float = 0.0
var tick: float = 0.0
var finish_age: float = -1.0
var inputs: Dictionary = {}
var actions: Dictionary = {}
var seen: Dictionary = {}
var attacked: bool = false
var invalid_signal: bool = false
var quitting: bool = false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--session-server":
			server = true
		elif argument.begins_with("--port="):
			port = int(argument.trim_prefix("--port="))
	var game := Node.new()
	game.name = "TribesOfFire"
	root.add_child(game)
	session = SessionScript.new()
	session.name = "Session"
	game.add_child(session)
	session.intent_received.connect(_intent)
	session.action_received.connect(_action)
	session.peer_joined.connect(func(id: int): seen[id] = true)
	session.state_received.connect(_state)
	session.failed.connect(func(message: String):
		push_error(message)
		quit(1))
	call_deferred("_start")

func _start() -> void:
	var error: Error
	if server:
		error = session.host_game(port, 2, true)
	else:
		error = session.join_game("127.0.0.1", port)
	if error != OK:
		push_error("ENet setup failed: %s" % error_string(error))
		quit(1)

func _process(delta: float) -> bool:
	age += delta
	if age > 12.0:
		push_error("ENet test timed out: server=%s, seen=%d, inputs=%d, actions=%d, rejected=%d" %
			[server, seen.size(), inputs.size(), actions.size(), session.rejected_commands])
		quit(1)
		return false
	if finish_age >= 0.0 and age >= finish_age:
		print("SESSION_SERVER_PASS clients=2 intents=2 actions=2 malicious_rejected=%d" % session.rejected_commands)
		quit(0)
		return false
	tick += delta
	if tick < 0.1:
		return false
	tick = 0.0
	if server:
		var passed: bool = seen.size() == 2 and inputs.size() == 2 and actions.size() == 2 \
			and session.rejected_commands >= 4 and not invalid_signal
		session.broadcast({"passed": passed, "inputs": inputs.size(), "actions": actions.size()})
		if passed and finish_age < 0:
			finish_age = age + 0.6
	elif session.local_id > 0:
		if not attacked:
			attacked = true
			# Intentionally bypass the public client's sanitizer to exercise server trust boundaries.
			session._submit_intent.rpc_id(1, {"move": [1000.0, 0.0], "yaw": 0.0})
			session._submit_action.rpc_id(1, "weather_storm")
			session.send_action("attack")
		session.send_intent({"move": [1.0, 1.0], "yaw": 0.2, "jump": false, "sprint": true})
	return false

func _intent(id: int, data: Dictionary) -> void:
	var movement: Array = data.get("move", [])
	if movement.size() != 2 or Vector2(movement[0], movement[1]).length() > 1.00001:
		invalid_signal = true
	inputs[id] = true

func _action(id: int, action: String) -> void:
	if action != "attack":
		invalid_signal = true
	actions[id] = true

func _state(state: Dictionary) -> void:
	if state.get("passed", false) and not quitting:
		quitting = true
		print("SESSION_CLIENT_PASS id=%d authoritative_snapshot=true" % session.local_id)
		await session.graceful_leave()
		quit(0)
