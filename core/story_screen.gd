class_name StoryScreen
extends Control
## Basis für Intro und Ende: zeigt Text-Seiten nacheinander mit Schreibmaschinen-Effekt.
## Klick / Leertaste: Text sofort fertig zeigen bzw. zur nächsten Seite.
##
## Eine Seite ist ein Dictionary:
##   text   – der Text (Pflicht)
##   size   – Schriftgröße (Standard 34)
##   color  – Textfarbe
##   bg     – Hintergrundfarbe
##   auto   – Sekunden bis automatisch weiter (0 = warten auf Klick)
##   sub    – kleiner Zusatztext unten (z. B. Quelle)

const VIEW := Vector2(1280, 720)
const CHARS_PER_SEC := 45.0

var pages: Array = []
var index := -1

var _bg: ColorRect
var _label: Label
var _sub: Label
var _hint: Label
var _typing := false
var _auto_t := 0.0


## Unterklassen geben hier ihre Seiten zurück.
func build_pages() -> Array:
	return []


## Wird nach der letzten Seite aufgerufen.
func on_end() -> void:
	pass


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg = ColorRect.new()
	_bg.color = Pal.BG
	_bg.size = VIEW
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_label = UI.make_centered("", 34, Pal.TEXT, Rect2(120, 80, VIEW.x - 240, VIEW.y - 220))
	add_child(_label)
	_sub = UI.make_centered("", 18, Pal.DIM, Rect2(120, VIEW.y - 150, VIEW.x - 240, 60))
	add_child(_sub)
	_hint = UI.make_centered(UI.ctrl("Tippen zum Fortfahren", "Klicken oder Leertaste"), 20, Pal.DIM, Rect2(0, VIEW.y - 60, VIEW.x, 30))
	add_child(_hint)
	for c in [_label, _sub, _hint]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pages = build_pages()
	next_page()


func _process(delta: float) -> void:
	if _typing:
		var total := _label.get_total_character_count()
		var shown := _label.visible_characters + maxi(1, int(CHARS_PER_SEC * delta))
		_label.visible_characters = shown
		if total <= 0 or shown >= total:
			_finish_typing()
	elif index >= 0 and index < pages.size():
		var auto: float = pages[index].get("auto", 0.0)
		if auto > 0.0:
			_auto_t += delta
			if _auto_t >= auto:
				next_page()
	_hint.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 300.0)


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed("interact") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if _typing:
		_finish_typing()
	else:
		next_page()


func next_page() -> void:
	index += 1
	if index >= pages.size():
		set_process_unhandled_input(false)
		on_end()
		return
	var p: Dictionary = pages[index]
	_label.text = p.get("text", "")
	_label.add_theme_font_size_override("font_size", p.get("size", 34))
	_label.add_theme_color_override("font_color", p.get("color", Pal.TEXT))
	_bg.color = p.get("bg", Pal.BG)
	_sub.text = p.get("sub", "")
	_label.visible_characters = 0
	_typing = true
	_auto_t = 0.0


func _finish_typing() -> void:
	_label.visible_characters = -1
	_typing = false
