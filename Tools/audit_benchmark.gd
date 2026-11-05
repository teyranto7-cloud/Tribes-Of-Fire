extends SceneTree
## Identical seeded scene for before/after audit; software-renderer diagnostic only.
var game
var results:Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if DisplayServer.get_name()=="headless":printerr("Rendering display required");quit(1);return
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://audit-benchmark";root.add_child(game)
	while not game.ready_world:await process_frame
	game.new_game(718991);game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.player.set_physics_process(false);game.set_controls(false)
	game.graphics.begin_edit();game.graphics.choose_preset(0);game.graphics.pending["fps"]=0;game.graphics.pending["vsync"]=false;game.graphics.preview(game.world,root,game.player)
	game.runtime._add_workshop("workbench",Vector3(0,game.world.terrain_height(0,4),4),game.runtime.key(1))
	game.runtime.workshops[-1].machine["recipe"]="plank";game.runtime.workshops[-1].machine["output"]={"plank":2}
	game.player.position=game.runtime.workshops[-1].position+Vector3(0,0.2,2)
	game.menu_camera.position=Vector3(13,9,15);game.menu_camera.look_at(Vector3(0,2,-4));game.menu_camera.current=true
	var deadline:=Time.get_ticks_msec()+25000
	while Time.get_ticks_msec()<deadline:
		if game.world._wanted.keys().all(func(k):return game.world._chunks.has(k)):break
		await process_frame
	game.set_process(false)
	for scene in ["day","station","night","storm"]:
		game.clock.elapsed=2100 if scene=="night" else 800
		game.weather.condition="storm" if scene=="storm" else "clear";game.weather.current=game.weather.PRESETS[game.weather.condition].duplicate()
		game.world.apply_weather(game.weather.state());game.world.illuminate(game.clock)
		game.runtime.factory_view={"station":0,"kind":"workbench","state":game.runtime.workshops[0].machine.duplicate(true)}
		game.hud.show_panel("factory" if scene=="station" else "")
		game.set_controls(false)
		await create_timer(1).timeout
		var frames:Array[float]=[];var process_ms:=0.0;var physics_ms:=0.0;var draws:=0.0
		var start:=Time.get_ticks_usec();var last:=start
		while Time.get_ticks_usec()-start<4000000:
			await RenderingServer.frame_post_draw
			var now:=Time.get_ticks_usec();frames.append(float(now-last)/1000);last=now
			process_ms+=Performance.get_monitor(Performance.TIME_PROCESS)*1000;physics_ms+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000
			draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var elapsed:=float(Time.get_ticks_usec()-start)/1000000;frames.sort()
		var row:={"scene":scene,"frames":frames.size(),"fps":frames.size()/elapsed,"p50_ms":frames[int(frames.size()*0.5)],"p95_ms":frames[mini(frames.size()-1,int(frames.size()*0.95))],"process_ms":process_ms/frames.size(),"physics_ms":physics_ms/frames.size(),"draw_calls":draws/frames.size(),"nodes":get_node_count(),"godot_static_bytes":OS.get_static_memory_usage()}
		results.append(row);print("AUDIT_PERF ",JSON.stringify(row))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/audit"))
	var f:=FileAccess.open("res://builds/audit/performance.json",FileAccess.WRITE);f.store_string(JSON.stringify({"version":ProjectSettings.get_setting("application/config/version"),"seed":718991,"resolution":[root.size.x,root.size.y],"hardware":game.graphics.hardware(),"samples":results,"gpu_time_ms":null,"method":"Very Low, fixed camera/seed, wait for wanted chunks, 1s warmup + 4s samples. Main world clock held, live physics/AI. Xorg/llvmpipe software; not target hardware or sustained performance."},"\t"));f.close()
	await game.quit_game(0,false)
