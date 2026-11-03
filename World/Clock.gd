extends RefCounted

const DAY := 1800.0
const NIGHT := 900.0
const CYCLE := DAY + NIGHT
var elapsed: float = 450.0
var day_seconds: float = DAY
var night_seconds: float = NIGHT

func advance(delta: float) -> void:
	if is_finite(delta):
		elapsed = fposmod(elapsed + maxf(delta, 0.0), day_seconds + night_seconds)

func hour() -> float:
	if elapsed < day_seconds:
		return 6.0 + elapsed / day_seconds * 12.0
	return fposmod(18.0 + (elapsed - day_seconds) / night_seconds * 12.0, 24.0)

func daylight() -> float:
	return clampf(sin((hour() - 6.0) / 24.0 * TAU), 0.0, 1.0)

func label() -> String:
	var h := hour()
	return "%02d:%02d" % [int(h), int((h - floorf(h)) * 60.0)]
