extends RefCounted
const Balance = preload("res://Game/Balance.gd")

const MAX_HP := 100
const REGEN_INTERVAL := 3.0
var hp: int = MAX_HP
var quiet_seconds: float = 0.0
var regen_delay: float = Balance.number("vitals", "regen_delay", 6)
var regen_block_left: float = 0.0

func damage(amount: int) -> void:
	if amount <= 0 or hp <= 0:
		return
	hp = maxi(0, hp - amount)
	quiet_seconds = 0.0
	regen_block_left = regen_delay

func advance(delta: float, safe: bool = true) -> void:
	if hp <= 0 or not is_finite(delta) or delta <= 0:
		return
	var available := maxf(0.0, delta - regen_block_left)
	regen_block_left = maxf(0.0, regen_block_left - delta)
	# Unsafe exposure/combat cannot bank partial regeneration for an instant heal.
	if not safe:
		quiet_seconds = 0.0
		return
	quiet_seconds += available
	var interval := maxf(0.01, Balance.number("vitals", "regen_interval", REGEN_INTERVAL))
	var ticks := int(floor((quiet_seconds + 0.00000001) / interval))
	if ticks > 0:
		quiet_seconds = maxf(0.0, quiet_seconds - ticks * interval)
		hp = mini(MAX_HP, hp + ticks)
