extends RefCounted
## Merge sections before atomically replacing preferences; never drops another module's values.
static func read(section: String, key: String, fallback: Variant = null, path: String = "user://settings.cfg") -> Variant:
	var config := ConfigFile.new()
	if config.load(path) != OK or not config.has_section_key(section, key):
		return fallback
	return config.get_value(section, key, fallback)
static func write_sections(sections: Dictionary, path: String = "user://settings.cfg") -> Error:
	var config := ConfigFile.new()
	config.load(path)
	for section in sections:
		if not sections[section] is Dictionary:
			return ERR_INVALID_DATA
		for key in sections[section]:
			config.set_value(str(section), str(key), sections[section][key])
	var absolute := ProjectSettings.globalize_path(path)
	var result := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if result != OK:
		return result
	var temporary := path + ".tmp"
	result = config.save(temporary)
	if result != OK:
		return result
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute)

static func recover_preferences(path: String = "user://settings.cfg") -> bool:
	if not FileAccess.file_exists(path): return false
	var stream := FileAccess.open(path, FileAccess.READ)
	var malformed := stream == null
	if stream != null:
		malformed = stream.get_length() > 262144
		stream.close()
	var config := ConfigFile.new()
	if not malformed: malformed = config.load(path) != OK
	if not malformed and config.has_section_key("metadata", "version"):
		var version: Variant = config.get_value("metadata", "version")
		malformed = not version is int or version > 1 or version < 0
	if not malformed: return false
	var absolute := ProjectSettings.globalize_path(path)
	var backup := absolute + ".bak"
	if FileAccess.file_exists(backup): backup += ".%d" % Time.get_ticks_usec()
	if DirAccess.rename_absolute(absolute, backup) != OK: return false
	config.clear()
	config.set_value("metadata", "version", 1)
	config.save(path)
	return true
