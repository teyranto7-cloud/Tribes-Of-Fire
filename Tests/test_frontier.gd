extends SceneTree
const Terrain=preload("res://World/Terrain.gd")
var checks:=0
var failed:=0
var game
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failed+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var fingerprints:Array=[]
	for seed_value in [718991,12345,90210]:
		var descriptor:={"seed":seed_value,"generator":3,"size":1536}
		var a=Terrain.new(descriptor);var b=Terrain.new(descriptor)
		var fingerprint:=0.0
		for z in range(-600,601,80):
			for x in range(-600,601,80):
				check(is_equal_approx(a.height(x,z),b.height(x,z)),"Seed reproduces height")
				check(a.biome(x,z)==b.biome(x,z),"Seed reproduces biomes")
				fingerprint+=a.height(x,z)
		fingerprints.append(fingerprint)
		for index in range(100):
			var at:Vector3=a.spawn_point(index)
			check(at.y>a.WATER_LEVEL+1,"Spawn is dry")
			var gradient:=Vector2(a.height(at.x+0.5,at.z)-a.height(at.x-0.5,at.z),a.height(at.x,at.z+0.5)-a.height(at.x,at.z-0.5)).length()
			check(gradient<0.6,"Spawn slope is walkable")
		for z in range(-600,601,40):
			var x:float=a.river_x(z)
			check(a.height(x,z)<a.WATER_LEVEL,"Continuous river occupies a depression")
			check(a.height(x+50,z)>a.height(x,z),"Valley rises toward banks")
			check(a.watershed.current(z)>0 and a.watershed.width(z)>=8,"River width and current are bounded")
	check(absf(fingerprints[0]-fingerprints[1])>1 and absf(fingerprints[1]-fingerprints[2])>1,"Three seeds produce distinct worlds")
	# Historical samplers remain versioned; reload cannot silently regenerate them.
	for version in [0,1,2]:
		var descriptor:={"seed":1337,"generator":version,"size":128 if version==0 else (320 if version==1 else 1536)}
		var a=Terrain.new(descriptor);var b=Terrain.new(descriptor)
		check(is_equal_approx(a.height(18,29),b.height(18,29)),"Historical generator remains reproducible")
	game=load("res://Scenes/Main.tscn").instantiate();root.add_child(game)
	while not game.ready_world:await process_frame
	for seed_value in [718991,12345,90210]:
		game.save_folder="user://frontier/%d-%d"%[OS.get_process_id(),seed_value]
		game.new_game(seed_value);game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
		await physics_frame;await physics_frame
		for z in game.world.sampler.watershed.crossings:
			var x:float=game.world.sampler.river_x(z)
			var ray:=PhysicsRayQueryParameters3D.create(Vector3(x,10,z),Vector3(x,-6,z),1)
			var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(ray)
			check(not hit.is_empty() and hit["collider"].is_in_group("seed_bridge"),"Seeded river has physical crossing")
		for i in range(100):
			var at:Vector3=game.world.sampler.spawn_point(i)
			var shape:=SphereShape3D.new();shape.radius=0.4
			var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP
			query.collision_mask=1;query.exclude=[game.player.get_rid()]
			check(game.world.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"Spawn does not intersect a rock or structure")
		var tree=game.world.trees[0];tree.hit();tree.hit();tree.hit();game.world.record_tree_cut(tree.tree_id)
		game.runtime.mining.stocks[0]=0
		var at:=Vector3(-8,0,-12);at.y=game.world.terrain_height(at.x,at.z)
		check(game.world.dig(at),"New world supports persistent terrain edits")
		await process_frame;await process_frame
		var edited:float=game.world.terrain_height(at.x,at.z)
		var identity:String=game.session.player_key(1)
		var chest=game.world.add_structure("chest",Vector3(8,game.world.terrain_height(8,8),8),0,identity)
		chest.storage={"wood":7}
		check(game.save_game(),"Seed, harvested resources, structures and edits save")
		var chest_id:int=chest.structure_id
		game.load_game()
		check(int(game.world.descriptor()["seed"])==seed_value and int(game.world.descriptor()["generator"])==3,"Reload keeps exact descriptor")
		check(is_equal_approx(game.world.terrain_height(at.x,at.z),edited),"Reload keeps surface alteration")
		check(game.world.cut_ids().has(0) and game.runtime.mining.stocks[0]==0,"Reload keeps harvested resources")
		check(game.world.get_structure(chest_id).storage.get("wood")==7,"Reload keeps construction and stored items")
		game.world.update_streaming([Vector3(320,0,320)])
		check(game.world._wanted.has(Vector2i(20,20)),"Streaming reaches beyond historical 320m limit")
		var deadline:=Time.get_ticks_msec()+8000
		while not game.world.has_terrain_at(Vector3(320,0,320)) and Time.get_ticks_msec()<deadline:await process_frame
		check(game.world.has_terrain_at(Vector3(320,0,320)),"Remote terrain chunk becomes playable")
		check(game.world._chunks.size()<=121,"Loaded chunks remain bounded for one focus")
	print("FRONTIER CHECKS=%d FAILED=%d"%[checks,failed])
	game.quit_game(0 if failed==0 else 1,false)
