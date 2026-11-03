extends CanvasLayer
## Presentation only: inventory, weather and networking commands are owned by Main.

var game
var language: int = 0
var mode: String = "loading"
var stats: Label
var hint: Label
var notice_label: Label
var exposure_label: Label
var panel: PanelContainer
var column: VBoxContainer
var shade: ColorRect
var cross: Label
var notice_left: float = 0.0
var previous_panel: String = "menu"
var inventory_signature: String = ""
var refresh_left: float = 0.0
var sensitivity_value: float = 0.003
var root: Control

const INK := Color("#e8e6d0")
const GOLD := Color("#eeb777")
const MUTED := Color("#b0c5b6")


func t(pt: String, en: String) -> String:
	return game.localization.text(en, pt) if game != null and game.localization != null else (pt if language == 0 else en)


func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 17
	theme.default_font = preload("res://Assets/Fonts/NotoSansCJK-Regular.ttc")
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", Color("#6f827a"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("#29433d")
		if state == "hover" or state == "focus":
			button_style.bg_color = Color("#3a5746")
		elif state == "pressed":
			button_style.bg_color = Color("#705735")
		elif state == "disabled":
			button_style.bg_color = Color("#1d302d")
		button_style.corner_radius_top_left = 6
		button_style.corner_radius_top_right = 6
		button_style.corner_radius_bottom_left = 6
		button_style.corner_radius_bottom_right = 6
		button_style.content_margin_left = 16
		button_style.content_margin_right = 16
		button_style.content_margin_top = 9
		button_style.content_margin_bottom = 9
		theme.set_stylebox(state, "Button", button_style)
	root.theme = theme
	var minimap := preload("res://UI/NavigationMiniMap.gd").new(); minimap.game=game
	minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left=-178;minimap.offset_right=-18;minimap.offset_top=18;minimap.offset_bottom=178
	minimap.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(minimap)
	var quickbar := preload("res://UI/Quickbar.gd").new();quickbar.game=game
	quickbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	quickbar.offset_left=18;quickbar.offset_right=-18;quickbar.offset_top=-70;quickbar.offset_bottom=-14
	root.add_child(quickbar)
	stats = Label.new()
	stats.position = Vector2(24, 18)
	stats.add_theme_font_size_override("font_size", 18)
	stats.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	stats.add_theme_constant_override("shadow_offset_x", 2)
	stats.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(stats)
	exposure_label = Label.new()
	exposure_label.position = Vector2(24, 102)
	exposure_label.add_theme_color_override("font_color", Color("#b6d9ef"))
	root.add_child(exposure_label)
	hint = Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -110
	hint.offset_bottom = -78
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(hint)
	notice_label = Label.new()
	notice_label.position = Vector2(24, 158)
	notice_label.add_theme_color_override("font_color", GOLD)
	notice_label.add_theme_font_size_override("font_size", 18)
	root.add_child(notice_label)
	cross = Label.new()
	cross.text = "·"
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.add_theme_font_size_override("font_size", 32)
	root.add_child(cross)
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.03, 0.03, 0.64)
	root.add_child(shade)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -308
	panel.offset_bottom = 308
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.125, 0.115, 0.98)
	style.border_color = Color("#a08052")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 20
	style.content_margin_bottom = 18
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)
	get_viewport().size_changed.connect(_fit_panel)
	_fit_panel()
	loading(t("Preparando o mundo…", "Preparing the world…"))


func _fit_panel() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var half_width := minf(420.0 if mode in ["inventory", "map"] else 300.0, viewport_size.x * 0.5 - 12.0)
	var half_height := minf(308.0, viewport_size.y * 0.5 - 12.0)
	panel.offset_left = -half_width
	panel.offset_right = half_width
	panel.offset_top = -half_height
	panel.offset_bottom = half_height


func text(value: String, size: int = 17, tint: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(label)
	return label


func button(value: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = value
	control.custom_minimum_size.y = 40
	control.pressed.connect(action)
	control.pressed.connect(func():
		if game.runtime != null:
			game.runtime.audio.click())
	column.add_child(control)
	return control


func clear() -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()


func _heading(subtitle: String) -> void:
	text("TRIBES OF FIRE", 32, GOLD)
	text(subtitle, 17, MUTED)
	var divider := HSeparator.new()
	column.add_child(divider)


func _footer() -> void:
	text(t("Criado por felipealx", "Created by felipealx") + " · " + str(ProjectSettings.get_setting("application/config/version")), 14, MUTED)


func loading(value: String) -> void:
	mode = "loading"
	if game != null:
		game.set_controls(false)
	panel.show()
	shade.show()
	cross.hide()
	clear()
	_heading(t("Uma nova chama. Uma nova jornada.", "A new flame. A new journey."))
	text(value, 19)
	_footer()


func show_panel(value: String) -> void:
	mode = value
	_fit_panel()
	game.set_controls(value == "")
	panel.visible = value != ""
	shade.visible = value != ""
	cross.visible = value == ""
	if value == "":
		return
	clear()
	match value:
		"language":
			_language()
		"character":
			_heading(tr("Create character"))
			_add_panel(preload("res://UI/CharacterCreator.gd"))
		"graphics":
			_heading(tr("Graphics"))
			_add_panel(preload("res://UI/GraphicsPanel.gd"))
			button(tr("Back"), func(): show_panel("settings"))
		"controls":
			_heading(tr("Controls"))
			_add_panel(preload("res://UI/ControlsPanel.gd"))
			button(tr("Back"), func(): show_panel("settings"))
		"communication":
			_heading(tr("Communication"))
			_add_panel(preload("res://UI/CommunicationPanel.gd"))
			button(tr("Back"), func(): show_panel("pause"))
		"death":
			_heading(tr("You died"))
			button(tr("Respawn"), func(): game.request_command("respawn", {}))
			button(tr("Return to main menu"), Callable(game,"return_to_menu"))
		"inventory":
			_heading(tr("Inventory"))
			_add_panel(preload("res://UI/InventoryPanel.gd"))
			button(tr("Drink"), func(): game.request_command("drink", {}))
			button(tr("Cook"), func(): game.request_command("cook", {}))
			button(tr("Back"), func(): show_panel(""))
		"network":
			_network()
		"settings":
			_settings()
		"admin": _admin()
		"create_world": _create_world()
		"help": _help()
		"technology": _technology()
		"storage": _storage()
		"factory": _factory()
		"clans": _clans()
		"map":
			_heading(tr("World map"))
			_add_panel(preload("res://UI/WorldMap.gd"))
			button(tr("Back"), func(): show_panel("pause"))
		"credits":
			_heading(tr("Credits"))
			text("felipealx · Tribes of Fire")
			text("Godot Engine — MIT")
			text("Noto Sans CJK — SIL Open Font License 1.1")
			text(tr("Original procedural models, music and sounds."))
			button(tr("Back"), func(): show_panel("menu"))
		"menu":
			_main_menu()
		"loading":
			loading(t("Conectando…", "Connecting…"))
		_:
			_pause()
	_footer()


func _main_menu() -> void:
	var emblem:=TextureRect.new();emblem.texture=preload("res://Assets/icon.svg")
	emblem.custom_minimum_size=Vector2(64,64);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;column.add_child(emblem)
	_heading(t("Sobrevivência • exploração • construção", "Survival • exploration • building"))
	button(t("Continuar jornada salva", "Continue saved journey"), Callable(game, "load_game")).disabled = game.saved.is_empty()
	button(t("Nova jornada local", "New local journey"), func(): show_panel("create_world"))
	button(t("Hospedar / Conectar por IP", "Host / Connect by IP"), func(): show_panel("network"))
	button(t("Configurações", "Settings"), func():
		previous_panel = "menu"
		show_panel("settings"))
	button(tr("Credits"), func(): show_panel("credits"))
	button(t("Sair", "Quit"), Callable(game, "quit_game"))
	text(t("Versão em desenvolvimento. A nova jornada substitui o progresso local ao salvar.",
		"Development build. A new journey replaces local progress when saved."), 14, MUTED)


func _pause() -> void:
	_heading(t("ACAMPAMENTO", "CAMP"))
	button(t("Tribos e diplomacia","Tribes and diplomacy"),func():show_panel("clans"))
	button(t("Retomar jornada", "Resume journey"), func(): show_panel(""))
	var save_button := button(t("Salvar [F5]", "Save [F5]"), Callable(game, "save_game"))
	var load_button := button(t("Carregar [F9]", "Load [F9]"), Callable(game, "load_game"))
	if game.session != null and not game.session.is_authority():
		save_button.disabled = true
		load_button.disabled = true
		text(t("O servidor salva o mundo compartilhado.", "The server saves the shared world."), 14, MUTED)
	button(t("Configurações", "Settings"), func():
		previous_panel = "pause"
		show_panel("settings"))
	for entry in [["World map","map"],["Technology and crafting","technology"],["Help","help"]]:
		var destination: String = entry[1]
		button(tr(entry[0]), func(): show_panel(destination))
	button(tr("Return to main menu"), Callable(game,"return_to_menu"))
	button(tr("Communication"), func(): show_panel("communication"))
	if game.session.is_admin(game.session.local_id): button(tr("Administration"),func():show_panel("admin"))
	button(t("Sair do jogo", "Quit game"), Callable(game, "quit_game"))
	text(t("O tempo do mundo continua enquanto o processo está ativo.",
		"World time continues while the process is running."), 14, MUTED)


func _network() -> void:
	_heading(t("PARTIDA MULTIPLAYER", "MULTIPLAYER GAME"))
	text(t("Conexão direta por IP. O anfitrião controla movimento, coleta, construções e clima.",
		"Direct IP connection. The host controls movement, gathering, building and weather."), 15, MUTED)
	text(t("Endereço do servidor", "Server address"))
	var address := LineEdit.new()
	address.text = "127.0.0.1"
	address.placeholder_text = "192.168.1.10"
	address.max_length = 253
	column.add_child(address)
	text(t("Porta UDP", "UDP port"))
	var port := SpinBox.new()
	port.min_value = 1024
	port.max_value = 65535
	port.value = 24567
	port.step = 1
	port.rounded = true
	column.add_child(port)
	text(tr("Server password (optional)"))
	var password := LineEdit.new()
	password.secret = true
	password.max_length = 128
	column.add_child(password)
	button(t("Hospedar neste computador", "Host on this computer"), func():
		var selected_port := int(port.value)
		loading(t("Iniciando servidor…", "Starting server…"))
		game.host_game(selected_port, password.text))
	button(t("Conectar ao servidor", "Connect to server"), func():
		var selected_address := address.text.strip_edges()
		var selected_port := int(port.value)
		if selected_address.is_empty() or selected_address.contains("/") or selected_address.contains("://"):
			notify_message(t("Informe somente o IP ou nome do servidor.", "Enter only the server IP or hostname."))
			return
		loading(t("Conectando ao servidor…", "Connecting to server…"))
		game.join_game(selected_address, selected_port, password.text))
	button(t("Voltar", "Back"), func(): show_panel("menu"))
	text(t("Multiplayer experimental; capacidade de 100 jogadores ainda não validada. Pela Internet, o anfitrião precisa liberar a porta UDP no roteador.",
		"Experimental multiplayer; 100-player capacity has not been validated. Internet hosting requires forwarding the UDP port on your router."), 14, MUTED)


func notify_message(value: String) -> void:
	notice_label.text = value
	notice_left = 6.0
	# Also visible above the dimmed background in menus.
	notice_label.z_index = 3


func _process(delta: float) -> void:
	notice_left -= delta
	notice_label.visible = notice_left > 0
	if game == null or game.player == null:
		stats.text = ""
		hint.text = ""
		exposure_label.text = ""
		return
	var equipped := preload("res://Items/Catalog.gd").display_name(game.inventory.equipped_item()) if game.inventory != null else tr("Axe")
	if game.tool == 2:
		equipped = t("Fogueira", "Campfire")
	elif game.tool == 3:
		equipped = t("Abrigo", "Shelter")
	var wood_count: int = game.inventory.count("wood") if game.inventory != null else 0
	stats.text = t("VIDA %d / 100   RESISTÊNCIA %d\nMADEIRA %d   %s   %s",
		"HEALTH %d / 100   STAMINA %d\nWOOD %d   %s   %s") % [
		game.player.vitals.hp, int(game.player.stamina), wood_count, game.clock.label(), equipped]
	if game.exposure != null:
		var seconds: float = game.exposure.exposure_seconds
		var wet: float = game.exposure.wetness
		var temperature: float = game.exposure.temperature
		var comfort: bool = game.exposure.comfort
		if seconds > 0:
			var warning := t("Procurando abrigo", "Seek shelter") if seconds < 40.0 else t("Exposição prolongada", "Prolonged exposure")
			exposure_label.text = t("CHUVA %ds   UMIDADE %d%%   %.1f°C\n%s • primeiro dano aos 55s", "RAIN %ds   WETNESS %d%%   %.1f°C\n%s • first damage at 55s") % [int(seconds), int(wet * 100.0), temperature, warning]
		elif wet > 0.02 or comfort:
			exposure_label.text = t("UMIDADE %d%%   %.1f°C   %s", "WETNESS %d%%   %.1f°C   %s") % [int(wet * 100.0), temperature, t("Aquecendo", "Warming") if comfort else t("Secando", "Drying")]
		else:
			exposure_label.text = ""
	hint.visible = mode == ""
	hint.text = equipped
	if is_instance_valid(game.player.boat):hint.text=t("W/S remar · A/D virar · E desembarcar","W/S row · A/D turn · E disembark")
	elif game.runtime.mining!=null:
		var resource:int=game.runtime.mining.closest(game.player,3.0)
		if resource>=0:hint.text="[E] "+preload("res://Items/Catalog.gd").display_name(game.runtime.mining.resource_kind(resource))
	var activity: Dictionary = game.runtime.activities.action_state(game.session.local_id)
	if float(activity.get("total",0))>0:
		hint.text = tr("Gathering") + " · %d%%" % roundi((1.0-float(activity["remaining"])/float(activity["total"]))*100.0)
	var bearing := posmod(roundi(rad_to_deg(game.player.yaw)),360)
	var directions := ["N","NW","W","SW","S","SE","E","NE"]
	hint.text += "   ·   " + directions[posmod(roundi(bearing/45.0),8)]
	if game.survival != null:
		stats.text += "\n%s %.0f   %s %.0f" % [tr("Hunger"), game.survival.hunger, tr("Thirst"), game.survival.thirst]
	if game.player.vitals.hp <= 0 and mode != "death":
		show_panel("death")
	elif game.player.vitals.hp > 0 and mode == "death":
		show_panel("")

func _add_panel(script: GDScript) -> void:
	var content = script.new()
	column.add_child(content)
	content.configure(game, language)

func _language() -> void:
	_heading("Selecione seu idioma / Select your language")
	for i in range(game.localization.CODES.size()):
		var code: String = game.localization.CODES[i]
		button(game.localization.NAMES[i], func():
			if game.localization.select(code):
				notice_left = 0
				language = game.localization.CODES.find(code)
				if game.chat_ui != null:
					game.chat_ui.refresh_texts()
				show_panel("settings" if game.localization.chosen and game.running else "menu"))

func _settings() -> void:
	_heading(tr("Settings"))
	var minimap_toggle := CheckBox.new(); minimap_toggle.text=t("Mostrar minimapa", "Show minimap")
	minimap_toggle.button_pressed=game.settings_manager.read("accessibility","minimap",false)==true
	minimap_toggle.toggled.connect(func(value):game.settings_manager.write_sections({"accessibility":{"minimap":value}}));column.add_child(minimap_toggle)
	button(tr("Graphics"), func(): show_panel("graphics"))
	button(tr("Controls"), func(): show_panel("controls"))
	button(tr("Language"), func(): show_panel("language"))
	if game.running:
		button(tr("Communication"), func(): show_panel("communication"))
	var sound_enabled := CheckBox.new()
	sound_enabled.text = tr("Sound")
	sound_enabled.button_pressed = game.sound
	sound_enabled.toggled.connect(func(v): game.sound = v; AudioServer.set_bus_mute(0, not v); game.save_settings())
	column.add_child(sound_enabled)
	for bus in ["Master", "Music", "Ambient", "Effects", "UI", "Vocalizations", "Voice"]:
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		text(tr("Audio") + " · " + tr(bus))
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.01
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(index))
		slider.value_changed.connect(func(v): AudioServer.set_bus_volume_db(index, linear_to_db(maxf(v, 0.0001))); game.save_settings())
		column.add_child(slider)
	button(tr("Back"), func(): show_panel(previous_panel))

func _create_world() -> void:
	_heading(tr("Create world"))
	text(tr("Seed (leave empty for a new random world)"))
	var seed_input := LineEdit.new()
	seed_input.max_length = 10
	column.add_child(seed_input)
	text(tr("New continent: 1536 × 1536 m. Existing worlds keep their terrain."), 14, MUTED)
	button(tr("Create world"), func():
		var seed_value := -1
		if not seed_input.text.strip_edges().is_empty():
			if not seed_input.text.is_valid_int() or int(seed_input.text)<0 or int(seed_input.text)>2147483647:
				notify_message(tr("Invalid seed"));return
			seed_value=int(seed_input.text)
		game.new_game(seed_value))
	button(tr("Back"),func(): show_panel("menu"))
func _help() -> void:
	_heading(tr("Help"))
	text(t("WASD mover • Mouse câmera • Shift correr • Espaço pular\n1 machado • 2 fogueira • 3 abrigo • Clique usar • I / Tab inventário • Esc menu", "WASD move • Mouse camera • Shift sprint • Space jump\n1 axe • 2 campfire • 3 shelter • Click use • I / Tab inventory • Esc menu"))
	text(tr("Gathering takes time. Pick up the dropped materials after cutting or mining."))
	text(tr("Map: M · Rotate building: R · Interact: E"))
	button(tr("Back"),func():show_panel("pause"))
func _technology() -> void:
	_heading(tr("Technology and crafting"))
	var id: int = game.session.local_id
	if not game.runtime.progression.has(id): return
	var profile = game.runtime.progression[id]
	text(tr("Era")+": "+str(game.runtime.Profile.era(game.runtime.known_technologies(id))))
	for skill in profile.skills:
		text(tr(skill.capitalize())+": "+str(profile.level(skill)),14,MUTED)
	for key in profile.technologies():
		var technology: String = key
		var definition: Dictionary = profile.technologies()[key]
		var cost := PackedStringArray()
		for item in definition["cost"]: cost.append(preload("res://Items/Catalog.gd").display_name(item)+" × "+str(definition["cost"][item]))
		button(tr(definition["name"])+" · "+", ".join(cost),func():game.request_command("research",{"technology":technology})).disabled=key in game.runtime.known_technologies(id)
	var queue: Array = game.runtime.activities.queue(id)
	for index in range(queue.size()):
		var selected: int = index
		button(tr("Cancel")+" · "+preload("res://Items/Catalog.gd").display_name(queue[index]["recipe"]),func():game.request_command("craft_cancel",{"index":selected}))
	button(tr("Refuel campfire"),func():game.request_command("refuel",{}))
	button(tr("Fish with a spear"),func():game.request_command("fish",{}))
	button(tr("Feed and tame a nearby animal"),func():game.request_command("tame",{"animal":0}))
	var garden = game.world.structure_near(game.player,"garden",4)
	if garden!=null:
		button(tr("Plant berries"),func():game.request_command("plant",{"structure":garden.structure_id,"crop":"berries"}))
		button(tr("Harvest"),func():game.request_command("harvest_crop",{"structure":garden.structure_id}))
	button(tr("Back"),func():show_panel("pause"))
func _storage() -> void:
	_heading(tr("Storage"))
	_add_panel(preload("res://UI/StoragePanel.gd"))
	button(tr("Back"),func():show_panel(""))

func apply_accessibility(config: Dictionary) -> void:
	if root==null or panel==null: return
	var contrast: bool = config.get("high_contrast",false)
	root.theme.set_color("font_color","Label",Color.WHITE if contrast else INK)
	root.theme.set_color("font_color","Button",Color.WHITE if contrast else INK)
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color("#080b0a") if contrast else Color(0.065,0.125,0.115,0.98)
	style.border_color = Color.WHITE if contrast else Color("#a08052")
	panel.add_theme_stylebox_override("panel",style)

func _admin() -> void:
	_heading(tr("Administration"))
	if not game.session.is_admin(game.session.local_id):
		button(tr("Back"),func():show_panel("pause"));return
	var targets:=OptionButton.new();var keys:Array=[]
	for id in game.players:
		if id==game.session.local_id: continue
		targets.add_item(game.players[id].appearance["name"]);keys.append(game.players[id].get_meta("key",""))
	column.add_child(targets)
	for action in ["kick","ban","mute","unmute"]:
		var selected: String=action
		button(tr(action.capitalize()),func():
			if targets.selected>=0 and targets.selected<keys.size():game.session.send_admin_action(selected,{"target":keys[targets.selected]})).disabled=keys.is_empty()
	button(tr("Save"),func():game.session.send_admin_action("save",{}))
	var pvp:=CheckBox.new();pvp.text=tr("PvP enabled");pvp.button_pressed=game.server_rules["pvp"]=="on"
	pvp.toggled.connect(func(v):game.session.send_admin_action("set_rule",{"rule":"pvp","value":"on" if v else "off"}));column.add_child(pvp)
	button(tr("Back"),func():show_panel("pause"))

func _factory() -> void:
	var info:Dictionary=game.runtime.factory_view
	if info.is_empty():return
	_heading(t("Oficina de produção","Production workshop"))
	_add_panel(preload("res://UI/StationPanel.gd"))
	button(tr("Back"),func():show_panel(""))

func _clans() -> void:
	_heading(t("Tribos e diplomacia","Tribes and diplomacy"))
	var tribes=game.runtime.tribes
	var me:String=game.session.player_key(game.session.local_id)
	var own:String=tribes.tribe_of(me)
	button(t("Criar tribo / gerenciar membros","Create tribe / manage members"),func():show_panel("communication"))
	if own.is_empty():
		text(t("Crie ou entre em uma tribo para participar da diplomacia.","Create or join a tribe to participate in diplomacy."))
	else:
		text(str(tribes.tribes[own]["name"]),25)
		text(t("Modo PvP: ","PvP mode: ")+str(game.server_rules["pvp"]))
		for target in tribes.tribes:
			if target==own:continue
			var row:Dictionary=tribes.relations.get(tribes.pair_key(own,target),{})
			text(str(tribes.tribes[target]["name"])+" · "+tr(str(row.get("status","neutral")).capitalize()),21)
			var remaining:float=maxf(0,float(row.get("until",0))-Time.get_unix_time_from_system())
			if remaining>0:text(t("Proteção: ","Protection: ")+"%d min"%ceili(remaining/60))
			if tribes.tribes[own]["leader"]!=me:continue
			for entry in [["tribe_war",t("Declarar guerra","Declare war")],["tribe_alliance",t("Propor aliança","Propose alliance")],["tribe_accept_alliance",t("Aceitar aliança","Accept alliance")],["tribe_peace",t("Propor paz","Propose peace")],["tribe_accept_peace",t("Aceitar paz","Accept peace")],["tribe_break_alliance",t("Romper aliança (1h de proteção)","End alliance (1h protection)")]]:
				var action:String=entry[0];var destination:String=target
				var b:=button(entry[1],func():game.request_command(action,{"target":destination}))
				if "accept" in action:b.disabled=row.get("requested_by","")!=target or row.get("request","")!=("alliance" if "alliance" in action else "peace")
				elif action=="tribe_break_alliance":b.disabled=row.get("status","")!="allied"
				elif action=="tribe_war":b.disabled=remaining>0 or row.get("status","")=="allied"
	button(tr("Refresh"),func():show_panel("clans"))
	button(tr("Back"),func():show_panel("pause"))
