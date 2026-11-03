extends SceneTree
## Real 3-seed views and short measured renderer samples; no hardware certification.
var game
var results:Array=[]
func _initialize()->void:call_deferred("run")
func run()->void:
	if DisplayServer.get_name()=="headless":quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/screenshots/frontier"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/reports"))
	game=load("res://Scenes/Main.tscn").instantiate();root.add_child(game)
	while not game.ready_world:await process_frame
	game.graphics.begin_edit();game.graphics.choose_preset(0);game.graphics.pending["fps"]=0;game.graphics.pending["vsync"]=false
	game.graphics.preview(game.world,root,game.player)
	for seed_value in [718991,12345,90210]:
		game.save_folder="user://frontier-capture/%d-%d"%[OS.get_process_id(),seed_value]
		var started:=Time.get_ticks_usec()
		game.new_game(seed_value)
		var generation_ms:=(Time.get_ticks_usec()-started)/1000.0
		game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
		game.player.set_physics_process(false);game.set_controls(false);game.hud.show_panel("");game.set_controls(false)
		game.clock.elapsed=800
		var targets:=[Vector3(0,0,0),Vector3(game.world.sampler.river_x(180),0,180),game.world.sampler.waterfall]
		for i in range(targets.size()):
			var at:Vector3=targets[i];at.y=game.world.terrain_height(at.x,at.z)
			game.player.position=at+Vector3.UP*0.3
			game.world.update_streaming([game.player.position])
			var deadline:=Time.get_ticks_msec()+10000
			while not game.world.has_terrain_at(at) and Time.get_ticks_msec()<deadline:await process_frame
			game.menu_camera.position=at+Vector3(22,17,26);game.menu_camera.look_at(at+Vector3.UP*1.5);game.menu_camera.current=true
			await create_timer(1).timeout
			await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image()
			if image==null or image.is_empty():quit(1);return
			image.save_png("res://builds/screenshots/frontier/%d-%d.png"%[seed_value,i])
			var samples:Array[float]=[];var last:=Time.get_ticks_usec();var sample_start:=last;var calls:=0.0;var peak:=0
			while Time.get_ticks_usec()-sample_start<2500000:
				await RenderingServer.frame_post_draw
				var now:=Time.get_ticks_usec();samples.append((now-last)/1000.0);last=now
				calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				peak=maxi(peak,OS.get_static_memory_usage())
			var elapsed:=(Time.get_ticks_usec()-sample_start)/1000000.0;samples.sort()
			results.append({"seed":seed_value,"view":i,"samples":samples.size(),"fps":samples.size()/elapsed,"p95_ms":samples[int(samples.size()*0.95)],"draw_calls":calls/samples.size(),"loaded_chunks":game.world._chunks.size(),"tree_nodes":game.world.trees.size(),"static_memory_bytes":peak,"generation_ms":generation_ms})
			print("FRONTIER_RENDER ",JSON.stringify(results[-1]))
	var file:=FileAccess.open("res://builds/reports/frontier-performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"reference_hardware_verified":false,"preset":"Very Low","resolution":[root.size.x,root.size.y],"method":"1s warmup + 2.5s per view, three seeds; software rendering","results":results},"\t"));file.close()
	game.quit_game(0,false)
