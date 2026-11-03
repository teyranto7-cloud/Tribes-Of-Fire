extends RefCounted
var file: FileAccess
func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
	var name := "session-%d-%d.jsonl" % [int(Time.get_unix_time_from_system()), OS.get_process_id()]
	file = FileAccess.open("user://logs/" + name, FileAccess.WRITE)
	record("startup", {"version": ProjectSettings.get_setting("application/config/version"), "godot": Engine.get_version_info()["string"], "os": OS.get_name(), "renderer": RenderingServer.get_current_rendering_method()})
func record(stage: String, details: Dictionary = {}) -> void:
	# Only explicit technical metadata, never identities, chat, command payloads or audio.
	if file != null:
		file.store_line(JSON.stringify({"time_utc": Time.get_datetime_string_from_system(true), "stage": stage, "details": details}))
		file.flush()
