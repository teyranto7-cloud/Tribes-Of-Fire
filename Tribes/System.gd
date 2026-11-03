extends RefCounted
## All mutations run on the authority. Protection uses stable identities and UTC expiry.
const MAX_MEMBERS := 100
const MAX_PROTECTIONS := 2048
const PROTECTION_SECONDS := 300.0
var relations: Dictionary = {}
var tribes: Dictionary = {}
var invitations: Dictionary = {}
var protections: Array = []

func tribe_of(key: String) -> String:
	for id in tribes:
		if key in tribes[id]["members"]:
			return id
	return ""

func command(actor: String, action: String, data: Dictionary, now: float = -1.0) -> bool:
	if now < 0:
		now = Time.get_unix_time_from_system()
	if not is_finite(now):
		return false
	# Capacity checks must see only live protection; stale entries never block leaving.
	protections = protections.filter(func(p): return float(p["until"]) > now)
	var id := tribe_of(actor)
	var target := str(data.get("target", ""))
	if action in ["tribe_war","tribe_alliance","tribe_accept_alliance","tribe_break_alliance","tribe_peace","tribe_accept_peace"]:
		return diplomacy(actor,action,target,now)
	match action:
		"tribe_create":
			var title := str(data.get("name", "")).strip_edges()
			if id != "" or title.length() < 3 or title.length() > 32 or tribes.size() >= 64:
				return false
			id = Crypto.new().generate_random_bytes(16).hex_encode()
			tribes[id] = {"name": title, "leader": actor, "members": [actor]}
		"tribe_invite":
			if id == "" or tribes[id]["leader"] != actor or target == "" or tribe_of(target) != "":
				return false
			invitations[target] = {"tribe": id, "until": now + 600}
		"tribe_accept":
			var invite: Dictionary = invitations.get(actor, {})
			if id != "" or invite.is_empty() or float(invite["until"]) < now or not tribes.has(invite["tribe"]):
				return false
			if tribes[invite["tribe"]]["members"].size() >= MAX_MEMBERS:
				return false
			tribes[invite["tribe"]]["members"].append(actor)
			invitations.erase(actor)
		"tribe_leave", "tribe_kick":
			var departing := actor if action == "tribe_leave" else target
			if id == "" or (action == "tribe_kick" and (tribes[id]["leader"] != actor or target == actor or not target in tribes[id]["members"])):
				return false
			var former_members: Array = tribes[id]["members"].duplicate()
			former_members.erase(departing)
			if not former_members.is_empty():
				var existing := _equivalent_protection(departing, id, former_members)
				if existing < 0 and protections.size() >= MAX_PROTECTIONS:
					# Refuse before changing membership or dropping any live protection.
					return false
				if existing >= 0:
					protections[existing]["until"] = maxf(float(protections[existing]["until"]), now + PROTECTION_SECONDS)
				else:
					protections.append({"person": departing, "tribe": id, "members": former_members, "until": now + PROTECTION_SECONDS})
			tribes[id]["members"].erase(departing)
			if tribes[id]["members"].is_empty():
				tribes.erase(id)
			elif tribes[id]["leader"] == departing:
				tribes[id]["leader"] = tribes[id]["members"][0]
		"tribe_leader":
			if id == "" or tribes[id]["leader"] != actor or not target in tribes[id]["members"]:
				return false
			tribes[id]["leader"] = target
		_:
			return false
	return true

func _equivalent_protection(person: String, tribe: String, members: Array) -> int:
	for index in range(protections.size()):
		var existing: Dictionary = protections[index]
		if existing["person"] != person or existing["tribe"] != tribe:
			continue
		# Legacy v3 records also stored the departing player in this array.
		var previous: Array = existing["members"].filter(func(member): return member != person)
		if previous.size() != members.size():
			continue
		var equivalent := true
		for member in members:
			if not member in previous:
				equivalent = false
				break
		if equivalent:
			return index
	return -1

func can_damage(a: String, b: String, now: float = -1.0) -> bool:
	if a == b:
		return false
	if now < 0:
		now = Time.get_unix_time_from_system()
	var ta := tribe_of(a)
	var tb := tribe_of(b)
	if ta != "" and ta == tb:
		return false
	var relation:Dictionary=relations.get(pair_key(ta,tb),{})
	if relation.get("status","")=="allied" or float(relation.get("until",0))>now:return false
	for p in protections:
		if float(p["until"]) <= now:
			continue
		if (a == p["person"] and (b in p["members"] or tb == p["tribe"])) or (b == p["person"] and (a in p["members"] or ta == p["tribe"])):
			return false
	return true

func can_build(owner: String, actor: String) -> bool:
	return owner == actor or (tribe_of(owner) != "" and tribe_of(owner) == tribe_of(actor))

func state() -> Dictionary:
	return {"relations":relations.duplicate(true),"tribes": tribes.duplicate(true), "invitations": invitations.duplicate(true), "protections": protections.duplicate(true)}

func restore(data: Dictionary) -> void:
	if valid_state(data):
		relations=data.get("relations",{}).duplicate(true)
		tribes = data["tribes"].duplicate(true)
		invitations = data["invitations"].duplicate(true)
		protections = data["protections"].duplicate(true)

static func valid_state(data: Dictionary) -> bool:
	var ties:Variant=data.get("relations",{})
	if not ties is Dictionary or ties.size()>2048:return false
	for key in ties:
		var row:Variant=ties[key]
		if not key is String or key.length()>257 or key.split(":").size()!=2 or not row is Dictionary or row.size()!=4:return false
		if row.get("status") not in ["neutral","war","allied"] or row.get("request") not in ["","peace","alliance"] or not row.get("requested_by") is String:return false
		var until:Variant=row.get("until")
		if not (until is int or until is float) or not is_finite(float(until)) or until<0 or until>4102444800:return false
	if not data.get("tribes") is Dictionary or data["tribes"].size() > 64 or not data.get("invitations") is Dictionary or data["invitations"].size() > 1024 or not data.get("protections") is Array or data["protections"].size() > MAX_PROTECTIONS:
		return false
	for id in data["tribes"]:
		var t: Variant = data["tribes"][id]
		if not id is String or not t is Dictionary or not t.get("name") is String or t["name"].length() > 32 or not t.get("members") is Array or t["members"].size() > MAX_MEMBERS or not t.get("leader") in t["members"]:
			return false
		for member in t["members"]:
			if not member is String or member.length() > 128:
				return false
	for p in data["protections"]:
		if not p is Dictionary or not p.get("person") is String or not p.get("tribe") is String or not p.get("members") is Array or p["members"].size() > MAX_MEMBERS or not (p.get("until") is float or p.get("until") is int) or not is_finite(float(p["until"])):
			return false
	for key in data["invitations"]:
		var invite: Variant = data["invitations"][key]
		if not key is String or not invite is Dictionary or not invite.get("tribe") is String or not (invite.get("until") is float or invite.get("until") is int) or not is_finite(float(invite["until"])):
			return false
	return true

static func pair_key(a: String,b: String) -> String:
	return a+":"+b if a<b else b+":"+a
func at_war(a: String,b: String) -> bool:
	return not a.is_empty() and a!=b and relations.get(pair_key(a,b),{}).get("status","")=="war"
func diplomacy(actor: String,action: String,target: String,now: float) -> bool:
	var own:=tribe_of(actor)
	if own.is_empty() or own==target or not tribes.has(target) or tribes[own]["leader"]!=actor:return false
	var key:=pair_key(own,target)
	if not relations.has(key) and relations.size()>=2048:return false
	var row:Dictionary=relations.get(key,{"status":"neutral","request":"","requested_by":"","until":0.0}).duplicate()
	match action:
		"tribe_war":
			if row["status"]=="allied" or float(row["until"])>now:return false
			row["status"]="war";row["request"]="";row["requested_by"]=""
		"tribe_alliance","tribe_peace":
			row["request"]="alliance" if action=="tribe_alliance" else "peace";row["requested_by"]=own
		"tribe_accept_alliance","tribe_accept_peace":
			var request:="alliance" if action=="tribe_accept_alliance" else "peace"
			if row["request"]!=request or row["requested_by"]!=target:return false
			row["status"]="allied" if request=="alliance" else "neutral"
			row["request"]="";row["requested_by"]=""
		"tribe_break_alliance":
			if row["status"]!="allied":return false
			row["status"]="neutral";row["until"]=now+3600
			row["request"]="";row["requested_by"]=""
		_:return false
	relations[key]=row;return true
