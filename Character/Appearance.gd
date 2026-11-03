extends RefCounted
## Compact cosmetic data. Physics, reach and movement never depend on appearance.
const Shapes = preload("res://World/Shapes.gd")
const DEFAULT := {"name": "Survivor", "body": 0, "height": 1.48, "shoulders": 1.0, "volume": 1.0, "skin": 2, "eyes": 0, "eye_size": 1.0, "eye_spacing": 1.0, "eye_color": 0, "face": 1.0, "nose": 1.0, "mouth": 1.0, "ears": 1.0, "hair": 0, "hair_color": 0, "beard": 0, "clothing": 0}
const SKIN := [Color("#efd0ab"), Color("#dbaf83"), Color("#bc875e"), Color("#926244"), Color("#684832"), Color("#463426")]
const HAIR := [Color("#29251f"), Color("#50372a"), Color("#80583a"), Color("#c29b58"), Color("#a05332"), Color("#8a8c83"), Color("#ddd6bf")]
const EYES := [Color("#4b3024"), Color("#886140"), Color("#af8d36"), Color("#507850"), Color("#527e9c"), Color("#8a969b"), Color("#bb7835")]
static func valid(data: Dictionary) -> bool:
	if data.size() != DEFAULT.size():
		return false
	for key in DEFAULT:
		if not data.has(key):
			return false
	if not data["name"] is String or data["name"].strip_edges().length() < 2 or data["name"].length() > 24:
		return false
	for character in data["name"]:
		if character.unicode_at(0) < 32 or character in "<>[]{}\\/":
			return false
	for entry in [["body", 0, 1], ["skin", 0, 5], ["eyes", 0, 2], ["eye_color", 0, 6], ["hair", 0, 8], ["hair_color", 0, 6], ["beard", 0, 5], ["clothing", 0, 5]]:
		var value: Variant = data[entry[0]]
		if not (value is int or value is float) or not is_finite(float(value)) or value != floorf(value) or value < entry[1] or value > entry[2]:
			return false
	for entry in [["height", 1.35, 1.65], ["shoulders", 0.9, 1.15], ["volume", 0.85, 1.15], ["eye_size", 0.8, 1.2], ["eye_spacing", 0.85, 1.15], ["face", 0.85, 1.15], ["nose", 0.8, 1.2], ["mouth", 0.8, 1.2], ["ears", 0.8, 1.2]]:
		var value: Variant = data[entry[0]]
		if not (value is int or value is float) or not is_finite(float(value)) or value < entry[1] or value > entry[2]:
			return false
	return true

static func apply(player, data: Dictionary) -> void:
	if not valid(data):
		return
	var old: Node3D = player.avatar
	if is_instance_valid(old):
		player.remove_child(old)
		old.queue_free()
	player._materials.clear()
	preload("res://Character/Model.gd").build(player, data)
	player.appearance = data.duplicate(true)
	if player.label != null:
		player.label.text = data["name"]
		player.label.font = preload("res://Assets/Fonts/NotoSansCJK-Regular.ttc")
		player.label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var rig = preload("res://Character/Rig.gd").new()
	rig.name = "CharacterRig"
	player.rig = rig
	rig.setup(player)
	player.avatar.add_child(rig)
	player.set_equipment(player.visual_equipment, true)
