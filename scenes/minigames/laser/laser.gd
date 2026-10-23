extends Minigame
## ABWEHRLASER – der Twist: Schießen fühlt sich gut an … bis jeder Treffer
## neue Fragmente erzeugt und der Bildschirm sich füllt (Kessler-Syndrom).
## Zerfall: großes Teil → 3 Bauteile → je 3 blaue Splitter (siehe core/debris.gd).
## Lernziel: Abschießen ist KEINE Lösung. Das Spiel endet deshalb immer "erfolgreich",
## sobald die Lektion gezeigt wurde. Owner: Rolle 4

const STATION := Vector2(140, 360)
const START_PIECES := 6
const LESSON_AT := 40          # ab so vielen Teilen kommt der Funkspruch
const LESSON_TIME := 4.5

var pieces: Array[Dictionary] = []
var shots := 0
var beam_t := 0.0
var beam_to := Vector2.ZERO
var lesson := false
var lesson_t := 0.0


func _init() -> void:
	title = "Abwehrlaser"
	instructions = UI.ctrl("Tippe auf Trümmer, um sie zu zerstören!", "Klicke auf Trümmer, um sie zu zerstören!")
	time_limit = 25.0


func start() -> void:
	for i in START_PIECES:
		var pos := Vector2(randf_range(450, 1180), randf_range(150, 590))
		var vel := Vector2(randf_range(-60, -20), randf_range(-30, 30))
		pieces.append(Debris.random_big(pos, vel))


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

	if not lesson and (pieces.size() >= LESSON_AT or first_target() == Vector2.INF):
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


## Schuss auf Position m. Trifft das nächstgelegene teilbare Teil.
## Blaue Splitter sind zu klein – der Laser geht durch.
func shoot_at(m: Vector2) -> void:
	if lesson:
		return
	shots += 1
	beam_t = 0.12
	beam_to = m
	var best := -1
	var best_d := INF
	for i in pieces.size():
		var p: Dictionary = pieces[i]
		if not Debris.can_split(p):
			continue
		var d: float = p.pos.distance_to(m)
		if d < p.r + 16.0 and d < best_d:
			best = i
			best_d = d
	if best >= 0:
		var hit: Dictionary = pieces[best]
		pieces.remove_at(best)
		pieces.append_array(Debris.split(hit))


## Position des ersten noch teilbaren Teils (oder Vector2.INF). Für Tests/Hinweise.
func first_target() -> Vector2:
	for p in pieces:
		if Debris.can_split(p):
			return p.pos
	return Vector2.INF


func _draw() -> void:
	draw_stars()
	if lesson:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(Pal.ALERT, 0.08 + 0.06 * sin(elapsed * 10.0)))
	for p in pieces:
		Debris.draw(self, p)
	draw_circle(STATION, 46, Pal.PANEL)
	draw_circle(STATION, 30, Pal.HULL)
	draw_rect(Rect2(STATION + Vector2(20, -6), Vector2(50, 12)), Pal.LINE)
	if beam_t > 0.0:
		draw_line(STATION + Vector2(70, 0), beam_to, Pal.ALERT, 5.0)
		draw_circle(beam_to, 18, Color(Pal.WARN, 0.6))
	var col := Pal.DIM if pieces.size() < 15 else (Pal.WARN if pieces.size() < 30 else Pal.ALERT)
	draw_text(Vector2(32, 100), "Trümmerteile im Orbit: %d" % pieces.size(), 26, col)
