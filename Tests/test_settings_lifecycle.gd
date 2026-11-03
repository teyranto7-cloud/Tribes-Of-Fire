extends SceneTree
## Real elapsed-time regression for preset selection, session changes and process restart.
var game
var preset: int = 0
var restore_check: bool = false
var started: int = 0
var expected: Dictionary
var seconds: float = 120.0
var failed: bool = false
func _initialize() -> void:
	for option in OS.get_cmdline_user_args():
		if option.begins_with("--qa-preset="): preset=int(option.trim_prefix("--qa-preset="))
		if option=="--qa-restore": restore_check=true
		if option.begins_with("--qa-seconds="): seconds=float(option.trim_prefix("--qa-seconds="))
	call_deferred("run")
func require(value: bool, message: String) -> void:
	if not value:
		failed=true
		push_error(message)
func run() -> void:
	game=load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)
	while not game.ready_world: await process_frame
	if restore_check:
		require(int(game.graphics.applied["preset"])==preset,"Preset restored in a new process")
		require(game.graphics.applied==_disk(),"New process faithfully restores every persisted field")
		print("SETTINGS_RESTART_PASS preset=%d" % preset)
		game.quit_game(1 if failed else 0)
		return
	game.hud.show_panel("graphics")
	var panel
	for child in game.hud.column.get_children():
		if child.has_method("_preset_selected"): panel=child
	require(panel!=null,"Real graphics panel exists")
	if panel==null: game.quit_game(1,false);return
	panel._preset_selected(preset)
	expected=game.graphics.applied.duplicate(true)
	require(expected["preset"]==preset,"UI selection immediately applies preset")
	require(_disk()==expected,"UI selection immediately persists every field")
	game.hud.show_panel("settings")
	game.hud.show_panel("graphics")
	require(game.graphics.applied==expected,"Reopening settings preserves the selection")
	started=Time.get_ticks_usec()
	while Time.get_ticks_usec()-started < int(seconds*1000000):
		await process_frame
		require(game.graphics.applied==expected,"Preset did not change automatically during the real elapsed wait")
		if failed: break
	require(_disk()==expected,"Disk state remains unchanged after the wait")
	game.new_game(7100+preset)
	await process_frame
	require(game.graphics.applied==expected,"Creating a procedural world preserves preset")
	require(await game.return_to_menu(),"Return to menu succeeds and saves")
	require(game.graphics.applied==expected,"Returning to menu preserves preset")
	game.hud.show_panel("graphics")
	require(game.graphics.pending==expected,"Reopening panel after gameplay preserves all settings")
	print("SETTINGS_LIFECYCLE_PASS preset=%d elapsed=%.3f failed=%s" % [preset,float(Time.get_ticks_usec()-started)/1000000,failed])
	game.quit_game(1 if failed else 0)
func _disk() -> Dictionary:
	var config:=ConfigFile.new()
	if config.load("user://settings.cfg")!=OK: return {}
	return config.get_value("graphics","settings",{})
