extends RefCounted
const ConfigStore = preload("res://Settings/ConfigStore.gd")
const CODES := ["pt_BR", "en_US", "es", "fr", "de", "ja"]
const NAMES := ["Português (Brasil)", "English", "Español", "Français", "Deutsch", "日本語"]
var locale: String = "pt_BR"
var chosen: bool = false
var catalog: Dictionary = {}
var config_path: String
func _init(path: String = "user://settings.cfg") -> void:
	config_path = path
	for code in CODES:
		var resource = load("res://Localization/%s.po" % code)
		if resource is Translation:
			TranslationServer.add_translation(resource)
	ConfigStore.recover_preferences(config_path)
	var config := ConfigFile.new()
	if config.load(config_path) == OK:
		var stored: Variant = config.get_value("language", "locale", "")
		if stored is String and stored in CODES:
			locale = stored
			chosen = true
	if not chosen and config_path == "user://settings.cfg":
		var previous := ConfigFile.new()
		if previous.load("user://language.cfg") == OK:
			var stored: Variant = previous.get_value("language","locale","")
			if stored is String and stored in CODES: select(stored)
		if not chosen and OS.get_name()=="Windows":
			var output: Array = []
			if OS.execute("reg",["query","HKCU\\Software\\felipealx\\TribesOfFire","/v","InstallerLanguage"],output,true)==0:
				var pattern := RegEx.new();pattern.compile("REG_DWORD\\s+(0x[0-9a-fA-F]+|[0-9]+)")
				var found := pattern.search("".join(output))
				if found != null:
					var id := found.get_string(1).hex_to_int() if found.get_string(1).begins_with("0x") else int(found.get_string(1))
					var codes := {1046:"pt_BR",1033:"en_US",1034:"es",3082:"es",1036:"fr",1031:"de",1041:"ja"}
					if codes.has(id): select(codes[id])
	TranslationServer.set_locale(locale)
func select(code: String) -> bool:
	if not code in CODES:
		return false
	if ConfigStore.write_sections({"language":{"locale":code}}, config_path) != OK:
		return false
	locale = code
	chosen = true
	TranslationServer.set_locale(code)
	return true
func text(english: String, portuguese: String = "") -> String:
	var translated := TranslationServer.translate(english)
	if translated == english and locale == "pt_BR" and portuguese != "":
		return portuguese
	return translated
