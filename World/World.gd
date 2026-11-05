extends Node3D

const Shapes = preload("res://World/Shapes.gd")
const TreeScript = preload("res://World/Tree.gd")
const FireScript = preload("res://Building/Campfire.gd")
const ShelterScript = preload("res://Building/Shelter.gd")
const Foliage = preload("res://Assets/Shaders/foliage.gdshader")
const WaterShader = preload("res://Assets/Shaders/water.gdshader")
const Fish = preload("res://Animals/Fish.gd")
const Terrain = preload("res://World/Terrain.gd")
const Piece = preload("res://Building/Piece.gd")
const Balance = preload("res://Game/Balance.gd")
const SEED := 1337
const TREE_COUNT := 160
const LIMIT := 60.0

var world_description: Dictionary = Terrain.LEGACY.duplicate(true)
var sampler = Terrain.new()
var water_level: float = -2.9
var structures: Array = []
signal structure_loaded(piece)
var structure_registry = preload("res://Building/Registry.gd").new()
var _structure_wanted: Dictionary = {}
var _structure_nodes: Dictionary = {}
var fishes: Array = []
var resource_timers: Dictionary = {}
var _cut_registry: Dictionary = {}
var _chunks: Dictionary = {}
var _chunk_records: Dictionary = {}
var _tree_nodes: Dictionary = {}
var _wanted: Dictionary = {}
var _focus_positions: Array = [Vector3.ZERO]
var _ready_arrays: Array = []
var _job: int = -1
var _job_key := Vector2i.ZERO
var _generation: int = 0
var _mutex := Mutex.new()
var _poi_nodes: Array = []
var _grass_center := Vector3.ZERO
var _chunk_mask_signature: int = -1
var _chunk_mask: Image
var _chunk_mask_texture: ImageTexture
var trees: Array = []
var fires: Array[Node3D] = []
var shelters: Array[Node3D] = []
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var environment: Environment
var sky_material: ProceduralSkyMaterial
var preview: MeshInstance3D
var quality: int = 1
var grass: MultiMeshInstance3D
var grass_material: ShaderMaterial
var weather: Dictionary = {"rain": 0.0, "cloud": 0.0, "wind": 0.2, "fog": 0.0, "lightning": 0.0}
var rain_mesh: MultiMeshInstance3D
var rain_drops: Array[Dictionary] = []
var rain_rng := RandomNumberGenerator.new()
var rain_audio: AudioStreamPlayer
var thunder_audio: AudioStreamPlayer
var last_lightning: float = 0.0
var thunder_delay: float = -1.0
var rain_focus: Vector3 = Vector3.ZERO
var rain_enabled: bool = true
var water_material: ShaderMaterial
var reflection_probe: ReflectionProbe
var far_forest: MultiMeshInstance3D
var forest_material: ShaderMaterial
var forest_ids: Dictionary = {}
var forest_transforms: Array[Transform3D] = []
var forest_cut_hash:int = -1
var distant_terrain: MeshInstance3D
var distant_material: ShaderMaterial
var generated: bool = false
var generation_cancelled: bool = false
var last_daylight: float = 1.0
var last_wind: float = -1.0
var graphics_config: Dictionary = {}
var cloud_mesh: MeshInstance3D

static func height_at(x: float, z: float) -> float:
	return sin(x * 0.052) * 1.6 + cos(z * 0.047) * 1.4 + sin((x + z) * 0.031) * 0.8

func generate(progress: Callable) -> void:
	generation_cancelled = false
	setup_environment()
	for z in range(-4, 4):
		for x in range(-4, 4):
			make_chunk(x * 16, z * 16)
		progress.call("Terreno / Terrain %d%%" % int((z + 5) / 8.0 * 65.0))
		await get_tree().process_frame
		if generation_cancelled:
			return
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for i in range(TREE_COUNT):
		var p := Vector3(rng.randf_range(-58, 58), 0, rng.randf_range(-58, 58))
		while Vector2(p.x, p.z).length() < 7.0:
			p = Vector3(rng.randf_range(-58, 58), 0, rng.randf_range(-58, 58))
		if i < 3:
			p = [Vector3(3, 0, -3), Vector3(-3, 0, -3), Vector3(0, 0, -6)][i]
		p.y = height_at(p.x, p.z)
		var tree = TreeScript.new()
		add_child(tree)
		tree.setup(i, p, rng.randf_range(0.85, 1.35), Color("#2e6043").lerp(Color("#577c48"), rng.randf()))
		trees.append(tree)
		if i % 16 == 0:
			progress.call("Floresta / Forest %d%%" % (65 + int(i / 160.0 * 30)))
			await get_tree().process_frame
			if generation_cancelled:
				return
	make_scenery()
	make_grass()
	make_rain()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.7
	shape.bottom_radius = 0.7
	shape.height = 0.15
	preview = MeshInstance3D.new()
	preview.mesh = shape
	preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 1.0, 0.55, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview.material_override = m
	add_child(preview)
	preview.hide()
	generated = true
	set_quality(quality)
	progress.call("Pronto / Ready")

func cancel_generation() -> void:
	generation_cancelled = true

func make_chunk(x0: int, z0: int) -> void:
	_install_chunk(Vector2i(x0 / 16, z0 / 16), sampler.chunk_arrays(x0, z0))

func _install_chunk(key: Vector2i, arrays: Array) -> void:
	if _chunks.has(key): return
	var root := Node3D.new()
	root.name = "Chunk_%d_%d" % [key.x, key.y]
	add_child(root)
	_chunks[key] = root
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var terrain := MeshInstance3D.new()
	terrain.mesh = mesh
	var mat := Shapes.material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	terrain.material_override = mat
	root.add_child(terrain)
	var ground := StaticBody3D.new()
	ground.add_to_group("terrain")
	root.add_child(ground)
	var shape := mesh.create_trimesh_shape()
	shape.backface_collision = true
	Shapes.collider(ground, shape, Vector3.ZERO)
	_spawn_chunk_trees(key)
	if int(world_description["generator"])>=2 and DisplayServer.get_name()!="headless": _spawn_ground_life(root,key)

func setup_environment() -> void:
	var node := WorldEnvironment.new()
	environment = Environment.new()
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#4387a1")
	sky_material.sky_horizon_color = Color("#c4d6be")
	sky_material.ground_bottom_color = Color("#324b42")
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#aac7d2")
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_light_color = Color("#a3bab2")
	environment.fog_density = 0.003
	node.environment = environment
	add_child(node)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("#fff0cc")
	sun.directional_shadow_max_distance = 65.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.light_angular_distance = 0.6
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.light_color = Color("#7e9dc2")
	add_child(moon)
	cloud_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(800, 800)
	cloud_mesh.mesh = plane
	cloud_mesh.position.y = 45
	cloud_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cloud_material := ShaderMaterial.new()
	cloud_material.shader = preload("res://Assets/Shaders/clouds.gdshader")
	cloud_mesh.material_override = cloud_material
	add_child(cloud_mesh)

func make_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 1
	for i in range(65):
		var p := Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-60, 60))
		if Vector2(p.x, p.z).length() < 7:
			continue
		p.y = height_at(p.x, p.z) + 0.2
		var rock := Shapes.sphere(self, rng.randf_range(0.3, 0.75), p, Color("#78827b"))
		rock.scale = Vector3(1.3, 0.6, 1.0)
		rock.rotation.y = rng.randf() * TAU
		rock.add_to_group("world_rock")
	var water := PlaneMesh.new()
	water.size = Vector2(160, 160)
	water.subdivide_width = 48
	water.subdivide_depth = 48
	water.subdivide_width = 32
	water.subdivide_depth = 32
	var lake := Shapes.mesh(self, water, Vector3(0, -2.9, 0), Color("#4a929a"))
	water_material = ShaderMaterial.new()
	water_material.shader = WaterShader
	lake.material_override = water_material
	# A captured cubemap supplies environment reflections in Compatibility.
	# This is a local static probe, not planar reflections or screen-space SSR.
	reflection_probe = ReflectionProbe.new()
	reflection_probe.position = Vector3(0, 3, 0)
	reflection_probe.size = Vector3(140, 30, 140)
	reflection_probe.max_distance = 110
	reflection_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	reflection_probe.box_projection = false
	reflection_probe.intensity = 0.65
	add_child(reflection_probe)

func make_grass() -> void:
	grass = MultiMeshInstance3D.new()
	grass.multimesh = MultiMesh.new()
	grass.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	grass.multimesh.use_colors = true
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(6):
		var angle := i * 2.39996
		var side := Vector3(cos(angle), 0, sin(angle)) * 0.055
		var base := Vector3(sin(i * 3.1), 0, cos(i * 2.4)) * 0.12
		var middle := base + Vector3(sin(angle) * 0.10, 0.22 + i * 0.022, cos(angle) * 0.10)
		var tip := middle + Vector3(sin(angle) * 0.12, 0.18, cos(angle) * 0.12)
		for vertex in [base-side, middle-side*0.65, base+side, base+side, middle-side*0.65, middle+side*0.65, middle-side*0.65, tip, middle+side*0.65]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(vertex)
	grass.multimesh.mesh = surface.commit()
	grass.multimesh.instance_count = 4200
	grass_material = ShaderMaterial.new()
	grass_material.shader = Foliage
	grass_material.set_shader_parameter("tint", Color("#71935a"))
	grass.material_override = grass_material
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 20
	for i in range(4200):
		var p := Vector3(rng.randf_range(-61, 61), 0, rng.randf_range(-61, 61))
		p.y = height_at(p.x, p.z) - 0.02
		var scale_value := rng.randf_range(0.5, 1.4) if p.y > -2.6 else 0.0
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale_value)
		grass.multimesh.set_instance_transform(i, Transform3D(basis, p))
		grass.multimesh.set_instance_color(i, Color.WHITE.lerp(Color("#b4bd80"), rng.randf() * 0.45))
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass)

func illuminate(clock) -> void:
	if sun == null:
		return
	var day: float = clock.daylight()
	last_daylight = day
	var hour: float = clock.hour()
	var cloud := float(weather.get("cloud", 0))
	var flash := 0.0 if graphics_config.get("reduced_flash",false) else float(weather.get("lightning", 0))
	sun.rotation_degrees = Vector3(-(hour - 6.0) * 15.0, -25, 0)
	moon.rotation_degrees = sun.rotation_degrees + Vector3(180, 0, 0)
	sun.light_energy = day * 0.85 * (1 - cloud * 0.62) + flash * 3.0
	moon.light_energy = (1.0 - day) * 0.18
	if reflection_probe != null:
		reflection_probe.intensity = lerpf(0.06, 0.65, day) * (1 - cloud * 0.4)
	var dusk := clampf(1.0 - day * 2.8, 0, 1)
	sun.light_color = Color("#fff0cc").lerp(Color("#ffac69"), dusk)
	environment.ambient_light_energy = lerpf(0.14, 0.40, day) * (1 - cloud * 0.35) + flash * 0.8
	sky_material.sky_top_color = Color("#0b162e").lerp(Color("#4387a1"), day).lerp(Color("#414d5b"), cloud * 0.7)
	sky_material.sky_horizon_color = Color("#26394d").lerp(Color("#d5d9b5"), day).lerp(Color("#68767b"), cloud * 0.7)
	environment.fog_light_color = Color("#1e2f42").lerp(Color("#a3bab2"), day)
	environment.fog_density = 0.0018 + float(weather.get("fog", 0)) * 0.025 + float(weather.get("rain", 0)) * 0.008

func apply_weather(state: Dictionary) -> void:
	if cloud_mesh != null:
		cloud_mesh.material_override.set_shader_parameter("density", float(state.get("cloud", 0.05)) + 0.15)
		cloud_mesh.material_override.set_shader_parameter("tint", Color("#9baab3").lerp(Color("#d8e1d7"), last_daylight))
	var flash := float(state.get("lightning", 0))
	if flash > 0.5 and last_lightning <= 0.5:
		thunder_delay = 1.5 + rain_rng.randf() * 2.0
	last_lightning = flash
	weather = state.duplicate()
	var wind := float(state.get("wind", 0.2))
	if absf(wind - last_wind) >= 0.01:
		last_wind = wind
		if grass_material != null:
			grass_material.set_shader_parameter("wind", wind)
		for tree in trees:
			if tree.foliage_material != null:
				tree.foliage_material.set_shader_parameter("wind", wind)
	if rain_audio != null:
		rain_audio.volume_db = lerpf(-65, -18, float(weather.get("rain", 0)))
	if water_material != null:
		water_material.set_shader_parameter("rain", float(weather.get("rain", 0)))

func set_quality(value: int) -> void:
	quality = clampi(value, 0, 3)
	if sun == null:
		return
	sun.shadow_enabled = quality > 0
	sun.directional_shadow_max_distance = [25.0, 45.0, 60.0, 80.0][quality]
	if grass != null:
		grass.multimesh.visible_instance_count = [700, 1600, 2800, 4200][quality]
		grass.visibility_range_end = [22.0, 35.0, 50.0, 75.0][quality]
		grass.visibility_range_end_margin = 4.0
	for tree in trees:
		tree.set_quality(quality)
	if reflection_probe != null:
		reflection_probe.visible = quality >= 2
	for fire in fires:
		fire.set_quality(quality)
	if rain_mesh != null:
		rain_mesh.multimesh.visible_instance_count = [70, 130, 200, 280][quality]

func apply_graphics(config: Dictionary) -> void:
	graphics_config = config.duplicate(true)
	set_quality([0, 0, 1, 2, 3, 1][int(config["preset"])])
	sun.shadow_enabled = int(config["shadows"]) > 0
	sun.directional_shadow_max_distance = [20.0, 45.0, 65.0, 90.0][int(config["shadows"])]
	grass.multimesh.visible_instance_count = int(config["vegetation"])
	grass.visibility_range_end = float(config["view_distance"]) * 0.6
	reflection_probe.visible = bool(config["reflections"])
	rain_enabled = bool(config["rain"])
	cloud_mesh.visible = bool(config["clouds"])
	var distance := float(config["view_distance"])
	for tree in trees:
		var lod_distance := distance * 0.55
		if not tree.detail_meshes.is_empty():
			lod_distance = minf(tree.detail_meshes[0].visibility_range_end, lod_distance)
		for mesh in tree.detail_meshes:
			mesh.visibility_range_end = lod_distance
		for mesh in tree.distant_meshes:
			mesh.visibility_range_begin = lod_distance
			mesh.visibility_range_end = distance
	water_material.set_shader_parameter("detail", int(config["water"]))
	for fire in fires:
		fire.set_quality(int(config["particles"]))
		_apply_fire_graphics(fire, fires.find(fire))
	environment.ssao_enabled = bool(config["ao"]) and RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.volumetric_fog_enabled = bool(config["volumetric"]) and RenderingServer.get_current_rendering_method() == "forward_plus"

func nearest_tree(player: Node3D):
	var result = null
	var distance := 3.5
	var forward := -player.global_basis.z
	for tree in trees:
		if tree.felled: continue
		var offset: Vector3 = tree.global_position - player.global_position
		if absf(offset.y) > 2: continue
		offset.y = 0
		var length := offset.length()
		if length >= distance or length <= 0.01 or offset.normalized().dot(forward) <= 0.35: continue
		var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, tree.global_position + Vector3.UP, 1, [player.get_rid(), tree.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		distance = length
		result = tree
	return result

func placement(player: CharacterBody3D, kind: String = "campfire", rotation_value: int = 0, options: Dictionary = {}, ignore_id: int = 0) -> Dictionary:
	if preload("res://Items/Catalog.gd").station_ids().has(kind): return preload("res://Building/Placement.gd").station(self,player,rotation_value,options)
	if kind in preload("res://Energy/Grid.gd").KINDS: return preload("res://Energy/Grid.gd").placement(self,player,kind)
	if kind=="raft":
		var at:Vector3=player.position-player.global_basis.z*4
		at.y=water_level+0.12
		var valid:bool=contains_position(at) and structure_registry.records.size()<preload("res://Building/Registry.gd").MAXIMUM
		for offset in [Vector3(-1,0,-1.8),Vector3(1,0,1.8),Vector3.ZERO]:
			valid=valid and terrain_height(at.x+offset.x,at.z+offset.z)<water_level-0.6
		for piece in structures:
			if piece.position.distance_to(at)<3:valid=false
		return {"valid":valid,"position":at,"rotation":rotation_value}
	if kind in Piece.KINDS: return preload("res://Building/Placement.gd").evaluate(self,player,kind,rotation_value,options,ignore_id)
	var shelter := kind == "shelter"
	if (shelters.size() >= 16 if shelter else fires.size() >= 32):
		return {"valid": false, "position": player.global_position}
	var target := player.global_position - player.global_basis.z * (5.5 if shelter else 3.0)
	target.x = clampf(target.x, -half_extent() + 5, half_extent() - 5)
	target.z = clampf(target.z, -half_extent() + 5, half_extent() - 5)
	var query := PhysicsRayQueryParameters3D.create(target + Vector3.UP * 6, target - Vector3.UP * 9, 1, [player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {"valid": false, "position": target}
	var p: Vector3 = hit["position"]
	var valid: bool = hit["collider"].is_in_group("terrain") and hit["normal"].dot(Vector3.UP) > (0.96 if shelter else 0.88) and p.y > -2.7
	for fire in fires:
		if fire.position.distance_to(p) < (3.0 if shelter else 1.8):
			valid = false
	for building in shelters:
		if Vector2(building.position.x - p.x, building.position.z - p.z).length() < (5.5 if shelter else 0.5):
			valid = false
	var volume := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.8 if shelter else 0.85
	volume.shape = shape
	volume.transform = Transform3D(Basis.IDENTITY, p + Vector3.UP * (3.0 if shelter else 1.0))
	volume.collision_mask = 1
	volume.exclude = [player.get_rid()]
	if not get_world_3d().direct_space_state.intersect_shape(volume, 1).is_empty():
		valid = false
	return {"valid": valid, "position": p + Vector3.UP * 0.03}

func add_fire(at: Vector3) -> void:
	var fire = FireScript.new()
	fire.position = at
	add_child(fire)
	fire.set_quality(quality)
	fires.append(fire)
	if not graphics_config.is_empty():
		fire.set_quality(int(graphics_config["particles"]))
		_apply_fire_graphics(fire, fires.size() - 1)

func _apply_fire_graphics(fire, index: int) -> void:
	var lighting: int = int(graphics_config.get("lighting", 1))
	fire.light.omni_range = [5.0, 8.0, 10.0][lighting]
	fire.light.visible = index < [6, 12, 24][lighting]
	fire.light.shadow_enabled = int(graphics_config.get("shadows", 1)) >= 2

func add_shelter(at: Vector3) -> void:
	var shelter = ShelterScript.new()
	shelter.position = at
	add_child(shelter)
	shelters.append(shelter)
	# Existing drops must recompute the roof occlusion before falling again.
	for drop in rain_drops:
		drop["active"] = false

func is_sheltered(player: Node3D) -> bool:
	var start := player.global_position + Vector3.UP * 1.65
	var query := PhysicsRayQueryParameters3D.create(start, start + Vector3.UP * 20, 1)
	if player is CollisionObject3D:
		query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()

func warmth_at(at: Vector3) -> bool:
	for fire in fires:
		if not fire.lit or fire.fuel <= 0 or fire.global_position.distance_to(at) >= Balance.number("fire", "heat_radius", 4): continue
		var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP, fire.global_position + Vector3.UP, 1)
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return true
	return false

func restore(data: Dictionary) -> void:
	apply_terrain_changes(data.get("terrain_changes",{}))
	_cut_registry.clear()
	for id in data.get("cut", []): _cut_registry[int(id)] = true
	resource_timers = data.get("resource_timers", {}).duplicate(true)
	for tree in trees:
		var cut: bool = _cut_registry.has(tree.tree_id)
		if cut != tree.felled: tree.set_felled(cut, cut)
	_restore_points(fires, data.get("fires", []), "fire")
	_restore_points(shelters, data.get("shelters", []), "shelter")
	for state in data.get("fire_states", []):
		var p: Array = state["position"]
		for fire in fires:
			if fire.position.distance_to(Vector3(p[0], p[1], p[2])) < 0.05: fire.restore_state(state)
	restore_buildings(data.get("structures", []),int(data.get("structure_next_id",1)))
	for fish in fishes: fish.restore({"stock":8,"restock_at":0.0})
	for state in data.get("fishing",[]):
		if int(state["id"])<fishes.size(): fishes[int(state["id"])].restore(state)

func _restore_points(nodes: Array, positions: Array, kind: String) -> void:
	for node in nodes.duplicate():
		var found := false
		for p in positions:
			if node.position.distance_to(Vector3(p[0], p[1], p[2])) < 0.01: found = true
		if not found:
			nodes.erase(node); _remove_world_object(node)
	for p in positions:
		var at := Vector3(p[0], p[1], p[2])
		var found := false
		for node in nodes:
			if node.position.distance_to(at) < 0.01: found = true
		if not found:
			if kind == "fire": add_fire(at)
			else: add_shelter(at)

func cut_ids() -> Array:
	for tree in trees:
		if tree.felled: _cut_registry[tree.tree_id] = true
	var ids: Array = _cut_registry.keys()
	ids.sort()
	return ids

func fire_positions() -> Array:
	var positions: Array = []
	for fire in fires:
		positions.append([fire.position.x, fire.position.y, fire.position.z])
	return positions

func shelter_positions() -> Array:
	var positions: Array = []
	for shelter in shelters:
		positions.append([shelter.position.x, shelter.position.y, shelter.position.z])
	return positions

func make_rain() -> void:
	rain_rng.seed = 83117
	rain_mesh = MultiMeshInstance3D.new()
	rain_mesh.multimesh = MultiMesh.new()
	rain_mesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var drop := BoxMesh.new()
	drop.size = Vector3(0.018, 0.65, 0.018)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.79, 0.87, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = mat
	rain_mesh.multimesh.mesh = drop
	rain_mesh.multimesh.instance_count = 280
	rain_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain_mesh)
	for i in range(280):
		rain_drops.append({"p": Vector3.ZERO, "bottom": 0.0, "active": false})
		rain_mesh.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
	rain_audio = AudioStreamPlayer.new()
	rain_audio.stream = weather_sound(false)
	rain_audio.volume_db = -65
	add_child(rain_audio)
	rain_audio.play()
	thunder_audio = AudioStreamPlayer.new()
	thunder_audio.stream = weather_sound(true)
	thunder_audio.volume_db = -17
	add_child(thunder_audio)

static func weather_sound(thunder: bool) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4141 if thunder else 7239
	var frames := 44100 if thunder else 22050
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var filtered := 0.0
	for i in range(frames):
		filtered = lerpf(filtered, rng.randf_range(-1, 1), 0.025 if thunder else 0.6)
		var amplitude := pow(1 - float(i) / frames, 1.2) if thunder else 0.4
		bytes.encode_s16(i * 2, int(filtered * amplitude * 26000))
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = 22050
	result.data = bytes
	if not thunder:
		result.loop_mode = AudioStreamWAV.LOOP_FORWARD
		result.loop_end = frames
	return result

func _physics_process(delta: float) -> void:
	if not generated or rain_mesh == null:
		return
	if thunder_delay >= 0:
		thunder_delay -= delta
		if thunder_delay < 0:
			thunder_audio.play()
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		rain_focus = camera.global_position
	var rain := float(weather.get("rain", 0))
	var count := int([70, 130, 200, 280][int(graphics_config.get("particles", quality))])
	rain_mesh.visible = rain > 0.02 and rain_enabled
	if not rain_mesh.visible:
		return
	for i in range(count):
		var drop: Dictionary = rain_drops[i]
		var p: Vector3 = drop["p"]
		p.y -= delta * (10.0 + rain * 6.0)
		if not drop["active"] or p.y < float(drop["bottom"]) + 0.4 or Vector2(p.x - rain_focus.x, p.z - rain_focus.z).length() > 24:
			p = rain_focus + Vector3(rain_rng.randf_range(-18, 18), rain_rng.randf_range(5, 13), rain_rng.randf_range(-18, 18))
			drop["bottom"] = rain_stop_at(p.x, p.z, rain_focus.y + 18)
			p.y = maxf(p.y, float(drop["bottom"]) + 0.7)
			drop["active"] = true
		drop["p"] = p
		var scale_value := 1.0 if float(i) / count < rain else 0.0
		rain_mesh.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_value), p))

func rain_stop_at(x: float, z: float, top: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, -15, z), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return float(hit["position"].y) + 0.2 if not hit.is_empty() else -8.0

func descriptor() -> Dictionary:
	return world_description.duplicate(true)
func half_extent() -> float:
	return 60.0 if int(world_description["generator"]) == 0 else float(world_description["size"]) * 0.5
func contains_position(at: Vector3) -> bool:
	return absf(at.x) <= half_extent() and absf(at.z) <= half_extent()
func terrain_height(x: float, z: float) -> float:
	return sampler.height(x, z)
func biome_at(x: float, z: float) -> String:
	return sampler.biome(x, z)

func configure_world(description: Dictionary) -> void:
	if description == world_description: return
	_generation += 1
	world_description = description.duplicate(true)
	sampler = Terrain.new(description)
	for node in _chunks.values(): remove_child(node); node.queue_free()
	_chunks.clear()
	for tree in trees: remove_child(tree); tree.queue_free()
	trees.clear(); _tree_nodes.clear(); _chunk_records.clear(); _cut_registry.clear()
	# World-local objects and their clocks must never survive a seed change.
	for collection in [structures, fires, shelters]:
		for node in collection:
			_remove_world_object(node)
		collection.clear()
	structure_registry.clear(); _structure_nodes.clear(); _structure_wanted.clear()
	resource_timers.clear()
	for node in _poi_nodes: remove_child(node); node.queue_free()
	_poi_nodes.clear()
	for fish in fishes: remove_child(fish); fish.queue_free()
	fishes.clear()
	_build_tree_catalog()
	for z in range(-1, 2):
		for x in range(-1, 2): make_chunk(x * 16, z * 16)
	if int(description["generator"]) == 0:
		for z in range(-4, 4):
			for x in range(-4, 4): make_chunk(x * 16, z * 16)
	else:
		_make_points_of_interest()
		for id in range(12):
			var fish:=Fish.new();add_child(fish)
			fish.setup(id,Vector3(sampler.lake_center.x+sin(id*2.4)*6,water_level-0.5,sampler.lake_center.y+cos(id*2.4)*6))
			fishes.append(fish)
	_place_grass(Vector3.ZERO)
	_make_distant_terrain()
	_make_distant_forest()
	for child in get_children():
		if child.is_in_group("world_rock"):
			child.position.y=terrain_height(child.position.x,child.position.z)+0.2
			child.visible=child.position.y>water_level+0.1
		if child is MeshInstance3D and child.mesh is PlaneMesh and child != cloud_mesh:
			child.mesh.size = Vector2.ONE * (half_extent() * 2.6)
	update_streaming([Vector3.ZERO])

func _remove_world_object(node: Node) -> void:
	# Release mixer-thread playbacks while the emitter is still in the tree.
	_stop_world_audio(node)
	remove_child(node)
	node.queue_free()

func _stop_world_audio(node: Node) -> void:
	if node is AudioStreamPlayer3D or node is AudioStreamPlayer:
		node.stop()
		node.stream = null
	for child in node.get_children(): _stop_world_audio(child)

func _build_tree_catalog() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world_description["seed"])
	var legacy: bool = int(world_description["generator"]) == 0
	var count := 160 if legacy else (16000 if int(world_description["generator"]) >= 2 else 800)
	var extent := 58.0 if legacy else (145.0 if int(world_description["generator"])==1 else half_extent()*0.91)
	for id in range(count):
		var at := Vector3(rng.randf_range(-extent, extent), 0, rng.randf_range(-extent, extent))
		while Vector2(at.x, at.z).length() < 7: at = Vector3(rng.randf_range(-extent, extent), 0, rng.randf_range(-extent, extent))
		if id < 3: at = [Vector3(3,0,-3),Vector3(-3,0,-3),Vector3(0,0,-6)][id]
		at.y = terrain_height(at.x, at.z)
		var size := rng.randf_range(0.85,1.35)
		var tint := Color("#38724c").lerp(Color("#7ea958"), rng.randf())
		if not legacy and at.y < water_level + 0.6: continue
		var biome := biome_at(at.x, at.z)
		if int(world_description["generator"]) >= 3 and id > 2:
			if sampler.path_distance(at.x,at.z) < 2.2: continue
			if biome in ["plains","woodland"] and id % 3 != 0: continue
		var species: String = "oak" if legacy else ("palm" if biome == "beach" else ("pine" if biome in ["mountains", "tundra"] else ("burnt" if biome == "volcanic" else ["oak","pine","birch","fruit","fallen"][id % 5])))
		var key := Vector2i(floori(at.x/16), floori(at.z/16))
		if not _chunk_records.has(key): _chunk_records[key] = []
		_chunk_records[key].append({"id": id,"position": at,"size": size,"tint": tint,"species": species})

func _spawn_chunk_trees(key: Vector2i) -> void:
	for record in _chunk_records.get(key, []):
		if _tree_nodes.has(record["id"]): continue
		var tree = TreeScript.new()
		add_child(tree)
		tree.setup(record["id"], record["position"], record["size"], record["tint"], record["species"])
		tree.restore_cut(_cut_registry.has(record["id"]))
		trees.append(tree); _tree_nodes[record["id"]] = tree
	trees.sort_custom(func(a,b): return a.tree_id < b.tree_id)

func update_streaming(foci: Array) -> void:
	_stream_structures(foci)
	if int(world_description["generator"]) == 0: return
	_wanted.clear()
	_focus_positions = foci.duplicate()
	for focus in foci:
		var center := Vector2i(floori(focus.x/16),floori(focus.z/16))
		for z in range(-3,4):
			for x in range(-3,4):
				var key := center + Vector2i(x,z)
				var limit := ceili(half_extent() / 16)
				if key.x >= -limit and key.x < limit and key.y >= -limit and key.y < limit: _wanted[key] = true
	for key in _chunks.keys():
		if _wanted.has(key): continue
		var keep := false
		for focus in foci:
			if Vector2(key.x*16+8-focus.x,key.y*16+8-focus.z).length() < 88: keep = true
		if keep: continue
		var node: Node = _chunks[key]; remove_child(node); node.queue_free(); _chunks.erase(key)
		for tree in trees.duplicate():
			if Vector2i(floori(tree.position.x/16),floori(tree.position.z/16)) == key:
				if tree.felled: _cut_registry[tree.tree_id] = true
				_tree_nodes.erase(tree.tree_id); trees.erase(tree); remove_child(tree); tree.queue_free()
	if not foci.is_empty() and grass != null and _grass_center.distance_to(foci[0]) > 24: _place_grass(foci[0])

func _build_chunk_job(key: Vector2i, model, generation: int) -> void:
	var arrays: Array = model.chunk_arrays(key.x*16,key.y*16)
	_mutex.lock(); _ready_arrays.append({"key":key,"arrays":arrays,"generation":generation}); _mutex.unlock()

func _process(_delta: float) -> void:
	_install_structures(8)
	_sync_distant_forest()
	_update_chunk_mask()
	if forest_material!=null and not _focus_positions.is_empty():forest_material.set_shader_parameter("focus",Vector2(_focus_positions[0].x,_focus_positions[0].z))
	for poi in _poi_nodes: poi.visible=has_terrain_at(poi.position)
	if distant_material!=null and not _focus_positions.is_empty(): distant_material.set_shader_parameter("focus",Vector2(_focus_positions[0].x,_focus_positions[0].z))
	if _job >= 0 and WorkerThreadPool.is_task_completed(_job):
		WorkerThreadPool.wait_for_task_completion(_job); _job = -1
	_mutex.lock()
	var completed := _ready_arrays.duplicate()
	_ready_arrays.clear(); _mutex.unlock()
	for record in completed:
		if record["generation"] == _generation and _wanted.has(record["key"]): _install_chunk(record["key"],record["arrays"])
	if _job < 0 and not generation_cancelled:
		var missing: Array = _wanted.keys().filter(func(key): return not _chunks.has(key))
		missing.sort_custom(func(a,b): return _stream_distance(a) < _stream_distance(b))
		if not missing.is_empty():
			var key: Vector2i = missing[0]
			_job_key = key
			_job = WorkerThreadPool.add_task(_build_chunk_job.bind(key,sampler,_generation))

func _stream_distance(key: Vector2i) -> float:
	var best := INF
	for focus in _focus_positions:
		best = minf(best, Vector2(key.x*16+8-focus.x,key.y*16+8-focus.z).length_squared())
	return best
func has_terrain_at(at: Vector3) -> bool:
	return _chunks.has(Vector2i(floori(at.x/16),floori(at.z/16)))

func _exit_tree() -> void:
	if _job >= 0: WorkerThreadPool.wait_for_task_completion(_job)

func _place_grass(center: Vector3) -> void:
	if grass == null: return
	_grass_center = center
	var rng := RandomNumberGenerator.new(); rng.seed = int(world_description["seed"]) + 20 + floori(center.x/24)*107 + floori(center.z/24)*307
	for i in range(4200):
		var at := Vector3(center.x+rng.randf_range(-59,59),0,center.z+rng.randf_range(-59,59))
		at.y = terrain_height(at.x,at.z)-0.02
		var scale_value := rng.randf_range(0.5,1.4) if at.y > water_level+0.3 and contains_position(at) else 0.0
		grass.multimesh.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_value),at))

func record_tree_cut(id: int) -> void:
	_cut_registry[id] = true
	resource_timers[str(id)] = Time.get_unix_time_from_system() + Balance.number("world","tree_regrow_seconds",900)

func tick_world(delta: float, authoritative: bool, raining: bool) -> void:
	if not authoritative: return
	var now := Time.get_unix_time_from_system()
	for id in resource_timers.keys():
		if now >= float(resource_timers[id]):
			resource_timers.erase(id); _cut_registry.erase(int(id))
			if _tree_nodes.has(int(id)): _tree_nodes[int(id)].restore_cut(false)
	for fire in fires: fire.advance(delta,raining,is_sheltered(fire))
	for fish in fishes: fish.advance()

func fire_states() -> Array:
	var result: Array = []
	for fire in fires: result.append(fire.state())
	return result

func _modular_placement(player, kind: String, turn: int) -> Dictionary:
	return preload("res://Building/Placement.gd").evaluate(self,player,kind,turn)
func _sync_structure_records() -> void:
	for piece in structures: structure_registry.put(piece.get_record())
func _spawn_structure(record: Dictionary):
	var piece = Piece.new(); add_child(piece); piece.setup(record)
	piece.set_meta("collision_frame",Engine.get_physics_frames())
	structures.append(piece); _structure_nodes[int(record["id"])]=piece
	structure_loaded.emit(piece)
	return piece
func ensure_structures(at: Vector3, radius: float=12) -> void:
	for id in structure_registry.nearby(at,radius):
		if not _structure_nodes.has(id): _spawn_structure(structure_registry.records[id])
func add_structure(kind: String, at: Vector3, turn: int, owner: String, id: int = -1, extra: Dictionary = {}):
	if kind not in Piece.KINDS: return null
	if id<0: id=structure_registry.next_id
	var row := {"id":id,"kind":kind,"position":[at.x,at.y,at.z],"rotation":posmod(turn,4),"owner":owner,"hp":100,"open":false}
	row.merge(extra,true); structure_registry.put(row)
	return _spawn_structure(row)
func get_structure(id: int, materialize: bool=false):
	if not _structure_nodes.has(id) and materialize and structure_registry.records.has(id): return _spawn_structure(structure_registry.records[id])
	return _structure_nodes.get(id)
func structure_near(body, kind: String = "", distance: float = 3.0):
	var result = null
	for piece in structures:
		var d: float = piece.position.distance_to(body.position)
		if (d < distance or (result!=null and absf(d-distance)<.01 and preload("res://Building/Catalog.gd").piece(piece.kind).has("door"))) and (kind.is_empty() or piece.kind == kind): result=piece; distance=d
	return result
func replace_structure(row: Dictionary) -> void:
	var id:=int(row["id"]); var node=get_structure(id)
	if node!=null:
		structures.erase(node); _structure_nodes.erase(id); remove_child(node); node.queue_free()
	structure_registry.put(row)
	_spawn_structure(row)
func remove_structure(id: int) -> void:
	var node=get_structure(id)
	if node!=null:
		structures.erase(node); _structure_nodes.erase(id); remove_child(node); node.queue_free()
	structure_registry.erase(id); _structure_wanted.erase(id)
func toggle_door(id: int) -> bool:
	var piece = get_structure(id)
	if piece == null or not preload("res://Building/Catalog.gd").piece(piece.kind).has("door"): return false
	piece.set_open(not piece.open); piece.record_extra["revision"]=int(piece.record_extra.get("revision",1))+1
	return true
func bed_spawn(identity: String) -> Vector3:
	_sync_structure_records()
	for row in structure_registry.records.values():
		if row["kind"]=="bed" and row.get("bound_to","")==identity: return structure_registry.point(row)+Vector3(1.5,0.5,0)
	return Vector3(0,terrain_height(0,0)+0.2,0)
func building_records(focus: Variant = null) -> Array:
	_sync_structure_records()
	if focus is Vector3:
		var result: Array=[]
		for id in structure_registry.nearby(focus,96): result.append(structure_registry.records[id].duplicate(true))
		return result
	return structure_registry.all_records()
func restore_buildings(records: Array, next_id: int = 1) -> void:
	var ids := {}
	for row in records: ids[int(row["id"])]=row
	for node in structures.duplicate():
		var replacement: Dictionary=ids.get(node.structure_id,{})
		var before: Dictionary=node.get_record()
		var changed:=replacement.is_empty()
		for key in ["kind","owner","tier","mirror","paint"]:
			if before.get(key)!=replacement.get(key): changed=true
		if node.kind!="raft" and (before.get("position")!=replacement.get("position") or before.get("rotation")!=replacement.get("rotation")): changed=true
		if changed:
			structures.erase(node); _structure_nodes.erase(node.structure_id); remove_child(node); node.queue_free()
		else:
			node.hp=int(replacement["hp"])
			if preload("res://Building/Catalog.gd").piece(node.kind).has("door"): node.record_extra["door_swing"]=int(replacement.get("door_swing",-1))
			node.set_open(bool(replacement.get("open",false)))
			for key in ["name","locked","allow_allies","supports","revision","paid_cost"]:
				if replacement.has(key): node.record_extra[key]=replacement[key]
			node.storage=replacement.get("storage",{}).duplicate(true); node.storage_wear=replacement.get("storage_wear",{}).duplicate(true); node.bound_to=str(replacement.get("bound_to",""))
			if node.kind=="raft":
				node.replica_target=structure_registry.point(replacement); node.replica_yaw=int(replacement["rotation"])*PI*.5
				if node.is_multiplayer_authority(): node.position=node.replica_target; node.rotation.y=node.replica_yaw
	structure_registry.load_records(records,maxi(next_id,structure_registry.next_id))
	_stream_structures(_focus_positions)
	# Small old saves are installed immediately; large worlds use the frame budget.
	_install_structures(32)
func _stream_structures(foci: Array) -> void:
	_sync_structure_records(); _structure_wanted.clear()
	for focus in foci:
		for id in structure_registry.nearby(focus,72): _structure_wanted[id]=true
		ensure_structures(focus)
	for node in structures.duplicate():
		var keep: bool=_structure_wanted.has(node.structure_id)
		for focus in foci:
			if node.position.distance_to(focus)<96: keep=true
		if not keep:
			structures.erase(node); _structure_nodes.erase(node.structure_id); remove_child(node); node.queue_free()
func _install_structures(budget: int) -> void:
	for id in _structure_wanted:
		if _structure_nodes.has(id) or not structure_registry.records.has(id): continue
		_spawn_structure(structure_registry.records[id]); budget-=1
		if budget<=0: break

func _make_points_of_interest() -> void:
	if int(world_description["generator"]) >= 3: _make_watershed_landmarks()
	for place in sampler.locations:
		var node := StaticBody3D.new(); node.position=place["position"]; add_child(node); _poi_nodes.append(node)
		var rock := Color("#66645b")
		if place["kind"] == "cave":
			for side in [-1,1]:
				Shapes.box(node,Vector3(2,4,12),Vector3(side*4,2,0),rock)
				var shape := BoxShape3D.new(); shape.size=Vector3(2,4,12); Shapes.collider(node,shape,Vector3(side*4,2,0))
			for item in [[Vector3(10,1.5,12),Vector3(0,4.5,0)],[Vector3(10,4,1),Vector3(0,2,5.5)]]:
				Shapes.box(node,item[0],item[1],rock); var shape:=BoxShape3D.new();shape.size=item[0];Shapes.collider(node,shape,item[1])
			node.add_to_group("rain_roof");node.add_to_group("cave")
		else:
			for x in [-4,0,4]:
				for z in [-4,4]:
					Shapes.cylinder(node,0.6,3.2,Vector3(x,1.6,z),rock)
					var shape:=CylinderShape3D.new();shape.radius=0.6;shape.height=3.2;Shapes.collider(node,shape,Vector3(x,1.6,z))

func fish_states() -> Array:
	return fishes.map(func(fish): return fish.state())

func apply_terrain_changes(edits: Dictionary) -> void:
	if sampler.changes==edits:return
	_generation+=1
	sampler=Terrain.new(world_description,edits)
	call_deferred("_refresh_edited_chunks")
func _refresh_edited_chunks() -> void:
	for key in _chunks.keys():
		var node:Node=_chunks[key]
		remove_child(node);node.queue_free()
		_chunks.erase(key)
		# Trees are independent from terrain chunk nodes; keep stable IDs.
	for z in range(-1,2):
		for x in range(-1,2):
			var p:Vector3=_focus_positions[0] if not _focus_positions.is_empty() else Vector3.ZERO
			var key:=Vector2i(floori(p.x/16)+x,floori(p.z/16)+z)
			_install_chunk(key,sampler.chunk_arrays(key.x*16,key.y*16))
func dig(at: Vector3) -> bool:
	if not contains_position(at) or terrain_height(at.x,at.z)<water_level+0.5:return false
	var edits:Dictionary=sampler.changes.duplicate(true)
	var key:="%d,%d"%[roundi(at.x/4.0),roundi(at.z/4.0)]
	if edits.size()>=1024 or float(edits.get(key,0))>=4:return false
	edits[key]=float(edits.get(key,0))+0.5
	apply_terrain_changes(edits)
	return true

func _make_distant_terrain() -> void:
	if is_instance_valid(distant_terrain):distant_terrain.queue_free()
	distant_material=null
	if int(world_description["generator"])<2 or DisplayServer.get_name()=="headless":return
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var extent:=half_extent();var step:=extent*2/96
	var samples:Dictionary={}
	for z in range(97):
		for x in range(97):
			var at:=Vector2(-extent+x*step,-extent+z*step)
			var normal:=Vector3(sampler.height(at.x-1,at.y)-sampler.height(at.x+1,at.y),2,sampler.height(at.x,at.y-1)-sampler.height(at.x,at.y+1)).normalized()
			samples[Vector2i(x,z)]=[Vector3(at.x,sampler.height(at.x,at.y)-0.7,at.y),normal,sampler.ground_color(at.x,at.y,normal)]
	for z in range(96):
		for x in range(96):
			for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var sample:Array=samples[Vector2i(x,z)+corner]
				surface.set_normal(sample[1]);surface.set_color(sample[2]);surface.add_vertex(sample[0])
	distant_terrain=MeshInstance3D.new();distant_terrain.mesh=surface.commit()
	distant_terrain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	distant_material=ShaderMaterial.new();distant_material.shader=preload("res://Assets/Shaders/distant_terrain.gdshader")
	distant_terrain.material_override=distant_material;add_child(distant_terrain)
	_chunk_mask_signature=-1
	_update_chunk_mask()
func _spawn_ground_life(parent: Node3D,key: Vector2i) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=int(world_description["seed"])+key.x*1973+key.y*9277
	var stem:=CylinderMesh.new();stem.top_radius=0.015;stem.bottom_radius=0.025;stem.height=0.32;stem.radial_segments=5
	var flower:=SphereMesh.new();flower.radius=0.065;flower.height=0.055;flower.radial_segments=6;flower.rings=3
	for layer in range(2):
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true
		multi.mesh=stem if layer==0 else flower;multi.instance_count=20
		var batch:=MultiMeshInstance3D.new();batch.multimesh=multi
		var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=0.95
		batch.material_override=mat;batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(batch)
		rng.seed=int(world_description["seed"])+key.x*1973+key.y*9277
		for i in range(20):
			var at:=Vector3(key.x*16+rng.randf_range(0,16),0,key.y*16+rng.randf_range(0,16));at.y=terrain_height(at.x,at.z)
			var basis:=Basis.IDENTITY
			if at.y<water_level+0.7 or sampler.biome(at.x,at.z) in ["desert","volcanic","tundra"]:basis=basis.scaled(Vector3.ZERO)
			at.y+=0.16 if layer==0 else 0.34
			multi.set_instance_transform(i,Transform3D(basis,at))
			multi.set_instance_color(i,Color("#5a8851") if layer==0 else [Color("#dfc36b"),Color("#aa95c7"),Color("#ead9bf")][i%3])

func _make_distant_forest() -> void:
	if is_instance_valid(far_forest):far_forest.queue_free()
	forest_material=null
	forest_ids.clear();forest_transforms.clear();forest_cut_hash=-1
	if int(world_description["generator"])<2 or DisplayServer.get_name()=="headless":return
	var holder:=Node3D.new()
	Shapes.cylinder(holder,0.22,2.9,Vector3(0,1.45,0),Color("#66503a"))
	Shapes.sculpted(holder,Vector3(0,3.3,0),Vector3(3.0,2.4,2.9),Color("#55774b"),"fur")
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in holder.get_children():
		var arrays:Array=part.mesh.surface_get_arrays(0)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		for i in range(indices.size() if not indices.is_empty() else vertices.size()):
			var index:int=indices[i] if not indices.is_empty() else i
			surface.set_normal((part.basis.inverse().transposed()*normals[index]).normalized())
			surface.set_color(part.material_override.albedo_color)
			surface.add_vertex(part.transform*vertices[index])
	holder.free()
	var records:Array=[]
	for items in _chunk_records.values():
		for record in items:
			if int(record["id"])%6==0:records.append(record)
	var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=surface.commit();multi.instance_count=records.size()
	for i in range(records.size()):
		var record:Dictionary=records[i]
		var transform:=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*float(record["size"])),record["position"])
		multi.set_instance_transform(i,transform);forest_ids[int(record["id"])]=i;forest_transforms.append(transform)
	far_forest=MultiMeshInstance3D.new();far_forest.multimesh=multi
	far_forest.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	forest_material=ShaderMaterial.new();forest_material.shader=preload("res://Assets/Shaders/distant_forest.gdshader")
	far_forest.material_override=forest_material;add_child(far_forest)
func _sync_distant_forest() -> void:
	if not is_instance_valid(far_forest):return
	var signature:int=hash(_cut_registry)
	if signature==forest_cut_hash:return
	forest_cut_hash=signature
	for id in forest_ids:
		var index:int=forest_ids[id];var at:Transform3D=forest_transforms[index]
		if _cut_registry.has(id):at.basis=at.basis.scaled(Vector3.ZERO)
		far_forest.multimesh.set_instance_transform(index,at)

func _make_watershed_landmarks() -> void:
	for z in sampler.watershed.crossings:
		var x: float = sampler.river_x(z)
		var bridge := StaticBody3D.new(); bridge.name = "SeedBridge"; bridge.add_to_group("seed_bridge")
		bridge.position = Vector3(x, water_level+1.2, z); add_child(bridge); _poi_nodes.append(bridge)
		var width: float = sampler.watershed.width(z)*2+18
		for i in range(18):
			var at := Vector3((i+0.5)/18.0*width-width*0.5,0,0)
			Shapes.box(bridge,Vector3(width/18.0+0.03,0.22,3.2),at,Color("#8c7048").lightened((i%3)*0.03))
		var slab := BoxShape3D.new(); slab.size = Vector3(width,0.3,3.2); Shapes.collider(bridge,slab,Vector3.ZERO)
		Shapes.consolidate(bridge)
	# Small elevated tributary waterfall, adjacent to the low main valley.
	var falls := Node3D.new(); falls.position = sampler.waterfall; add_child(falls); _poi_nodes.append(falls)
	for side in [-1,1]:
		Shapes.sculpted(falls,Vector3(side*2.3,-3,0),Vector3(2,5,2),Color("#72796c"),"head",side+2)
	var sheet := PlaneMesh.new(); sheet.size = Vector2(3.2,8)
	var flow := MeshInstance3D.new(); flow.mesh=sheet; flow.position=Vector3(0,-4,0); flow.rotation.x=PI/2
	var material := ShaderMaterial.new(); material.shader=preload("res://Assets/Shaders/cascade.gdshader"); flow.material_override=material
	falls.add_child(flow)
	var pool := Shapes.sphere(falls,2.0,Vector3(0,-7.7,0),Color("#b1dcce")); pool.scale=Vector3(1.4,0.08,0.8)

func _update_chunk_mask() -> void:
	if distant_material == null: return
	var signature:=hash(_chunks.keys())
	if signature==_chunk_mask_signature:return
	_chunk_mask_signature=signature
	var side:=ceili(half_extent()/16.0)*2
	_chunk_mask=Image.create(side,side,false,Image.FORMAT_L8)
	_chunk_mask.fill(Color.BLACK)
	for key in _chunks:
		var cell:Vector2i=key+Vector2i(side/2,side/2)
		if cell.x>=0 and cell.x<side and cell.y>=0 and cell.y<side:_chunk_mask.set_pixel(cell.x,cell.y,Color.WHITE)
	_chunk_mask_texture=ImageTexture.create_from_image(_chunk_mask)
	distant_material.set_shader_parameter("loaded_chunks",_chunk_mask_texture)
	distant_material.set_shader_parameter("world_extent",half_extent())
