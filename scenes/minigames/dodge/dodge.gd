extends Minigame
## AUSWEICHMANÖVER – Station per Schub hoch/runter steuern, Trümmern ausweichen.
## Echter Hintergrund: Die ISS führt regelmäßig Ausweichmanöver durch.
## Owner: Rolle 2

const SHIP_X := 220.0
const SHIP_R := 30.0
const MAX_HITS := 3
const BREAKUP_TIME := 1.8      # so lange sieht man das Auseinanderfallen, bevor "verloren" kommt

# ISS-Farben
const C_TRUSS := Color("8a93a6")
const C_ARRAY := Color("b5893a")       # ISS-Solarflügel wirken goldbraun
const C_ARRAY_LINE := Color("7a5a22")
const C_MODULE := Color("e3e7ee")
const C_MODULE_LINE := Color("a9b0bf")
const C_RADIATOR := Color("f5f7fa")
const C_SCORCH := Color("2a2a2a")

## Die 4 Solarflügel: (Seite x, Seite y). Bei Treffer 1 und 2 fällt je einer ab.
const ARRAYS := [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]
const LOST_AT_HIT := {1: 2, 2: 1}      # Treffer-Nr. → Index des Flügels, der abreißt

var ship_y := 360.0
var vel := 0.0
var debris: Array[Dictionary] = []
var wreck: Array[Dictionary] = []      # abgerissene Stationsteile (keine Kollision)
var spawn_t := 0.0
var hits := 0
var invuln := 0.0
var broken := false
var broken_t := 0.0
var earth := Earth.new()          # Erde im Hintergrund (core/earth.gd)


func _init() -> void:
	title = "Ausweichmanöver"
	instructions = ""   # kein Steuerungstext unten
	time_limit = 20.0


func tick(delta: float) -> void:
	_move_pieces(delta)
	if broken:
		broken_t += delta
		if broken_t >= BREAKUP_TIME:
			finish(false, "STATION ZERBROCHEN")
		return

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
		var pos := Vector2(VIEW.x + 60, randf_range(100, 630))
		var dv := Vector2(-randf_range(380, 600) * (1.0 + difficulty() * 0.6), 0)
		# 40 % große Teile (verkleinert), sonst einzelne Bauteile – siehe core/debris.gd
		if randf() < 0.4:
			debris.append(Debris.random_big(pos, dv, randf_range(0.55, 0.7)))
		else:
			debris.append(Debris.random_small(pos, dv))

	invuln = maxf(invuln - delta, 0.0)
	var ship := Vector2(SHIP_X, ship_y)
	for d in debris:
		if invuln <= 0.0 and d.pos.distance_to(ship) < SHIP_R + d.r * 0.8:
			d.pos.x = -100.0
			take_hit()
			return


## Ein Treffer: Station verliert ein Teil – beim letzten Treffer zerfällt sie.
func take_hit() -> void:
	hits += 1
	invuln = 1.0
	if hits >= MAX_HITS:
		_break_apart()
	elif LOST_AT_HIT.has(hits):
		var a: Vector2 = ARRAYS[LOST_AT_HIT[hits]]
		_throw_off("iss_panel", Vector2(a.x * 70, a.y * 19), 1.0)


func on_timeout() -> void:
	if not broken:
		finish(true, "AUSGEWICHEN!")


func _move_pieces(delta: float) -> void:
	for d in debris + wreck:
		d.pos += d.vel * delta
		d.rot += d.spin * delta
	debris = debris.filter(func(d): return d.pos.x > -80.0)
	wreck = wreck.filter(func(d): return d.pos.x > -80.0 and d.pos.y > -80.0 and d.pos.y < VIEW.y + 80.0)


# --- Schaden & Zerfall -------------------------------------------------------

## Löst ein Teil von der Station und lässt es wie normalen Müll wegtreiben.
func _throw_off(kind: String, offset: Vector2, scale: float) -> void:
	var dir := offset.normalized() if offset != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
	var v := dir * randf_range(60, 140) + Vector2(-60, vel * 0.5)
	var piece := Debris.make(kind, Vector2(SHIP_X, ship_y) + offset, v, scale)
	piece.rot = 0.0                      # startet exakt so, wie es an der Station saß
	piece.spin = randf_range(-4, 4)
	wreck.append(piece)


## Die ganze Station zerfällt in ihre Bauteile – gleiche Mechanik wie bei den Trümmern.
func _break_apart() -> void:
	broken = true
	for i in ARRAYS.size():
		if not _array_lost(i):
			var a: Vector2 = ARRAYS[i]
			_throw_off("iss_panel", Vector2(a.x * 70, a.y * 19), 1.0)
	_throw_off("strut", Vector2(-42, 0), 2.0)          # Gitterträger links
	_throw_off("strut", Vector2(42, 0), 2.0)           # Gitterträger rechts
	_throw_off("tank", Vector2(0, -14), 1.0)           # Module
	_throw_off("tank", Vector2(0, 14), 1.0)
	_throw_off("strut", Vector2(-28, -10), 0.7)        # Radiatoren
	_throw_off("strut", Vector2(28, 10), 0.7)


func _array_lost(i: int) -> bool:
	for h in LOST_AT_HIT:
		if LOST_AT_HIT[h] == i and hits >= h:
			return true
	return false


# --- Zeichnen ----------------------------------------------------------------

func _draw() -> void:
	draw_stars()
	earth.draw(self, elapsed, elapsed / time_limit)   # Nacht → Sonnenaufgang → Tag
	for d in debris:
		draw_line(d.pos + Vector2(d.r, 0), d.pos + Vector2(d.r + 40, 0), Color(Pal.DEBRIS, 0.25), 2.0)
		Debris.draw(self, d)
	if not broken:
		var blink := invuln > 0.0 and int(invuln * 12.0) % 2 == 0
		if not blink:
			_draw_station(Vector2(SHIP_X, ship_y))
	for w in wreck:
		Debris.draw(self, w)
	draw_text(Vector2(32, 100), "Treffer: %d / %d" % [hits, MAX_HITS], 24, Pal.ALERT if hits > 0 else Pal.DIM)


## Stark vereinfachte ISS: Gitterträger, 4 Solarflügel, Module in der Mitte, Radiatoren.
## Je mehr Treffer, desto mitgenommener: Flügel fehlen, Brandspuren, Luft entweicht, Schlingern.
func _draw_station(p: Vector2) -> void:
	var tilt := 0.0
	if hits >= 2:
		tilt = 0.08 * sin(elapsed * 3.0)
	draw_set_transform(p, tilt, Vector2.ONE)

	# Radiatoren (weiß) – der rechte fehlt ab Treffer 2
	draw_rect(Rect2(-34, -16, 12, 12), C_RADIATOR)
	if hits < 2:
		draw_rect(Rect2(22, 4, 12, 12), C_RADIATOR)

	# Gitterträger (Truss)
	draw_rect(Rect2(-84, -3, 168, 6), C_TRUSS)
	for x in range(-80, 84, 8):
		draw_line(Vector2(x, -3), Vector2(x + 4, 3), C_MODULE_LINE, 1.0)

	# Solarflügel
	for i in ARRAYS.size():
		var a: Vector2 = ARRAYS[i]
		var cx: float = a.x * 70
		if _array_lost(i):
			# abgerissener Stummel
			draw_line(Vector2(cx, a.y * 3), Vector2(cx + 3, a.y * 9), C_ARRAY_LINE, 2.0)
			continue
		var y0: float = 5.0 if a.y > 0 else -33.0
		var r := Rect2(cx - 9, y0, 18, 28)
		var col := C_ARRAY if hits == 0 else C_ARRAY.darkened(0.15 * hits)
		draw_rect(r, col)
		for k in range(1, 4):
			draw_line(Vector2(r.position.x, r.position.y + k * 7), Vector2(r.end.x, r.position.y + k * 7), C_ARRAY_LINE, 1.0)
		draw_line(Vector2(cx, r.position.y), Vector2(cx, r.end.y), C_ARRAY_LINE, 1.0)

	# Module (Mittelstück)
	draw_rect(Rect2(-8, -24, 16, 48), C_MODULE)
	draw_rect(Rect2(-18, -6, 36, 12), C_MODULE)
	for y in [-14, 14]:
		draw_line(Vector2(-8, y), Vector2(8, y), C_MODULE_LINE, 1.0)
	draw_circle(Vector2(0, 0), 4, Pal.ACCENT)

	# Schaden
	if hits >= 1:
		draw_circle(Vector2(5, -17), 4, Color(C_SCORCH, 0.8))
		draw_circle(Vector2(-12, 3), 3, Color(C_SCORCH, 0.6))
	if hits >= 2:
		draw_circle(Vector2(-4, 18), 5, Color(C_SCORCH, 0.9))
		# entweichende Luft aus einem Leck
		for k in 4:
			var t := fmod(elapsed * 1.5 + k * 0.25, 1.0)
			draw_circle(Vector2(-4 - t * 30, 22 + t * 18), 2.5 * (1.0 - t), Color(1, 1, 1, 0.6 * (1.0 - t)))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
