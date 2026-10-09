extends Node
## Globaler Spielzustand (Autoload "GameState").
## Hier stehen: Reihenfolge der Aufgaben, Gesamt-Countdown, Hüllen-Integrität,
## Story-Flags und Szenenwechsel. Owner: Rolle 1 (Hub & Story-Ablauf).

signal hull_changed(value: int)

## Gesamtzeit für den Hub-Teil in Sekunden (ca. 3:30 → mit Intro/Ende ~5 Min).
const TOTAL_TIME := 210.0
## Schaden an der Hülle, wenn ein Minispiel fehlschlägt.
const FAIL_DAMAGE := 25

const SCENE_INTRO := "res://scenes/intro/intro.tscn"
const SCENE_HUB := "res://scenes/hub/hub.tscn"
const SCENE_ENDING := "res://scenes/ending/ending.tscn"

## Reihenfolge = Dramaturgie. Einfach umsortieren, um sie zu ändern.
const TASK_ORDER: Array[String] = ["dodge", "leak", "laser", "comms", "capture"]

const TASKS := {
	"dodge": {
		"title": "Ausweichmanöver",
		"room": "BRÜCKE",
		"alarm": "Trümmerwolke voraus! Zur Brücke!",
		"scene": "res://scenes/minigames/dodge/dodge.tscn",
	},
	"leak": {
		"title": "Leck abdichten",
		"room": "HABITAT",
		"alarm": "Druckverlust im Habitat!",
		"scene": "res://scenes/minigames/leak/leak.tscn",
	},
	"laser": {
		"title": "Abwehrlaser",
		"room": "ABWEHR",
		"alarm": "Großes Trümmerteil im Anflug – Laser bereit!",
		"scene": "res://scenes/minigames/laser/laser.tscn",
	},
	"comms": {
		"title": "Funkverbindung",
		"room": "FUNK",
		"alarm": "Funkkontakt zur Erde verloren!",
		"scene": "res://scenes/minigames/comms/comms.tscn",
	},
	"capture": {
		"title": "Trümmer einfangen",
		"room": "ROBOTIK",
		"alarm": "Trümmerschwarm in Reichweite – Netzwerfer bereit!",
		"scene": "res://scenes/minigames/capture/capture.tscn",
	},
}

var hull: int = 100
var time_left: float = TOTAL_TIME
var running: bool = false
## task_id -> bool (geschafft?)
var results: Dictionary = {}
## Freie Story-Flags, z. B. flags["kessler_seen"] = true
var flags: Dictionary = {}


func _ready() -> void:
	_setup_input()


func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		end_run()


func reset() -> void:
	hull = 100
	time_left = TOTAL_TIME
	running = false
	results.clear()
	flags.clear()


func start_run() -> void:
	running = true


func end_run() -> void:
	if not running:
		return
	running = false
	goto(SCENE_ENDING)


func damage(amount: int) -> void:
	hull = max(hull - amount, 0)
	hull_changed.emit(hull)
	if hull <= 0:
		end_run()


func complete(task_id: String, success: bool) -> void:
	results[task_id] = success
	if not success:
		damage(FAIL_DAMAGE)


## Nächste offene Aufgabe oder "" wenn alle erledigt.
func next_task_id() -> String:
	for id in TASK_ORDER:
		if not results.has(id):
			return id
	return ""


func all_done() -> bool:
	return next_task_id() == ""


func goto(path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", path)


# --- Eingabe -----------------------------------------------------------------
# Aktionen per Code statt im Editor, damit project.godot selten Merge-Konflikte hat.

func _setup_input() -> void:
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("interact", [KEY_SPACE, KEY_E, KEY_ENTER])


func _add_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
