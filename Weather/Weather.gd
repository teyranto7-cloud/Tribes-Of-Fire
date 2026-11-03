extends RefCounted

const CONDITIONS := ["clear", "cloudy", "light_rain", "heavy_rain", "storm", "fog"]
const PRESETS := {
	"clear": {"rain": 0.0, "wind": 0.15, "cloud": 0.05, "fog": 0.0, "temperature": 22.0},
	"cloudy": {"rain": 0.0, "wind": 0.3, "cloud": 0.75, "fog": 0.1, "temperature": 18.0},
	"light_rain": {"rain": 0.3, "wind": 0.35, "cloud": 0.8, "fog": 0.2, "temperature": 15.0},
	"heavy_rain": {"rain": 0.8, "wind": 0.65, "cloud": 0.95, "fog": 0.4, "temperature": 11.0},
	"storm": {"rain": 1.0, "wind": 1.0, "cloud": 1.0, "fog": 0.6, "temperature": 9.0},
	"fog": {"rain": 0.0, "wind": 0.1, "cloud": 0.5, "fog": 1.0, "temperature": 12.0}
}
var elapsed: float = 0.0
var remaining: float = 180.0
var condition: String = "clear"
var current: Dictionary = PRESETS["clear"].duplicate()
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 1337

func set_weather(value: String) -> bool:
	if not PRESETS.has(value):
		return false
	condition = value
	remaining = 240.0
	return true

func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0:
		return
	var left := delta
	while left > 0.00000001:
		var segment := minf(left, remaining)
		var alpha := 1.0 - exp(-segment / 18.0)
		var target: Dictionary = PRESETS[condition]
		for key in current:
			current[key] = lerpf(float(current[key]), float(target[key]), alpha)
		elapsed += segment
		remaining -= segment
		left -= segment
		if remaining <= 0.00000001:
			condition = CONDITIONS[rng.randi_range(0, CONDITIONS.size() - 1)]
			remaining = rng.randf_range(180.0, 420.0)

func state() -> Dictionary:
	var output := current.duplicate()
	output["condition"] = condition
	output["raining"] = float(current["rain"]) >= 0.05
	var phase := fposmod(elapsed, 19.0)
	output["lightning"] = (1.0 - phase / 0.14) if condition == "storm" and phase < 0.14 else 0.0
	return output

func serialize() -> Dictionary:
	return {"elapsed": elapsed, "remaining": remaining, "condition": condition,
		"current": current.duplicate(), "rng_state": str(rng.state)}

func restore(data: Dictionary) -> void:
	if not valid(data):
		return
	elapsed = float(data["elapsed"])
	remaining = float(data["remaining"])
	condition = str(data["condition"])
	current = data["current"].duplicate()
	rng.state = int(data["rng_state"])

static func valid(data: Dictionary) -> bool:
	if not data.get("condition") in CONDITIONS:
		return false
	for key in ["elapsed", "remaining"]:
		var value: Variant = data.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0:
			return false
	if float(data["remaining"]) > 420.0 or not data.get("current") is Dictionary:
		return false
	if not data.get("rng_state") is String or not str(data["rng_state"]).is_valid_int():
		return false
	var fields: Dictionary = data["current"]
	if fields.size() != 5:
		return false
	for key in ["rain", "wind", "cloud", "fog", "temperature"]:
		var value: Variant = fields.get(key)
		if not (value is float or value is int) or not is_finite(float(value)):
			return false
		if float(value) < (0.0 if key != "temperature" else -30.0) or float(value) > (1.0 if key != "temperature" else 60.0):
			return false
	return true
