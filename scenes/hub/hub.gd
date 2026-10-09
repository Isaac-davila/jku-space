extends Node
## Hub: die Raumstation. Spieler läuft (WASD/Pfeile oder Tippen) in den
## blinkenden Raum → das Minispiel startet automatisch.
## Owner: Rolle 1. Minispiele werden NUR über GameState.TASKS eingebunden.

const VIEW := Vector2(1280, 720)
const PLAYER_SPEED := 380.0
const PLAYER_R := 16.0

## Raum-Rechtecke pro Aufgabe. Mitte unten = Quartier (Startpunkt).
const ROOMS := {
	"dodge": Rect2(70, 110, 340, 220),
	"comms": Rect2(470, 110, 340, 220),
	"leak": Rect2(870, 110, 340, 220),
	"laser": Rect2(70, 420, 340, 220),
	"capture": Rect2(870, 420, 340, 220),
}
const QUARTERS := Rect2(470, 420, 340, 220)

var world: Node2D
var game_layer: Node
var player_pos := QUARTERS.get_center()
var move_target := Vector2.INF
var in_minigame := false
var _enter_t := 0.0

var _hull_label: Label
var _time_label: Label
var _alarm_label: Label


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	world.draw.connect(_draw_world)
	game_layer = Node.new()
	game_layer.name = "GameLayer"
	add_child(game_layer)
	_build_hud()
	GameState.start_run()


func _process(delta: float) -> void:
	_update_hud()
	if in_minigame:
		return
	_move_player(delta)
	var active := GameState.next_task_id()
	if active == "":
		GameState.end_run()
		return
	if ROOMS[active].has_point(player_pos):
		_enter_t += delta
		if _enter_t > 0.35:
			_open_minigame(active)
	else:
		_enter_t = 0.0
	world.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if in_minigame:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		move_target = world.get_global_mouse_position()


func _move_player(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		move_target = Vector2.INF
	elif move_target != Vector2.INF:
		var to := move_target - player_pos
		if to.length() < 6.0:
			move_target = Vector2.INF
		else:
			dir = to.normalized()
	player_pos += dir * PLAYER_SPEED * delta
	player_pos = player_pos.clamp(Vector2(60, 100), VIEW - Vector2(60, 70))


func _open_minigame(id: String) -> void:
	var scene: PackedScene = load(GameState.TASKS[id].scene)
	var mg: Minigame = scene.instantiate()
	in_minigame = true
	_enter_t = 0.0
	world.hide()
	_alarm_label.hide()
	game_layer.add_child(mg)
	mg.finished.connect(_on_minigame_finished.bind(id, mg), CONNECT_ONE_SHOT)


func _on_minigame_finished(success: bool, id: String, mg: Minigame) -> void:
	GameState.complete(id, success)
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	mg.queue_free()
	player_pos = ROOMS[id].get_center()
	move_target = Vector2.INF
	in_minigame = false
	world.show()
	_alarm_label.show()


# --- Zeichnen ----------------------------------------------------------------

func _draw_world() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	world.draw_rect(Rect2(Vector2.ZERO, VIEW), Pal.BG)
	# Gänge
	world.draw_rect(Rect2(40, 80, VIEW.x - 80, VIEW.y - 130), Color("0e1526"))
	var active := GameState.next_task_id()
	var font := ThemeDB.fallback_font
	for id in ROOMS:
		var r: Rect2 = ROOMS[id]
		var col := Pal.PANEL
		var border := Pal.LINE
		if GameState.results.has(id):
			border = Pal.OK if GameState.results[id] else Pal.ALERT
		elif id == active:
			var pulse := 0.5 + 0.5 * sin(t * 6.0)
			col = Pal.PANEL.lerp(Color("5a0f18"), pulse)
			border = Pal.ALERT
		world.draw_rect(r, col)
		world.draw_rect(r, border, false, 3.0)
		var room_name: String = GameState.TASKS[id].room
		world.draw_string(font, r.position + Vector2(16, 34), room_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.DIM)
		if GameState.results.has(id):
			var status := "OK" if GameState.results[id] else "BESCHÄDIGT"
			world.draw_string(font, r.position + Vector2(16, r.size.y - 18), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, border)
	world.draw_rect(QUARTERS, Pal.PANEL)
	world.draw_rect(QUARTERS, Pal.LINE, false, 2.0)
	world.draw_string(font, QUARTERS.position + Vector2(16, 34), "QUARTIER", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.DIM)

	# Pfeil zum aktiven Raum
	if active != "":
		var target: Vector2 = ROOMS[active].get_center()
		var d := (target - player_pos)
		if d.length() > 80:
			var tip := player_pos + d.normalized() * 44
			world.draw_line(player_pos + d.normalized() * 24, tip, Pal.ALERT, 4.0)
			world.draw_circle(tip, 6, Pal.ALERT)

	# Spieler
	world.draw_circle(player_pos, PLAYER_R + 4, Color(Pal.ACCENT, 0.25))
	world.draw_circle(player_pos, PLAYER_R, Pal.ACCENT)
	world.draw_circle(player_pos + Vector2(5, -4), 6, Pal.BG)


# --- HUD ---------------------------------------------------------------------

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	_hull_label = UI.make_label("", 22, Pal.TEXT)
	_hull_label.position = Vector2(40, VIEW.y - 42)
	hud.add_child(_hull_label)
	_time_label = UI.make_label("", 22, Pal.WARN)
	_time_label.position = Vector2(VIEW.x - 320, VIEW.y - 42)
	_time_label.size = Vector2(280, 30)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(_time_label)
	_alarm_label = UI.make_centered("", 26, Pal.ALERT, Rect2(0, 24, VIEW.x, 44))
	hud.add_child(_alarm_label)
	for c in hud.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _update_hud() -> void:
	_hull_label.text = "HÜLLE %d %%" % GameState.hull
	_hull_label.add_theme_color_override("font_color", Pal.OK if GameState.hull > 50 else Pal.ALERT)
	var s := int(ceil(GameState.time_left))
	_time_label.text = "AUFPRALL IN %d:%02d" % [s / 60, s % 60]
	var active := GameState.next_task_id()
	if active != "":
		_alarm_label.text = "ALARM: " + GameState.TASKS[active].alarm
		_alarm_label.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 150.0)
