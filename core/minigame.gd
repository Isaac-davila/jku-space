class_name Minigame
extends Node2D
## Basisklasse für ALLE Minispiele – das ist die Team-Schnittstelle.
##
## So baust du ein Minispiel:
##   1. Neue Szene mit Node2D als Wurzel, Skript "extends Minigame".
##   2. In _init(): title, instructions, time_limit setzen.
##   3. NICHT _ready() oder _process() überschreiben. Stattdessen:
##        start()        – einmalig beim Start
##        tick(delta)    – jeden Frame (nur solange das Spiel läuft)
##        on_timeout()   – wenn die Zeit abläuft (Standard: verloren)
##        _draw()        – zeichnen (wird jeden Frame neu ausgelöst)
##   4. Wenn das Spiel vorbei ist: finish(true) oder finish(false).
##   5. Szene mit F6 direkt starten zum Testen – sie startet sich nach dem Ende neu.
##
## Spielfeld ist immer 1280 x 720. Maus-Klicks funktionieren auch per Touch.

signal finished(success: bool)

const VIEW := Vector2(1280, 720)

@export var title: String = "Minispiel"
@export_multiline var instructions: String = ""
@export var time_limit: float = 20.0

var time_left: float = 0.0
var elapsed: float = 0.0
var done: bool = false

var _time_label: Label
var _msg_label: Label
var _stars: Array[Vector3] = []


func _ready() -> void:
	time_left = time_limit
	for i in 120:
		_stars.append(Vector3(randf() * VIEW.x, randf() * VIEW.y, randf_range(0.5, 1.8)))
	_build_hud()
	start()


func _process(delta: float) -> void:
	queue_redraw()
	if done:
		post_tick(delta)
		return
	elapsed += delta
	time_left = maxf(time_left - delta, 0.0)
	tick(delta)
	_time_label.text = "%.1f s" % time_left
	if time_left <= 0.0 and not done:
		on_timeout()


# --- Zum Überschreiben -------------------------------------------------------

func start() -> void:
	pass


func tick(_delta: float) -> void:
	pass


## Läuft weiter, NACHDEM das Minispiel beendet ist (z. B. Hintergrund weiterlaufen lassen).
func post_tick(_delta: float) -> void:
	pass


func on_timeout() -> void:
	finish(false)


# --- Für Unterklassen --------------------------------------------------------

## Beendet das Minispiel. Optional eigener Abschlusstext.
func finish(success: bool, message: String = "") -> void:
	if done:
		return
	done = true
	if message == "":
		message = "GESCHAFFT" if success else "FEHLGESCHLAGEN"
	show_message(message, Pal.OK if success else Pal.ALERT)
	finished.emit(success)
	if _is_standalone():
		await get_tree().create_timer(2.5).timeout
		get_tree().reload_current_scene()


func show_message(text: String, color: Color = Pal.TEXT) -> void:
	_msg_label.text = text
	_msg_label.add_theme_color_override("font_color", color)
	_msg_label.visible = true


func hide_message() -> void:
	_msg_label.visible = false


## 0.0 am Anfang → 1.0 am Ende. Praktisch für steigende Schwierigkeit.
func difficulty() -> float:
	return clampf(elapsed / maxf(time_limit, 0.01), 0.0, 1.0)


func is_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT


func draw_stars() -> void:
	for s in _stars:
		draw_circle(Vector2(s.x, s.y), s.z, Color(1, 1, 1, 0.25 + s.z * 0.2))


## Zeichnet ein unregelmäßiges Trümmerteil.
func draw_debris(pos: Vector2, r: float, rot: float, color: Color = Pal.DEBRIS, seed_val: float = 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 7:
		var a := rot + TAU * i / 7.0
		var rr := r * (0.65 + 0.35 * absf(sin(i * 2.37 + seed_val)))
		pts.append(pos + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, color)


func draw_text(pos: Vector2, text: String, size: int = 22, color: Color = Pal.TEXT) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


# --- Intern ------------------------------------------------------------------

func _is_standalone() -> bool:
	return is_inside_tree() and get_tree().current_scene == self


func _build_hud() -> void:
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	var bg := ColorRect.new()
	bg.color = Pal.BG
	bg.size = VIEW
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(bg)

	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)

	var t := UI.make_label(title.to_upper(), 28, Pal.ACCENT)
	t.position = Vector2(32, 18)
	hud.add_child(t)

	_time_label = UI.make_label("", 28, Pal.WARN)
	_time_label.position = Vector2(VIEW.x - 232, 18)
	_time_label.size = Vector2(200, 40)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(_time_label)

	var ins := UI.make_centered(instructions, 22, Pal.DIM, Rect2(32, VIEW.y - 64, VIEW.x - 64, 48))
	hud.add_child(ins)

	_msg_label = UI.make_centered("", 56, Pal.TEXT, Rect2(Vector2.ZERO, VIEW))
	_msg_label.visible = false
	hud.add_child(_msg_label)

	for c in hud.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
