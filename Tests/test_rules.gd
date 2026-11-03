extends SceneTree

const Inventory = preload("res://Core/Inventory.gd")
const Vitals = preload("res://Core/Vitals.gd")
const Clock = preload("res://World/Clock.gd")
const Weather = preload("res://Weather/Weather.gd")
const Exposure = preload("res://Weather/Exposure.gd")
const Store = preload("res://Persistence/Store.gd")
var failed: int = 0
var checks: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error(message)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lock-hold="):
			var lock_error := Store.acquire_lock(arg.trim_prefix("--lock-hold="))
			if not lock_error.is_empty():
				printerr(lock_error)
				quit(1)
			else:
				print("LOCK_READY")
			return
		if arg.begins_with("--lock-probe="):
			var error := Store.acquire_lock(arg.trim_prefix("--lock-probe="))
			if error.is_empty():
				Store.release_lock(arg.trim_prefix("--lock-probe="))
			quit(1 if error.is_empty() else 0)
			return
		if arg.begins_with("--lock-acquire-release="):
			var folder := arg.trim_prefix("--lock-acquire-release=")
			var error := Store.acquire_lock(folder)
			Store.release_lock(folder)
			quit(0 if error.is_empty() else 1)
			return
	var inv = Inventory.new()
	check(not inv.craft_fire(), "Não fabricar sem recursos")
	inv.add("wood", 8)
	check(inv.craft_fire(), "Fabricar com oito madeiras")
	check(inv.count("wood") == 0 and inv.count("campfire") == 1, "Custo exato")
	check(not inv.consume("campfire", 2), "Não permitir saldo negativo")
	check(inv.count("campfire") == 1, "Falha de consumo é atômica")
	inv.add("wood", 12)
	check(inv.craft_shelter() and inv.count("wood") == 0, "Abrigo custa doze madeiras")
	inv.items["campfire"] = 9999
	inv.add("wood", 8)
	check(not inv.craft_fire() and inv.count("wood") == 8, "Fabricação com estoque cheio é atômica")
	check(not inv.add("unknown", 1) and not inv.add("wood", -1), "Rejeitar itens e quantidades inválidos")
	var life = Vitals.new()
	life.hp = 50
	life.advance(2.99)
	check(life.hp == 50, "Não regenerar antes de três segundos")
	life.advance(0.01)
	check(life.hp == 51, "Regenerar um HP em três segundos")
	life.hp = 50
	life.quiet_seconds = 0
	life.advance(30)
	check(life.hp == 60, "Regenerar dez HP em trinta segundos")
	life.advance(1000)
	check(life.hp == 100, "Não ultrapassar cem HP")
	life.hp = 50
	life.quiet_seconds = 0
	life.advance(2)
	life.damage(1)
	life.advance(2)
	check(life.hp == 49, "Dano reinicia o intervalo")
	life.advance(1)
	check(life.hp == 49, "Cooldown de segurança V2 impede regeneração antes dos seis segundos")
	life.advance(6)
	check(life.hp == 50, "Após cooldown de seis segundos, regenerar um HP em três segundos")
	life.damage(100)
	life.advance(30)
	check(life.hp == 0, "Não regenerar após morte")
	test_rain()
	var clock = Clock.new()
	clock.elapsed = 0
	check(is_equal_approx(clock.hour(), 6), "Amanhecer")
	clock.advance(1800)
	check(is_equal_approx(clock.hour(), 18), "Dia de trinta minutos")
	clock.advance(900)
	check(is_equal_approx(clock.hour(), 6), "Noite de quinze minutos")
	test_weather()
	test_persistence()
	print("RULES CHECKS=%d FAILED=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)

func test_rain() -> void:
	var rain = Exposure.new()
	var life = Vitals.new()
	for segment in [20.0, 19.0, 1.0, 14.99]:
		rain.advance(segment, true, false, life)
		check(rain.damage_count == 0, "Nenhum dano climático antes de 55s: %.2f" % rain.exposure_seconds)
	rain.advance(0.01, true, false, life)
	check(rain.damage_count == 1 and life.hp == 99, "Primeiro dano aos 55s")
	rain.advance(15, true, false, life)
	check(rain.damage_count == 2, "Segundo dano aos 70s")
	rain.advance(15, true, false, life)
	check(rain.damage_count == 3, "Terceiro dano aos 85s")
	rain.advance(15, true, false, life)
	check(rain.damage_count == 4, "Quarto dano aos 100s")
	rain.advance(200, true, false, life)
	check(rain.damage_count == 17, "Cinco minutos causam exatamente 17 HP brutos")
	for fps in [15, 30, 60, 144]:
		var fractional = Exposure.new()
		var health = Vitals.new()
		for frame in range(fps * 300):
			fractional.advance(1.0 / fps, true, false, health)
		check(fractional.damage_count == 17 and health.hp == life.hp,
			"Dano e regeneração independentes de FPS: %d" % fps)
	var injured = Vitals.new()
	injured.hp = 1
	var chronology = Exposure.new()
	chronology.advance(100, true, false, injured)
	check(injured.hp == 10, "V2: regenerar só até40s e bloquear durante exposição danosa")
	var stepped_life = Vitals.new()
	stepped_life.hp = 1
	var stepped = Exposure.new()
	for frame in range(6000):
		stepped.advance(1.0 / 60.0, true, false, stepped_life)
	check(stepped_life.hp == injured.hp and stepped.damage_count == chronology.damage_count,
		"Regeneração sem saturação também independe do tamanho do tick")
	var reset = Exposure.new()
	reset.advance(54, true, false, life)
	reset.advance(1, true, true, life)
	check(reset.exposure_seconds == 0 and reset.damage_count == 0, "Abrigo interrompe e reinicia exposição")
	reset.advance(54, true, false, life)
	check(reset.damage_count == 0, "Sair do abrigo oferece nova proteção completa")
	reset.advance(1, true, false, life)
	check(reset.damage_count == 1, "Dano somente aos novos 55s")
	reset.advance(1, false, false, life)
	check(reset.exposure_seconds == 0, "Fim da chuva reinicia contador")
	reset.advance(55, true, false, life, true)
	check(reset.damage_count == 1 and reset.comfort and is_equal_approx(reset.exposure_seconds,55),
		"Reconstrução: calor interrompe perda sem reiniciar exposição ou secar como telhado")
	var restored = Exposure.new()
	restored.restore(reset.state())
	restored.advance(14.99, true, false, life)
	check(restored.damage_count == 1, "Sair do calor e restaurar não antecipa próximo dano")
	restored.advance(0.01, true, false, life)
	check(restored.damage_count == 2, "Sem calor, restauração preserva intervalo de dano")

func test_weather() -> void:
	var weather = Weather.new()
	check(not weather.set_weather("invalid"), "Rejeitar clima desconhecido")
	check(weather.set_weather("storm"), "Admin pode selecionar tempestade")
	weather.advance(1)
	check(float(weather.state()["rain"]) > 0 and float(weather.state()["rain"]) < 1,
		"Clima muda gradualmente")
	var restored = Weather.new()
	check(Weather.valid(weather.serialize()), "Estado climático serializável")
	restored.restore(weather.serialize())
	weather.advance(900)
	restored.advance(900)
	check(weather.serialize() == restored.serialize(), "Clima determinístico após restauração")
	var split = Weather.new()
	var bulk = Weather.new()
	bulk.advance(900)
	for frame in range(900):
		split.advance(1)
	check(split.condition == bulk.condition and is_equal_approx(split.state()["rain"], bulk.state()["rain"]),
		"Clima não depende do tamanho do tick")

func test_persistence() -> void:
	var data := {"version": 2, "seed": 1337,
		"players": {"1": {"position": [0, 2, 0], "hp": 75,
			"inventory": {"axe": 1, "wood": 12, "campfire": 1, "shelter": 1}}},
		"cut": [2, 9], "fires": [[2, 1, -3]], "shelters": [[4, 1, 4]],
		"phase": 123.0, "weather": Weather.new().serialize()}
	var folder := "user://tests/%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	check(Store.valid(data), "Schema v2 válido")
	check(Store.save_world(data, folder) == "", "Gravar primeiro snapshot")
	var loaded := Store.load_world(folder)
	check(not loaded.is_empty() and loaded.get("cut") == [2, 9], "Restaurar árvores")
	check(loaded["players"]["1"]["inventory"]["wood"] == 12, "Restaurar inventário individual")
	check(loaded["shelters"].size() == 1 and Vector3(loaded["shelters"][0][0],
		loaded["shelters"][0][1], loaded["shelters"][0][2]).is_equal_approx(Vector3(4, 1, 4)), "Restaurar abrigo")
	var lock_output: Array = []
	var result := OS.execute(OS.get_executable_path(), PackedStringArray([
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://Tests/test_rules.gd", "--", "--lock-probe=" + folder]), lock_output, true)
	check(result == 0, "Segundo processo não pode adquirir pasta de gravação")
	data["players"]["1"]["inventory"]["wood"] = 20
	check(Store.save_world(data, folder) == "", "Gravar segundo snapshot")
	var file := FileAccess.open(folder.path_join("world.b.json"), FileAccess.WRITE)
	if file != null:
		file.store_string("corrompido")
		file.close()
		loaded = Store.load_world(folder)
		check(loaded["players"]["1"]["inventory"]["wood"] == 12, "Recuperar snapshot anterior após corrupção")
	else:
		check(false, "Abrir arquivo para teste de corrupção")
	data["players"]["1"]["inventory"]["wood"] = -1
	check(not Store.valid(data), "Rejeitar contagem negativa")
	check(Store.save_world(data, folder) != "", "Rejeitar gravação inválida")
	data["players"]["1"]["inventory"]["wood"] = 20
	data["players"]["1"]["position"] = [NAN, 0, 0]
	check(not Store.valid(data), "Rejeitar posição não finita")
	data["players"]["1"]["position"] = [0, 2, 0]
	data["cut"] = [2, 2]
	check(not Store.valid(data), "Rejeitar IDs duplicados")
	Store.release_lock(folder)
	check(Store.acquire_lock(folder) == "", "Liberação permite novo escritor")
	Store.release_lock(folder)
	var legacy := {"version": 1, "seed": 1337, "position": [0, 2, 0],
		"inventory": {"axe": 1, "wood": 4, "campfire": 0},
		"cut": [1], "fires": [], "phase": 450, "hp": 90}
	check(Store.valid(legacy) and Store.valid(Store.migrate(legacy)), "Migração da base v1 preserva mundo")
