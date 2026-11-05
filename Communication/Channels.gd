extends RefCounted
## Routing decisions use server positions and membership, never client-provided positions.
var local_range: float = 40.0
var voice_range: float = 30.0
var groups: Dictionary = {}
var invitations: Dictionary = {}
var calls: Dictionary = {}
var blocked: Dictionary = {}
var _messages: Dictionary = {}

func recipients(sender: String, channel: String, target: String, positions: Dictionary, tribes, voice: bool = false) -> Array:
	if not positions.has(sender):
		return []
	var result: Array = []
	for key in positions:
		if sender in blocked.get(key, []) or key in blocked.get(sender, []):
			continue
		var allowed := false
		match channel:
			"global":
				allowed = not voice
			"local", "proximity":
				allowed = positions[sender].distance_to(positions[key]) <= (voice_range if voice else local_range)
			"tribe":
				allowed = tribes.tribe_of(sender) != "" and tribes.tribe_of(sender) == tribes.tribe_of(key)
			"allies":
				var a: String = tribes.tribe_of(sender)
				var b: String = tribes.tribe_of(key)
				allowed = not a.is_empty() and not b.is_empty() and (a == b or tribes.relations.get(tribes.pair_key(a, b), {}).get("status") == "allied")
			"private":
				if voice:
					allowed = calls.has(target) and calls[target]["accepted"] and sender in calls[target]["members"] and key in calls[target]["members"]
				else:
					allowed = positions.has(target) and key in [sender, target]
			"group", "diplomacy":
				allowed = groups.has(target) and groups[target]["kind"] == channel and sender in groups[target]["members"] and key in groups[target]["members"]
				if allowed and channel == "diplomacy":
					allowed = _diplomat(sender, groups[target]["owner"], tribes) and _diplomat(key, groups[target]["owner"], tribes)
		if allowed:
			result.append(key)
	return result

func allow_text(sender: String, message: String, now: float = -1.0) -> bool:
	if now < 0:
		now = Time.get_unix_time_from_system()
	if message.strip_edges().is_empty() or message.length() > 240 or message.to_utf8_buffer().has(0):
		return false
	var recent: Array = _messages.get(sender, [])
	recent = recent.filter(func(t): return now - float(t) < 10.0)
	if recent.size() >= 5:
		return false
	recent.append(now)
	_messages[sender] = recent
	return true

func command(actor: String, action: String, data: Dictionary, online: Array, tribes) -> bool:
	var target := str(data.get("target", ""))
	var id := str(data.get("id", ""))
	match action:
		"group_create":
			var title := str(data.get("name", "")).strip_edges()
			var kind := str(data.get("kind", "group"))
			if title.is_empty() or title.length() > 32 or groups.size() >= 64 or kind not in ["group", "diplomacy"]:
				return false
			if kind == "diplomacy" and not _leader(actor, tribes):
				return false
			id = Crypto.new().generate_random_bytes(16).hex_encode()
			groups[id] = {"name": title, "kind": kind, "owner": actor, "members": [actor]}
		"group_invite":
			if not groups.has(id) or groups[id]["owner"] != actor or not target in online or target in groups[id]["members"]:
				return false
			if groups[id]["members"].size() >= 100:
				return false
			if groups[id]["kind"] == "diplomacy" and not _diplomat(target, actor, tribes):
				return false
			invitations[target] = {"id": id, "until": Time.get_unix_time_from_system() + 600}
		"group_accept":
			var invite: Dictionary = invitations.get(actor, {})
			if invite.is_empty() or not groups.has(invite["id"]) or invite["until"] < Time.get_unix_time_from_system():
				return false
			var info: Dictionary = groups[invite["id"]]
			if info["members"].size() >= 100 or actor in info["members"] or (info["kind"] == "diplomacy" and not _diplomat(actor, info["owner"], tribes)):
				return false
			groups[invite["id"]]["members"].append(actor)
			invitations.erase(actor)
		"group_leave", "group_kick":
			if not groups.has(id) or not actor in groups[id]["members"]:
				return false
			var departing := actor if action == "group_leave" else target
			if action == "group_kick" and (groups[id]["owner"] != actor or departing == actor):
				return false
			groups[id]["members"].erase(departing)
			if groups[id]["members"].is_empty():
				groups.erase(id)
			elif groups[id]["owner"] == departing:
				groups[id]["owner"] = groups[id]["members"][0]
		"call_invite":
			if not target in online or target == actor or actor in blocked.get(target, []) or target in blocked.get(actor, []) or calls.size() >= 64:
				return false
			var active := 0
			for call in calls.values():
				if actor in call["members"]:
					active += 1
			if active >= 4:
				return false
			id = Crypto.new().generate_random_bytes(16).hex_encode()
			calls[id] = {"members": [actor, target], "accepted": false}
		"call_accept":
			if not calls.has(id) or calls[id]["members"][1] != actor:
				return false
			calls[id]["accepted"] = true
		"call_leave":
			if not calls.has(id) or not actor in calls[id]["members"]:
				return false
			calls.erase(id)
		"block":
			if not target in online or target == actor:
				return false
			var entries: Array = blocked.get(actor, [])
			if bool(data.get("enabled", true)) and not target in entries:
				if entries.size() >= 256:
					return false
				entries.append(target)
			elif not bool(data.get("enabled", true)):
				entries.erase(target)
			blocked[actor] = entries
		_:
			return false
	return true

func disconnected(key: String) -> void:
	for id in calls.keys():
		if key in calls[id]["members"]:
			calls.erase(id)

func public_state(key: String) -> Dictionary:
	var visible_groups: Dictionary = {}
	var visible_calls: Dictionary = {}
	for id in groups:
		if key in groups[id]["members"]:
			visible_groups[id] = groups[id].duplicate(true)
	for id in calls:
		if key in calls[id]["members"]:
			visible_calls[id] = calls[id].duplicate(true)
	return {"groups": visible_groups, "calls": visible_calls, "invitation": invitations.get(key, {}).duplicate(), "blocked": blocked.get(key, []).duplicate()}

func _leader(key: String, tribes) -> bool:
	var id: String = tribes.tribe_of(key)
	return id != "" and tribes.tribes[id]["leader"] == key

func _diplomat(key: String, owner: String, tribes) -> bool:
	return _leader(owner, tribes) and (_leader(key, tribes) or tribes.tribe_of(key) == tribes.tribe_of(owner))

func state() -> Dictionary:
	# Calls and invitations require fresh consent after a process restart.
	return {"groups": groups.duplicate(true), "blocked": blocked.duplicate(true)}

func restore(data: Dictionary) -> void:
	groups.clear()
	blocked.clear()
	calls.clear()
	invitations.clear()
	_messages.clear()
	if valid_state(data):
		groups = data["groups"].duplicate(true)
		blocked = data["blocked"].duplicate(true)

static func valid_state(data: Dictionary) -> bool:
	if data.size() != 2 or not data.get("groups") is Dictionary or not data.get("blocked") is Dictionary or data["groups"].size() > 64 or data["blocked"].size() > 1024:
		return false
	for id in data["groups"]:
		var info: Variant = data["groups"][id]
		if not _identity(id) or not info is Dictionary or info.size() != 4 or not _identity(info.get("owner")):
			return false
		if not info.get("name") is String or info["name"].strip_edges().is_empty() or info["name"].length() > 32 or info["name"].to_utf8_buffer().has(0) or info.get("kind") not in ["group", "diplomacy"]:
			return false
		if not _members(info.get("members"), 100) or not info["owner"] in info["members"]:
			return false
	for id in data["blocked"]:
		if not _identity(id) or not _members(data["blocked"][id], 256, true) or id in data["blocked"][id]:
			return false
	return true

static func _identity(value: Variant) -> bool:
	return value is String and not value.is_empty() and value.length() <= 128 and not value.to_utf8_buffer().has(0)

static func _members(values: Variant, limit: int, empty: bool = false) -> bool:
	if not values is Array or values.size() > limit or (values.is_empty() and not empty):
		return false
	var seen: Dictionary = {}
	for value in values:
		if not _identity(value) or seen.has(value):
			return false
		seen[value] = true
	return true
