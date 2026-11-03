extends Node
## One presentation settings owner. No timer, automatic quality adjustment or periodic reload.
const ConfigStore = preload("res://Settings/ConfigStore.gd")
const GraphicsSettings = preload("res://Graphics/Settings.gd")
const DEFAULT_PATH := "user://settings.cfg"
var config_path: String = DEFAULT_PATH
var graphics = GraphicsSettings.new()
var last_error: String = ""
func _ready() -> void:
	ConfigStore.recover_preferences(config_path)
	graphics.load_settings(config_path)
func read(section: String, key: String, fallback: Variant = null, path: String = "") -> Variant:
	return ConfigStore.read(section, key, fallback, config_path if path.is_empty() else path)
func write_sections(sections: Dictionary, path: String = "") -> bool:
	var result := ConfigStore.write_sections(sections, config_path if path.is_empty() else path)
	last_error = "" if result == OK else error_string(result)
	return result == OK
