extends VBoxContainer
var game
var target: String = ""
var group: String = ""
var _test_auto_enabled: bool = false
func configure(value, _language: int = 0) -> void:
	game = value
	build()
func label_text(value: String) -> Label:
	var label := Label.new()
	label.text = tr(value)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label
func button(value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = tr(value)
	b.pressed.connect(callback)
	add_child(b)
	return b
func line(title: String, default_text: String = "") -> LineEdit:
	label_text(title)
	var field := LineEdit.new()
	field.max_length = 32
	field.text = default_text
	add_child(field)
	return field
func build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var me: String = game.session.player_key(game.session.local_id)
	label_text("Players")
	var list := OptionButton.new()
	list.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var identities: Array[String] = []
	for id in game.players:
		var identity: String = game.runtime.key(id)
		if identity == me:
			continue
		identities.append(identity)
		list.add_item(str(game.players[id].appearance["name"]) + " · " + str(id))
		if identity == target:
			list.select(identities.size() - 1)
	if target == "" and not identities.is_empty():
		target = identities[0]
	list.item_selected.connect(func(i): target = identities[i]; build())
	add_child(list)
	if target != "":
		label_text("Player volume")
		var gain := HSlider.new()
		gain.min_value = 0
		gain.max_value = 2
		gain.step = 0.05
		gain.value = float(game.runtime.voice.individual_volume.get(target, 1.0))
		gain.value_changed.connect(func(v): game.runtime.voice.individual_volume[target] = v; game.runtime.voice.save_settings())
		add_child(gain)
	button("Private", func(): game.hud.show_panel(""); game.chat_ui.open("private", target))
	button("Call", func(): game.request_command("call_invite", {"target": target}))
	button("Invite", func(): game.request_command("tribe_invite", {"target": target}))
	button("Mute", func(): game.runtime.voice.muted[target] = true; game.runtime.voice.save_settings())
	button("Unmute", func(): game.runtime.voice.muted[target] = false; game.runtime.voice.save_settings())
	button("Block", func(): game.request_command("block", {"target": target, "enabled": true}))
	button("Unblock", func(): game.request_command("block", {"target": target, "enabled": false}))
	button("Refresh", build)
	label_text("Tribe")
	var title := line("Name", "Tribe")
	button("Create tribe", func(): game.request_command("tribe_create", {"name": title.text}))
	var own: String = game.runtime.tribes.tribe_of(me)
	if own != "":
		var tribe_name := label_text("")
		tribe_name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		tribe_name.text = str(game.runtime.tribes.tribes[own]["name"])
		button("Leave", func(): game.request_command("tribe_leave", {}))
		if game.runtime.tribes.tribes[own]["leader"] == me:
			button("Kick", func(): game.request_command("tribe_kick", {"target": target}))
			button("Transfer leadership", func(): game.request_command("tribe_leader", {"target": target}))
	if game.runtime.tribes.invitations.has(me):
		button("Accept", func(): game.request_command("tribe_accept", {}))
	label_text("Group")
	var group_name := line("Name", "Group")
	button("Create", func(): game.request_command("group_create", {"name": group_name.text, "kind": "group"}))
	button("Diplomacy", func(): game.request_command("group_create", {"name": group_name.text, "kind": "diplomacy"}))
	var groups: Dictionary = game.runtime.channel_state.get("groups", {})
	var group_list := OptionButton.new()
	group_list.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var ids: Array = groups.keys()
	for id in ids:
		group_list.add_item(groups[id]["name"])
		if id == group:
			group_list.select(ids.find(id))
	if group == "" and not ids.is_empty():
		group = ids[0]
	group_list.item_selected.connect(func(i): group = ids[i])
	add_child(group_list)
	button("Invite to group", func(): game.request_command("group_invite", {"id": group, "target": target}))
	button("Leave group", func(): game.request_command("group_leave", {"id": group}))
	button("Remove from group", func(): game.request_command("group_kick", {"id": group, "target": target}))
	if not game.runtime.channel_state.get("invitation", {}).is_empty():
		button("Accept group invitation", func(): game.request_command("group_accept", {}))
	for id in game.runtime.channel_state.get("calls", {}):
		var call_id: String = id
		var call: Dictionary = game.runtime.channel_state["calls"][id]
		if not call["accepted"] and call["members"][1] == me:
			button("Accept call", func(): game.request_command("call_accept", {"id": call_id}))
		button("End call", func(): game.request_command("call_leave", {"id": call_id}))
	_voice_settings()
func _voice_settings() -> void:
	var voice = game.runtime.voice
	label_text("Voice chat")
	var enabled := CheckBox.new()
	enabled.text = tr("Enable microphone")
	enabled.button_pressed = voice.enabled
	enabled.toggled.connect(func(v):
		# Explicit user activation supersedes the temporary test-only activation.
		_test_auto_enabled = false
		voice.set_enabled(v))
	add_child(enabled)
	var mode := OptionButton.new()
	mode.add_item(tr("Push to talk") + " [V]")
	mode.add_item(tr("Voice activation"))
	mode.select(1 if voice.open_microphone else 0)
	mode.item_selected.connect(func(i): voice.open_microphone = i == 1)
	add_child(mode)
	var channel := OptionButton.new()
	var options: Array = [["proximity", "", tr("Local")], ["tribe", "", tr("Tribe")]]
	for id in game.runtime.channel_state.get("groups", {}):
		var info: Dictionary = game.runtime.channel_state["groups"][id]
		options.append([info["kind"], id, info["name"]])
	for id in game.runtime.channel_state.get("calls", {}):
		if game.runtime.channel_state["calls"][id]["accepted"]:
			options.append(["private", id, tr("Private") + " · " + str(id).left(6)])
	for i in range(options.size()):
		channel.add_item(options[i][2])
		if voice.channel == options[i][0] and voice.target == options[i][1]:
			channel.select(i)
	channel.item_selected.connect(func(i): voice.channel = options[i][0]; voice.target = options[i][1])
	add_child(channel)
	for entry in [["Input device", true], ["Output device", false]]:
		var input: bool = entry[1]
		label_text(entry[0])
		var devices: PackedStringArray = AudioServer.get_input_device_list() if input else AudioServer.get_output_device_list()
		var selector := OptionButton.new()
		for device in devices:
			selector.add_item(device)
		selector.disabled = devices.is_empty()
		selector.item_selected.connect(func(i):
			if input: AudioServer.input_device = devices[i]
			else: AudioServer.output_device = devices[i])
		add_child(selector)
	for entry in [["Volume", 0.0, 1.0, voice.volume], ["Sensitivity", 0.001, 0.2, voice.threshold]]:
		var is_volume: bool = entry[0] == "Volume"
		label_text(entry[0])
		var slider := HSlider.new()
		slider.min_value = entry[1]
		slider.max_value = entry[2]
		slider.step = 0.001
		slider.value = entry[3]
		slider.value_changed.connect(func(v):
			if is_volume: voice.volume = v
			else: voice.threshold = v
			voice.save_settings())
		add_child(slider)
	var test_button := button("Stop test" if voice.testing else "Test microphone", _toggle_test)
	test_button.name = "MicrophoneTest"
	var status := label_text("")
	status.name = "VoiceStatus"
func _toggle_test() -> void:
	var voice = game.runtime.voice
	if voice.testing:
		_finish_test()
	else:
		_test_auto_enabled = not voice.enabled
		if _test_auto_enabled:
			voice.set_enabled(true)
		voice.testing = voice.enabled
	build()
func _finish_test() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.runtime) or not is_instance_valid(game.runtime.voice):
		return
	if game.runtime.voice.testing or game.runtime.voice.receivers.has(-1):
		game.runtime.voice.stop_test()
	if _test_auto_enabled:
		game.runtime.voice.set_enabled(false)
	_test_auto_enabled = false
func _exit_tree() -> void:
	_finish_test()
func _process(_delta: float) -> void:
	var test_button := get_node_or_null("MicrophoneTest") as Button
	if test_button != null:
		test_button.text = tr("Stop test" if game.runtime.voice.testing else "Test microphone")
	var status := get_node_or_null("VoiceStatus") as Label
	if status != null:
		var voice = game.runtime.voice
		status.text = ("● " if voice.transmitting else "○ ") + tr(voice.channel.capitalize()) + "  %.0f%%" % (voice.level * 100) + "  " + tr(voice.status)
