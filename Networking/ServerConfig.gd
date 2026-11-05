extends RefCounted
## Local server configuration. Passwords are never included in public_state().
const DEFAULTS := {
	"name": "Tribes of Fire", "port": 24567, "password": "", "max_players": 16,
	"seed": 1337, "pvp": "on", "death_loss": 0.0, "day_minutes": 30.0,
	"night_minutes": 15.0, "resource_rate": 1.0, "difficulty": "normal",
	"admins": [], "bans": [], "structural_support": false
}
static func defaults() -> Dictionary:
	return DEFAULTS.duplicate(true)
static func normalize(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {"error": "Server configuration must be a JSON object", "data": {}}
	var result := defaults()
	for key in value:
		if not key is String or not DEFAULTS.has(key):
			return {"error": "Unknown server configuration field", "data": {}}
		result[key] = value[key]
	for key in ["name", "password", "pvp", "difficulty"]:
		if not result[key] is String or result[key].to_utf8_buffer().has(0):
			return {"error": "Invalid server text option: " + key, "data": {}}
	if result["name"].strip_edges().is_empty() or result["name"].length() > 64 or result["password"].length() > 128 or result["pvp"] not in ["on", "off", "war"] or result["difficulty"] not in ["peaceful", "normal", "hard"]:
		return {"error": "Invalid server name, password length or gameplay mode", "data": {}}
	if not result["structural_support"] is bool: return {"error":"structural_support must be boolean","data":{}}
	var limits := {"port": [1, 65535], "max_players": [1, 100], "seed": [0, 2147483647], "death_loss": [0, 1], "day_minutes": [1, 180], "night_minutes": [1, 180], "resource_rate": [0.25, 4]}
	for key in limits:
		var number: Variant = result[key]
		if not (number is int or number is float) or not is_finite(float(number)) or number < limits[key][0] or number > limits[key][1]:
			return {"error": "Invalid numeric server option: " + key, "data": {}}
		if key in ["port", "max_players", "seed"]:
			if float(number) != floorf(float(number)):
				return {"error": "Server option requires an integer: " + key, "data": {}}
			result[key] = int(number)
	for key in ["admins", "bans"]:
		if not result[key] is Array or result[key].size() > 1024:
			return {"error": "Invalid identity list: " + key, "data": {}}
		var seen: Dictionary = {}
		for identity in result[key]:
			if not identity_valid(identity) or seen.has(identity):
				return {"error": "Invalid or duplicate server identity", "data": {}}
			seen[identity] = true
	return {"error": "", "data": result}
static func load_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Could not open the server configuration", "data": {}}
	if file.get_length() > 262144:
		file.close()
		return {"error": "Server configuration exceeds its size limit", "data": {}}
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK:
		return {"error": "Server configuration contains invalid JSON", "data": {}}
	return normalize(parser.data)
static func identity_valid(value: Variant) -> bool:
	if not value is String or value.length() != 64:
		return false
	for character in value:
		if character not in "0123456789abcdef": return false
	return true
static func public_state(options: Dictionary) -> Dictionary:
	var result := options.duplicate(true)
	result.erase("password")
	result.erase("admins")
	result.erase("bans")
	result["password_required"] = not str(options.get("password", "")).is_empty()
	return result
