extends Minigame
## LECK ABDICHTEN – Einschlaglöcher antippen, bevor der Druck weg ist.
## Echter Hintergrund: Schon winzige Trümmer können Hüllen durchschlagen.
## Owner: Rolle 3

const PANEL_RECT := Rect2(140, 110, 900, 480)
const HOLE_R := 26.0
const LEAK_RATE := 5.0

var holes: Array[Dictionary] = []
var pressure := 100.0
var spawn_t := 0.6
var patches: Array[Vector2] = []
var flashes: Array[Dictionary] = []


func _init() -> void:
	title = "Leck abdichten"
	instructions = "Tippe auf jedes Loch, um es zu flicken!"
	time_limit = 18.0


func tick(delta: float) -> void:
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = lerpf(1.0, 0.4, difficulty())
		var p := Vector2(
			randf_range(PANEL_RECT.position.x + 40, PANEL_RECT.end.x - 40),
			randf_range(PANEL_RECT.position.y + 40, PANEL_RECT.end.y - 40))
		holes.append({"pos": p, "age": 0.0})
	for h in holes:
		h.age += delta
	pressure -= holes.size() * LEAK_RATE * delta
	for f in flashes:
		f.t -= delta
	flashes = flashes.filter(func(f): return f.t > 0.0)
	if pressure <= 0.0:
		pressure = 0.0
		finish(false, "DRUCK VERLOREN")


func on_timeout() -> void:
	finish(true, "HÜLLE DICHT!")


func _unhandled_input(event: InputEvent) -> void:
	if done or not is_click(event):
		return
	patch_at(get_global_mouse_position())


## Flickt das Loch an Position p (falls dort eins ist).
func patch_at(p: Vector2) -> void:
	for i in range(holes.size() - 1, -1, -1):
		if holes[i].pos.distance_to(p) < HOLE_R + 14.0:
			patches.append(holes[i].pos)
			flashes.append({"pos": holes[i].pos, "t": 0.25})
			holes.remove_at(i)
			return


func _draw() -> void:
	draw_rect(PANEL_RECT, Pal.HULL.darkened(0.55))
	for x in range(int(PANEL_RECT.position.x) + 30, int(PANEL_RECT.end.x), 60):
		for y in range(int(PANEL_RECT.position.y) + 30, int(PANEL_RECT.end.y), 60):
			draw_circle(Vector2(x, y), 3, Pal.HULL.darkened(0.3))
	draw_rect(PANEL_RECT, Pal.HULL, false, 4.0)
	for p in patches:
		draw_rect(Rect2(p - Vector2(22, 22), Vector2(44, 44)), Pal.WARN.darkened(0.3))
	var t := elapsed
	for h in holes:
		draw_circle(h.pos, HOLE_R, Color.BLACK)
		draw_arc(h.pos, HOLE_R, 0, TAU, 20, Pal.ALERT, 3.0)
		for k in 3:
			var a: float = t * 3.0 + k * 2.1 + h.age
			var dir := Vector2(cos(a), sin(a))
			draw_line(h.pos + dir * HOLE_R, h.pos + dir * (HOLE_R + 18 + 8 * sin(t * 20 + k)), Color(Pal.TEXT, 0.6), 2.0)
	for f in flashes:
		draw_circle(f.pos, 40.0 * (1.0 - f.t / 0.25) + 10.0, Color(Pal.OK, f.t * 3.0))
	# Druckanzeige
	var bar := Rect2(1100, 110, 50, 480)
	draw_rect(bar, Pal.PANEL)
	var h_px := bar.size.y * pressure / 100.0
	var col := Pal.OK if pressure > 50 else (Pal.WARN if pressure > 25 else Pal.ALERT)
	draw_rect(Rect2(bar.position.x, bar.end.y - h_px, bar.size.x, h_px), col)
	draw_rect(bar, Pal.LINE, false, 2.0)
	draw_text(Vector2(1078, 100), "DRUCK", 20, Pal.DIM)
	draw_text(Vector2(1090, 620), "%d %%" % int(pressure), 22, col)
