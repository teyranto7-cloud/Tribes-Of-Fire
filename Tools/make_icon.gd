extends SceneTree
func _initialize() -> void:
	var image := Image.new()
	var error := image.load_svg_from_string(FileAccess.get_file_as_string("res://Assets/icon.svg"), 1.0)
	if error != OK:
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/tools"))
	quit(image.save_png("res://builds/tools/icon.png"))
