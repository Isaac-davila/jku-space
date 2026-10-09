extends Minigame
## AUSWEICHMANÖVER – Station per Schub hoch/runter steuern, Trümmern ausweichen.
## Echter Hintergrund: Die ISS führt regelmäßig Ausweichmanöver durch.
## Owner: Rolle 2

const SHIP_X := 220.0
const SHIP_R := 30.0
const MAX_HITS := 3

var ship_y := 360.0
var vel := 0.0
var debris: Array[Dictionary] = []
var spawn_t := 0.0
var hits := 0
var invuln := 0.0


func _init() -> void:
	title = "Ausweichmanöver"
	instructions = "W/S oder Pfeiltasten – oder Finger gedrückt halten, wohin die Station soll"
	time_limit = 20.0


func tick(delta: float) -> void:
	var input := Input.get_axis("move_up", "move_down")
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		input = clampf((get_global_mouse_position().y - ship_y) / 80.0, -1.0, 1.0)
	vel += input * 1700.0 * delta
	vel -= vel * 2.2 * delta
	ship_y += vel * delta
	if ship_y < 110.0 or ship_y > 620.0:
		ship_y = clampf(ship_y, 110.0, 620.0)
		vel = 0.0

	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = lerpf(0.5, 0.16, difficulty())
		debris.append({
			"pos": Vector2(VIEW.x + 40, randf_range(100, 630)),
			"r": randf_range(8, 24),
			"speed": randf_range(380, 600) * (1.0 + difficulty() * 0.6),
			"rot": randf() * TAU,
			"spin": randf_range(-4, 4),
			"seed": randf() * 10.0,
		})

	invuln = maxf(invuln - delta, 0.0)
	var ship := Vector2(SHIP_X, ship_y)
	for d in debris:
		d.pos.x -= d.speed * delta
		d.rot += d.spin * delta
		if invuln <= 0.0 and d.pos.distance_to(ship) < SHIP_R + d.r * 0.8:
			hits += 1
			invuln = 1.0
			d.pos.x = -100.0
			if hits >= MAX_HITS:
				finish(false, "STATION GETROFFEN")
				return
	debris = debris.filter(func(d): return d.pos.x > -60.0)


func on_timeout() -> void:
	finish(true, "AUSGEWICHEN!")


func _draw() -> void:
	draw_stars()
	# Bahnlinien
	for y in range(140, 640, 100):
		draw_line(Vector2(0, y), Vector2(VIEW.x, y), Color(Pal.LINE, 0.35), 1.0)
	for d in debris:
		draw_debris(d.pos, d.r, d.rot, Pal.DEBRIS, d.seed)
		draw_line(d.pos + Vector2(d.r, 0), d.pos + Vector2(d.r + 40, 0), Color(Pal.DEBRIS, 0.25), 2.0)
	var blink := invuln > 0.0 and int(invuln * 12.0) % 2 == 0
	if not blink:
		_draw_station(Vector2(SHIP_X, ship_y))
	draw_text(Vector2(32, 100), "Treffer: %d / %d" % [hits, MAX_HITS], 24, Pal.ALERT if hits > 0 else Pal.DIM)


func _draw_station(p: Vector2) -> void:
	draw_rect(Rect2(p - Vector2(70, 6), Vector2(140, 12)), Color("3a5a9c"))
	draw_rect(Rect2(p - Vector2(70, 22), Vector2(30, 44)), Color("2b4a8c"))
	draw_rect(Rect2(p + Vector2(40, -22), Vector2(30, 44)), Color("2b4a8c"))
	draw_rect(Rect2(p - Vector2(22, 14), Vector2(44, 28)), Pal.HULL)
	draw_circle(p + Vector2(12, 0), 5, Pal.ACCENT)
