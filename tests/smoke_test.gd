extends SceneTree
## Smoke-Test: lädt jede Szene, lässt sie laufen und prüft die Minispiel-Schnittstelle.
## Aufruf (vorher einmal: godot --headless --import):
##   godot --headless --script res://tests/smoke_test.gd

const MINIGAMES := [
	"res://scenes/minigames/dodge/dodge.tscn",
	"res://scenes/minigames/leak/leak.tscn",
	"res://scenes/minigames/laser/laser.tscn",
	"res://scenes/minigames/comms/comms.tscn",
	"res://scenes/minigames/capture/capture.tscn",
]
const SCREENS := [
	"res://scenes/intro/intro.tscn",
	"res://scenes/hub/hub.tscn",
	"res://scenes/ending/ending.tscn",
]

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var gs = root.get_node_or_null("GameState")
	_check(gs != null, "Autoload GameState fehlt")

	# Jede Aufgabe in GameState muss auf eine existierende Szene zeigen
	for id in gs.TASK_ORDER:
		_check(gs.TASKS.has(id), "TASKS hat keinen Eintrag für " + id)
		_check(ResourceLoader.exists(gs.TASKS[id].scene), "Szene fehlt: " + gs.TASKS[id].scene)

	for path in MINIGAMES:
		await _test_minigame(path)

	for path in SCREENS:
		var s: PackedScene = load(path)
		_check(s != null, "Kann nicht laden: " + path)
		if s == null:
			continue
		var n := s.instantiate()
		root.add_child(n)
		for i in 90:
			await process_frame
		n.queue_free()
		await process_frame
		gs.running = false
		print("OK  ", path)

	await _test_laser_lesson()
	await _test_capture_combo()
	await _test_full_run()

	if failures.is_empty():
		print("\nALLE TESTS BESTANDEN")
		quit(0)
	else:
		print("\nFEHLER:\n- " + "\n- ".join(failures))
		quit(1)


func _test_minigame(path: String) -> void:
	var s: PackedScene = load(path)
	_check(s != null, "Kann nicht laden: " + path)
	if s == null:
		return
	var mg = s.instantiate()
	_check(mg is Minigame, path + " erbt nicht von Minigame")
	root.add_child(mg)
	var got := [false]
	mg.finished.connect(func(_ok): got[0] = true)
	for i in 120:
		await process_frame
	if not mg.done:
		mg.finish(true)
	_check(got[0], path + " hat finished nicht gesendet")
	mg.queue_free()
	await process_frame
	print("OK  ", path)


## Prüft, dass Schießen wirklich Fragmente erzeugt und die Lektion auslöst.
func _test_laser_lesson() -> void:
	var gs = root.get_node("GameState")
	gs.flags.clear()
	var mg = load("res://scenes/minigames/laser/laser.tscn").instantiate()
	root.add_child(mg)
	await process_frame
	var before: int = mg.pieces.size()
	var guard := 0
	while not mg.lesson and guard < 400:
		guard += 1
		if mg.pieces.is_empty():
			break
		var target: Vector2 = mg.pieces[0].pos
		mg.shoot_at(target)
		await process_frame
	_check(mg.pieces.size() > before, "Laser: Treffer erzeugen keine Fragmente")
	_check(mg.lesson, "Laser: Kessler-Lektion wurde nicht ausgelöst")
	await create_timer(mg.LESSON_TIME + 1.0).timeout
	_check(gs.flags.get("kessler_seen", false), "Laser: Flag kessler_seen nicht gesetzt")
	print("OK  Laser-Lektion (%d Teile nach %d Schüssen)" % [mg.pieces.size(), mg.shots])
	mg.queue_free()


## Prüft das Netz: 3 Teile auf einmal fangen = 90 Punkte.
func _test_capture_combo() -> void:
	var mg = load("res://scenes/minigames/capture/capture.tscn").instantiate()
	root.add_child(mg)
	await process_frame
	mg.pieces.clear()
	for k in 3:
		mg.pieces.append({"pos": Vector2(600 + k * 30, 300), "vel": Vector2.ZERO, "r": 12.0,
			"rot": 0.0, "spin": 0.0, "seed": 0.0})
	mg.throw_at(Vector2(630, 300))
	await create_timer(0.6).timeout
	_check(mg.score == 90, "Netz: 3er-Fang sollte 90 Punkte geben, war %d" % mg.score)
	_check(mg.nets_left == mg.NETS - 1, "Netz: Netzzähler falsch")
	print("OK  Netz-Kombo (%d Punkte)" % mg.score)
	mg.queue_free()
	await process_frame


## Spielt einen kompletten Durchlauf: Hub → alle Minispiele → Ending.
func _test_full_run() -> void:
	var gs = root.get_node("GameState")
	gs.reset()
	change_scene_to_file("res://scenes/hub/hub.tscn")
	await create_timer(0.3).timeout
	var hub = current_scene
	_check(hub != null and hub.name == "Hub", "Hub wurde nicht geladen")
	for id in gs.TASK_ORDER:
		hub.player_pos = hub.ROOMS[id].get_center()
		await create_timer(0.6).timeout
		_check(hub.in_minigame, "Minispiel '%s' startet nicht beim Betreten des Raums" % id)
		var mg = hub.game_layer.get_child(0) if hub.game_layer.get_child_count() > 0 else null
		if mg == null:
			return
		mg.finish(id != "leak")   # einmal absichtlich verlieren → Hüllenschaden
		await create_timer(2.0).timeout
	await create_timer(0.5).timeout
	_check(current_scene != null and current_scene.name == "Ending", "Nach allen Aufgaben kein Ending")
	_check(gs.hull == 100 - gs.FAIL_DAMAGE, "Hüllenschaden falsch: %d" % gs.hull)
	print("OK  Kompletter Durchlauf (Hülle %d %%)" % gs.hull)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)
		push_error(msg)
