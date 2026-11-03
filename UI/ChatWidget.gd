extends CanvasLayer
var game
var panel: PanelContainer
var history: RichTextLabel
var field: LineEdit
var channel_choice: OptionButton
var targets: OptionButton
var identity_list: Array = []
var minimized: Button
var unread: int = 0
var channel: String = "global"
var target: String = ""
const CHANNELS := ["global", "local", "tribe", "private", "group", "diplomacy"]
func configure(value) -> void:
	game = value
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 14
	panel.offset_top = -310
	panel.offset_right = 540
	panel.offset_bottom = -90
	root.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	history = RichTextLabel.new()
	history.bbcode_enabled = false
	history.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	history.custom_minimum_size = Vector2(400, 130)
	history.scroll_following = true
	history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(history)
	var row := HBoxContainer.new()
	column.add_child(row)
	channel_choice = OptionButton.new()
	for option in CHANNELS:
		channel_choice.add_item(tr(option.capitalize()))
	channel_choice.item_selected.connect(func(i): channel = CHANNELS[i]; _targets())
	row.add_child(channel_choice)
	targets = OptionButton.new()
	targets.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	targets.item_selected.connect(func(i): target = identity_list[i])
	row.add_child(targets)
	var opacity := HSlider.new()
	opacity.min_value = 0.3
	opacity.max_value = 1
	opacity.value = 0.9
	opacity.custom_minimum_size.x = 80
	opacity.value_changed.connect(func(v): panel.modulate.a = v)
	row.add_child(opacity)
	var close := Button.new()
	close.text = "−"
	close.pressed.connect(hide_chat)
	row.add_child(close)
	field = LineEdit.new()
	field.max_length = 240
	field.placeholder_text = tr("Message") + " · /ajuda"
	field.text_submitted.connect(send)
	column.add_child(field)
	minimized = Button.new()
	minimized.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	minimized.offset_left = 14
	minimized.offset_top = -108
	minimized.offset_bottom = -78
	minimized.offset_right = 160
	minimized.text = tr("Chat")
	minimized.pressed.connect(func(): open())
	root.add_child(minimized)
	game.runtime.message_added.connect(_message)
	panel.hide()
func _message(message: Dictionary) -> void:
	var time := Time.get_time_string_from_unix_time(int(message["timestamp"]) + int(Time.get_time_zone_from_system()["bias"]) * 60)
	history.add_text("[%s] [%s] %s: %s\n" % [time, tr(str(message["channel"]).capitalize()), message["sender"], message["text"]])
	if not panel.visible:
		unread += 1
		minimized.text = "Chat [%d]" % unread
func open(choice: String = "", recipient: String = "") -> void:
	if choice in CHANNELS:
		channel = choice
	if recipient != "":
		target = recipient
	_targets()
	channel_choice.select(CHANNELS.find(channel))
	panel.show()
	minimized.hide()
	unread = 0
	game.set_controls(false)
	field.grab_focus()
func hide_chat() -> void:
	panel.hide()
	minimized.show()
	minimized.text = tr("Chat")
	field.release_focus()
	game.set_controls(game.hud.mode == "")

func reset_session() -> void:
	panel.hide()
	field.release_focus()
	field.clear()
	history.clear()
	unread = 0
	target = ""
	channel = "global"
	identity_list.clear()
	targets.clear()
	minimized.show()
	minimized.text = tr("Chat")
func _targets() -> void:
	targets.clear()
	identity_list.clear()
	if channel == "private":
		for id in game.players:
			if id == game.session.local_id:
				continue
			identity_list.append(game.runtime.key(id))
			targets.add_item(game.players[id].appearance["name"] + " · " + str(id))
	elif channel in ["group", "diplomacy"]:
		for id in game.runtime.channel_state["groups"]:
			if game.runtime.channel_state["groups"][id]["kind"] == channel:
				identity_list.append(id)
				targets.add_item(game.runtime.channel_state["groups"][id]["name"])
	if target in identity_list:
		targets.select(identity_list.find(target))
	elif not identity_list.is_empty():
		target = identity_list[0]
	else:
		target = ""
	targets.disabled = identity_list.is_empty()
func refresh_texts() -> void:
	minimized.text = tr("Chat")
	for i in range(CHANNELS.size()):
		channel_choice.set_item_text(i, tr(CHANNELS[i].capitalize()))
	field.placeholder_text = tr("Message") + " · /ajuda"
func send(raw: String) -> void:
	var text := raw.strip_edges()
	if text.is_empty():
		return
	if text in ["/ajuda", "/help"]:
		history.add_text("/global /local /tribo /grupo /msg ID message\n")
		field.clear()
		return
	if text.begins_with("/"):
		var pieces := text.split(" ", false, 1)
		var aliases := {"/global": "global", "/local": "local", "/tribo": "tribe", "/grupo": "group"}
		if aliases.has(pieces[0]):
			channel = aliases[pieces[0]]
			text = pieces[1] if pieces.size() > 1 else ""
		elif pieces[0] == "/msg" and pieces.size() > 1:
			var rest := pieces[1].split(" ", false, 1)
			if rest.size() < 2:
				return
			var id := int(rest[0])
			if not game.players.has(id):
				return
			channel = "private"
			target = game.runtime.key(id)
			text = rest[1]
		else:
			return
	game.request_command("chat", {"channel": channel, "target": target, "text": text})
	field.clear()
func _unhandled_input(event: InputEvent) -> void:
	if not game.running or game.player == null or game.player.creation_pending:
		return
	if event.is_action_pressed("chat") and not event.is_echo():
		if panel.visible: hide_chat()
		elif game.hud.mode == "": open()
		get_viewport().set_input_as_handled()
	elif panel.visible and event.is_action_pressed("menu"):
		hide_chat()
		get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
	visible = game != null and game.running and game.player != null and not game.player.creation_pending
