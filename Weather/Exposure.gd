extends RefCounted

# Called only by the authoritative simulation. This integrates regeneration and
# rain damage in chronological order, even if a tick crosses several events.
const GRACE_SECONDS := 40.0
const DAMAGE_INTERVAL := 15.0
var exposure_seconds: float = 0.0
var next_damage_at: float = GRACE_SECONDS + DAMAGE_INTERVAL
var damage_count: int = 0
var wetness: float = 0.0
var temperature: float = 37.0
var comfort: bool = false

func reset() -> void:
	exposure_seconds = 0.0
	next_damage_at = GRACE_SECONDS + DAMAGE_INTERVAL

func advance(delta: float, raining: bool, sheltered: bool, vitals,
		near_fire: bool = false, safe: bool = true) -> void:
	if not is_finite(delta) or delta <= 0:
		return
	comfort = near_fire
	var exposed := raining and not sheltered
	if not exposed:
		reset()
		vitals.advance(delta, safe)
	else:
		var destination := exposure_seconds + delta
		while next_damage_at <= destination + 0.00000001:
			_advance_health(vitals, exposure_seconds, next_damage_at, safe)
			exposure_seconds = next_damage_at
			if not near_fire:
				vitals.damage(1)
				damage_count += 1
			next_damage_at += DAMAGE_INTERVAL
		_advance_health(vitals, exposure_seconds, destination, safe)
		exposure_seconds = destination
	var wet_rate := 1.0 / 80.0 if exposed else (-1.0 / 30.0 if near_fire else -1.0 / 120.0)
	wetness = clampf(wetness + wet_rate * delta, 0.0, 1.0)
	var target_temperature := 37.0 - wetness * (0.5 if near_fire else 3.5)
	temperature = lerpf(temperature, target_temperature, 1.0 - exp(-delta / 30.0))

func _advance_health(vitals, start: float, finish: float, safe: bool) -> void:
	# Split exactly at the harmful-exposure boundary; independent of frame size.
	var protected_time := maxf(0.0, minf(finish, GRACE_SECONDS) - start)
	if protected_time > 0.0:
		vitals.advance(protected_time, safe)
	if comfort:
		vitals.advance(maxf(0.0,finish-maxf(start,GRACE_SECONDS)),safe)
		return
	var harmful_time := maxf(0.0, finish - maxf(start, GRACE_SECONDS))
	if harmful_time > 0.0 or finish >= GRACE_SECONDS:
		# At the boundary itself clear a previously accumulated partial interval.
		vitals.quiet_seconds = 0.0
		vitals.advance(harmful_time, false)

func state() -> Dictionary:
	return {"exposure": exposure_seconds, "wetness": wetness,
		"temperature": temperature, "comfort": comfort, "rain_damage": damage_count}

func restore(data: Dictionary) -> void:
	if not valid(data):
		return
	exposure_seconds = float(data["exposure"])
	wetness = float(data["wetness"])
	temperature = float(data["temperature"])
	damage_count = int(data["rain_damage"])
	comfort = bool(data.get("comfort", false))
	next_damage_at = GRACE_SECONDS + DAMAGE_INTERVAL
	if exposure_seconds >= next_damage_at:
		next_damage_at += (floorf((exposure_seconds - next_damage_at) / DAMAGE_INTERVAL) + 1.0) * DAMAGE_INTERVAL

static func valid(data: Dictionary) -> bool:
	for key in ["exposure", "wetness", "temperature", "rain_damage"]:
		var value: Variant = data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
	if float(data["exposure"]) < 0 or float(data["exposure"]) > 1000000000:
		return false
	if float(data["wetness"]) < 0 or float(data["wetness"]) > 1:
		return false
	if float(data["temperature"]) < 0 or float(data["temperature"]) > 50:
		return false
	return float(data["rain_damage"]) >= 0 and float(data["rain_damage"]) <= 1000000000 \
		and float(data["rain_damage"]) == floorf(float(data["rain_damage"]))
