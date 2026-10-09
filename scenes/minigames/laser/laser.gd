extends Minigame
## ABWEHRLASER – der Twist: Schießen fühlt sich gut an … bis jeder Treffer
## neue Fragmente erzeugt und der Bildschirm sich füllt (Kessler-Syndrom).
## Lernziel: Abschießen ist KEINE Lösung. Das Spiel endet deshalb immer "erfolgreich",
## sobald die Lektion gezeigt wurde. Owner: Rolle 4

const STATION := Vector2(140, 360)
const LESSON_AT := 40          # ab so vielen Teilen kommt der Funkspruch
const LESSON_TIME := 4.5

var pieces: Array[Dictionary] = []
var created := 0
var shots := 0
var beam_t := 0.0
var beam_to := Vector2.ZERO
var lesson := false
var lesson_t := 0.0
var _ui_count: Label


func _init() -> void:
	title = "Abwehrlaser"
	instructions = "Tippe auf Trümmer, um sie zu zerstören!"
	time_limit = 25.0


func start() -> void:
	for i in 5:
		_spawn(Vector2(randf_range(600, 1150), randf_range(140, 600)), randf_range(30, 44),
			Vector2(randf_range(-60, -20), randf_range(-30, 30)))


func _spawn(pos: Vector2, r: float, v: Vector2) -> void:
	pieces.append({"pos": pos, "r": r, "vel": v, "rot": randf() * TAU,
		"spin": randf_range(-3, 3), "seed": randf() * 10.0})
	created += 1


func tick(delta: float) -> void:
	beam_t = maxf(beam_t - delta, 0.0)
	for p in pieces:
		p.pos += p.vel * delta
		p.rot += p.spin * delta
		if p.pos.x < 260 or p.pos.x > VIEW.x - 20:
			p.vel.x = -p.vel.x
		if p.pos.y < 100 or p.pos.y > VIEW.y - 90:
			p.vel.y = -p.vel.y
		p.pos = p.pos.clamp(Vector2(260, 100), Vector2(VIEW.x - 20, VIEW.y - 90))

	if not lesson and pieces.size() >= LESSON_AT:
		_start_lesson()
	if lesson:
		lesson_t += delta
		if lesson_t >= LESSON_TIME:
			GameState.flags["kessler_seen"] = true
			finish(true, "LEKTION GELERNT")


func on_timeout() -> void:
	# Zeit um → Lektion trotzdem zeigen; tick() beendet danach.
	if not lesson:
		_start_lesson()


func _start_lesson() -> void:
	lesson = true
	show_message("FUNK: „STOPP! Feuer einstellen!\nJeder Treffer erzeugt neue Trümmer!“", Pal.WARN)


func _unhandled_input(event: InputEvent) -> void:
	if done or lesson or not is_click(event):
		return
	shoot_at(get_global_mouse_position())


## Schuss auf Position m. Treffer zerlegt das Teil in 2–3 Fragmente.
func shoot_at(m: Vector2) -> void:
	if lesson:
		return
	shots += 1
	beam_t = 0.12
	beam_to = m
	for i in range(pieces.size() - 1, -1, -1):
		var p: Dictionary = pieces[i]
		if p.pos.distance_to(m) < p.r + 16.0:
			pieces.remove_at(i)
			var n := 3 if p.r > 14.0 else 2
			for k in n:
				var dir := Vector2.from_angle(randf() * TAU)
				_spawn(p.pos + dir * p.r * 0.4, maxf(p.r * 0.55, 6.0), p.vel + dir * randf_range(80, 180))
			return


func _draw() -> void:
	draw_stars()
	if lesson:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(Pal.ALERT, 0.08 + 0.06 * sin(elapsed * 10.0)))
	for p in pieces:
		draw_debris(p.pos, p.r, p.rot, Pal.DEBRIS, p.seed)
	draw_circle(STATION, 46, Pal.PANEL)
	draw_circle(STATION, 30, Pal.HULL)
	draw_rect(Rect2(STATION + Vector2(20, -6), Vector2(50, 12)), Pal.LINE)
	if beam_t > 0.0:
		draw_line(STATION + Vector2(70, 0), beam_to, Pal.ALERT, 5.0)
		draw_circle(beam_to, 18, Color(Pal.WARN, 0.6))
	var col := Pal.DIM if pieces.size() < 15 else (Pal.WARN if pieces.size() < 30 else Pal.ALERT)
	draw_text(Vector2(32, 100), "Trümmerteile im Orbit: %d" % pieces.size(), 26, col)
