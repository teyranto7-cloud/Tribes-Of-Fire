extends RefCounted
## Generator 3 hydrology: carve a continuous valley before placing vegetation/POIs.
var phase: float
var offset: float
var crossings: Array[float] = [-420.0, -140.0, 180.0, 430.0]
func _init(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = seed_value + 7189
	phase = rng.randf_range(-PI, PI)
	offset = rng.randf_range(48, 66) * (-1 if seed_value % 2 else 1)
func center(z: float) -> float:
	return offset + sin(z * 0.007 + phase) * 27 + sin(z * 0.017 + phase) * 8
func width(z: float) -> float:
	return 8.0 + 3.0 * (0.5 + 0.5 * sin(z * 0.013 + phase))
func current(z: float) -> float:
	return 0.5 + 1.1 * (0.5 + 0.5 * sin(z * 0.009 + phase))
func is_crossing(z: float) -> bool:
	return crossings.any(func(at): return absf(z - at) < 5.0)
func carve(value: float, x: float, z: float, water: float) -> float:
	var distance := absf(x - center(z))
	var bank := water + 1.0 + maxf(0, distance - width(z)) * 0.16
	value = lerpf(value, minf(value, bank), 1.0 - smoothstep(width(z) + 6, width(z) + 38, distance))
	var bed := water - 3.4
	if is_crossing(z): bed = water - 0.35
	return lerpf(value, bed, 1.0 - smoothstep(width(z) * 0.65, width(z) + 4, distance))
