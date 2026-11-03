extends RefCounted
## Immutable procedural sampler. It can also build vertex arrays on a worker.
const LEGACY := {"seed": 1337, "generator": 0, "size": 128}
const WATER_LEVEL := -2.9
var changes: Dictionary = {}
var settings: Dictionary
var relief := FastNoiseLite.new()
var detail := FastNoiseLite.new()
var moisture := FastNoiseLite.new()
var temperature := FastNoiseLite.new()
var locations: Array[Dictionary] = []
var river_offset: float = 0.0
var lake_center := Vector2.ZERO

func _init(description: Dictionary = LEGACY, edits: Dictionary = {}) -> void:
	changes=edits.duplicate(true)
	settings = description.duplicate(true)
	var seed_value := int(settings.get("seed", 1337))
	for index in range(4):
		var noise: FastNoiseLite = [relief, detail, moisture, temperature][index]
		noise.seed = seed_value + index * 7919
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = [0.012, 0.042, 0.009, 0.007][index]
		noise.fractal_octaves = 4 if index == 0 else 2
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 413
	river_offset = rng.randf_range(30, 55) * (-1 if seed_value % 2 else 1)
	lake_center = Vector2(river_offset + rng.randf_range(-12, 12), rng.randf_range(55, 85))
	var cave := Vector2(rng.randf_range(-85, -55), rng.randf_range(-70, -40))
	var ruins := Vector2(rng.randf_range(65, 95), rng.randf_range(-65, -35))
	locations.append({"kind": "cave", "position": Vector3(cave.x, raw_height(cave.x, cave.y), cave.y), "id": 3000})
	locations.append({"kind": "ruins", "position": Vector3(ruins.x, raw_height(ruins.x, ruins.y), ruins.y), "id": 3001})
	if int(settings.get("generator",0))>=2:
		for i in range(8):
			var a:=float(i)*TAU/8+rng.randf_range(-0.12,0.12)
			var p:=Vector2(cos(a),sin(a))*rng.randf_range(350,510)
			for attempt in range(80):
				if raw_height(p.x,p.y)>1.0: break
				p.x+=2
			locations.append({"kind":"monument","position":Vector3(p.x,raw_height(p.x,p.y),p.y),"id":3010+i})

static func legacy_height(x: float, z: float) -> float:
	return sin(x * 0.052) * 1.6 + cos(z * 0.047) * 1.4 + sin((x + z) * 0.031) * 0.8

func river_x(z: float) -> float:
	return river_offset + sin(z * 0.026 + int(settings["seed"]) * 0.01) * 12.0

func raw_height(x: float, z: float) -> float:
	if int(settings.get("generator", 0)) == 0:
		return legacy_height(x, z)
	if int(settings.get("generator", 0)) >= 2: return living_height(x,z)
	var continental := relief.get_noise_2d(x, z)
	var ridges := pow(maxf(0, absf(relief.get_noise_2d(x + 420, z - 310)) - 0.18), 1.8) * 40.0
	var value := 3.0 + continental * 7.0 + detail.get_noise_2d(x, z) * 1.2 + ridges
	# Dry, gently sloped start remains suitable for the original survival loop.
	var safe := 1.0 - smoothstep(8.0, 19.0, Vector2(x, z).length())
	value = lerpf(value, legacy_height(x, z), safe)
	var half_size := float(settings.get("size", 320)) * 0.5
	var coast := smoothstep(half_size * 0.72, half_size * 0.98, maxf(absf(x), absf(z)))
	value = lerpf(value, -8.5, coast)
	# A meandering channel connects the northern uplands, lake and southern sea.
	var channel := 1.0 - smoothstep(2.2, 5.8, absf(x - river_x(z)))
	value = lerpf(value, WATER_LEVEL - 0.8, channel)
	var lake := 1.0 - smoothstep(11.0, 19.0, Vector2(x, z).distance_to(lake_center))
	return lerpf(value, WATER_LEVEL - 1.3, lake)

func height(x: float, z: float) -> float:
	var value := raw_height(x, z)
	if int(settings.get("generator", 0)) != 0:
		for place in locations:
			var p: Vector3 = place["position"]
			var radius := 9.0 if place["kind"] == "cave" else 11.0
			var flatten := 1.0 - smoothstep(radius - 3.0, radius, Vector2(x - p.x, z - p.z).length())
			value = lerpf(value, p.y, flatten)
	var gx:=floori(x/4.0);var gz:=floori(z/4.0)
	var sx:=fposmod(x,4.0)/4.0;var sz:=fposmod(z,4.0)/4.0
	var depths:Array=[]
	for cell in [Vector2i(gx,gz),Vector2i(gx+1,gz),Vector2i(gx,gz+1),Vector2i(gx+1,gz+1)]: depths.append(float(changes.get("%d,%d"%[cell.x,cell.y],0)))
	return value-lerpf(lerpf(depths[0],depths[1],sx),lerpf(depths[2],depths[3],sx),sz)

func biome(x: float, z: float) -> String:
	var elevation := height(x, z)
	if elevation < WATER_LEVEL + 1.2: return "beach"
	if int(settings.get("generator", 0)) == 0: return "forest" if Vector2(x, z).length() > 15 else "plains"
	var wet := moisture.get_noise_2d(x, z)
	var heat := temperature.get_noise_2d(x, z)
	if elevation > 14.0: return "tundra" if heat < 0.0 else "mountains"
	if heat > 0.28 and wet < -0.2: return "desert"
	if heat > 0.36 and elevation > 7: return "volcanic"
	if wet > 0.3 and elevation < 5.0: return "marsh"
	if wet > 0.0: return "forest"
	if wet > -0.25: return "woodland"
	return "plains"

func ground_color(x: float, z: float, normal: Vector3) -> Color:
	var tint: Color = {"plains": Color("#718c49"), "forest": Color("#456d42"),
		"woodland": Color("#738951"), "marsh": Color("#526f52"), "mountains": Color("#83887c"),
		"tundra": Color("#c8d7d0"), "beach": Color("#c7b889"), "desert": Color("#b9a77a"),
		"volcanic": Color("#665e57")}[biome(x, z)]
	tint = tint.lerp(Color("#747971"), smoothstep(0.15, 0.5, 1.0 - normal.y))
	return tint.lightened(detail.get_noise_2d(x * 3.0, z * 3.0) * 0.12)

func chunk_arrays(x0: int, z0: int) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var samples: Dictionary = {}
	for z in range(9):
		for x in range(9):
			var px := x0 + x * 2.0
			var pz := z0 + z * 2.0
			var n := Vector3(height(px - 0.2, pz) - height(px + 0.2, pz), 0.4,
				height(px, pz - 0.2) - height(px, pz + 0.2)).normalized()
			var tint := ground_color(px, pz, n)
			if int(settings.get("generator", 0)) == 0:
				var h := height(px, pz)
				tint = Color("#356744").lerp(Color("#668243"), clampf((h + 3.0) / 7.0, 0, 1))
				if h < -2.1: tint = tint.lerp(Color("#b7a574"), clampf((-h - 2.1) * 2, 0, 1))
				if Vector2(px, pz).length() < 5.0: tint = tint.lerp(Color("#94845a"), 0.4)
			samples[Vector2i(x, z)] = [Vector3(px, height(px, pz), pz), n, tint]
	for z in range(8):
		for x in range(8):
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var value: Array = samples[Vector2i(x, z) + offset]
				vertices.append(value[0]); normals.append(value[1]); colors.append(value[2])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	return arrays

# Generator 2 is separate: historical worlds retain their exact height function.
func living_height(x: float, z: float) -> float:
	var distance := Vector2(x,z).length()
	var ridges := pow(1.0-absf(relief.get_noise_2d(x*0.32+470,z*0.32-190)),3.0)
	var highlands := smoothstep(85,240,distance)*smoothstep(0.35,0.75,moisture.get_noise_2d(x*0.32,z*0.32)+0.5)
	var value := 5.0+relief.get_noise_2d(x*0.65,z*0.65)*12.0+detail.get_noise_2d(x,z)*1.5+ridges*highlands*48.0
	value=lerpf(legacy_height(x,z),value,smoothstep(16,42,distance))
	var coast:=smoothstep(620,755,maxf(absf(x),absf(z)))
	value=lerpf(value,-12.0,coast)
	var river_distance:=absf(x-river_x(z))
	var valley:=1.0-smoothstep(15.0,40.0,river_distance)
	var bank:=WATER_LEVEL+0.6+maxf(0,river_distance-10.0)*0.22
	value=lerpf(value,minf(value,bank),valley)
	var channel:=1.0-smoothstep(7.0,15.0,river_distance)
	# Navigable continuous main river: at least 14 m wide and 3 m deep.
	value=lerpf(value,WATER_LEVEL-3.5,channel)
	var lake:=1.0-smoothstep(18.0,29.0,Vector2(x,z).distance_to(lake_center))
	return lerpf(value,WATER_LEVEL-4.0,lake)
