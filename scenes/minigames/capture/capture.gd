extends Minigame
## TRÜMMER EINFANGEN – Netze auf Trümmergruppen werfen. Je mehr Teile ein Netz
## gleichzeitig fängt, desto mehr Punkte (Multiplikator). Ziel: 100 Punkte.
## Echter Hintergrund: RemoveDEBRIS hat 2018 ein Netz im All getestet. Owner: Rolle 5

const LAUNCHER := Vector2(640, 610)
const NET_SPEED := 1100.0
const NET_RADIUS := 85.0
const OPEN_TIME := 0.3       # Sekunden, bis das Netz ganz offen ist
const PULL_TIME := 0.45      # Sekunden, in denen das Netz zuzieht
const GOAL := 100
const NETS := 8
const POINTS_PER_PIECE := 10 # Punkte = 10 × Anzahl × Anzahl → 10 / 40 / 90 / 160
const MIN_PIECES := 9

var pieces: Array[Dictionary] = []
var net: Dictionary = {}     # leer = kein Netz unterwegs
var nets_left := NETS
var score := 0
var popups: Array[Dictionary] = []


func _init() -> void:
	title = "Trümmer einfangen"
	instructions = UI.ctrl("Tippe, wohin das Netz fliegt – mehrere Teile auf einmal = Bonus!", "Klicke, wohin das Netz fliegt – mehrere Teile auf einmal = Bonus!")
	time_limit = 30.0


func start() -> void:
	for i in 4:
		_spawn_cluster(Vector2(randf_range(180, 1100), randf_range(160, 460)))


## Erzeugt eine Gruppe aus 2–4 Teilen, die gemeinsam treiben.
func _spawn_cluster(center: Vector2) -> void:
	var drift := Vector2(randf_range(-70, 70), randf_range(-20, 20))
	for k in randi_range(2, 4):
		pieces.append({
			"pos": center + Vector2(randf_range(-55, 55), randf_range(-40, 40)),
			"vel": drift + Vector2(randf_range(-12, 12), randf_range(-12, 12)),
			"r": randf_range(10, 20),
			"rot": randf() * TAU,
			"spin": randf_range(-3, 3),
			"seed": randf() * 10.0,
		})


func tick(delta: float) -> void:
	for p in pieces:
		p.pos += p.vel * delta
		p.rot += p.spin * delta
		if p.pos.x < -40:
			p.pos.x = VIEW.x + 40
		elif p.pos.x > VIEW.x + 40:
			p.pos.x = -40
		if p.pos.y < 120 or p.pos.y > 520:
			p.vel.y = -p.vel.y
			p.pos.y = clampf(p.pos.y, 120, 520)

	if pieces.size() < MIN_PIECES:
		var side := -60.0 if randf() < 0.5 else VIEW.x + 60.0
		_spawn_cluster(Vector2(side, randf_range(160, 460)))

	for pop in popups:
		pop.t -= delta
		pop.pos.y -= 40.0 * delta
	popups = popups.filter(func(pop): return pop.t > 0.0)

	if not net.is_empty():
		_update_net(delta)


func _update_net(delta: float) -> void:
	if net.state == "fly":
		net.pos = net.pos.move_toward(net.target, NET_SPEED * delta)
		if net.pos.distance_to(net.target) < 1.0:
			net.state = "open"
			net.t = 0.0
			_catch()
	else:
		net.t += delta
		var pull: float = clampf((net.t - OPEN_TIME) / PULL_TIME, 0.0, 1.0)
		for c in net.caught:
			c.pos = c.pos.lerp(net.pos, pull)
		if net.t >= OPEN_TIME + PULL_TIME:
			net = {}
			_check_end()


## Alles im Netzradius wird gefangen und gewertet.
func _catch() -> void:
	var caught: Array = []
	for i in range(pieces.size() - 1, -1, -1):
		if pieces[i].pos.distance_to(net.pos) < NET_RADIUS + pieces[i].r * 0.5:
			caught.append(pieces[i])
			pieces.remove_at(i)
	net.caught = caught
	var n := caught.size()
	var pts := POINTS_PER_PIECE * n * n
	score += pts
	var text := "Daneben!"
	var col := Pal.DIM
	if n == 1:
		text = "+%d" % pts
		col = Pal.TEXT
	elif n >= 2:
		text = "%der-Fang!  +%d" % [n, pts]
		col = Pal.WARN if n == 2 else Pal.OK
	popups.append({"pos": net.pos + Vector2(-60, -NET_RADIUS - 10), "text": text, "col": col, "t": 1.2})


func _check_end() -> void:
	if score >= GOAL:
		finish(true, "ORBIT AUFGERÄUMT!")
	elif nets_left <= 0:
		finish(false, "KEINE NETZE MEHR")


func on_timeout() -> void:
	if score >= GOAL:
		finish(true, "ORBIT AUFGERÄUMT!")
	else:
		finish(false, "ZEIT ABGELAUFEN")


func _unhandled_input(event: InputEvent) -> void:
	if is_click(event):
		throw_at(get_global_mouse_position())


## Wirft ein Netz Richtung p (nur eins gleichzeitig).
func throw_at(p: Vector2) -> void:
	if done or not net.is_empty() or nets_left <= 0:
		return
	nets_left -= 1
	net = {"pos": LAUNCHER, "target": Vector2(p.x, minf(p.y, 540.0)), "state": "fly", "t": 0.0, "caught": []}


# --- Zeichnen ----------------------------------------------------------------

func _draw() -> void:
	draw_stars()
	for p in pieces:
		draw_debris(p.pos, p.r, p.rot, Pal.DEBRIS, p.seed)

	# Werfer zeigt Richtung Maus
	var aim := (get_global_mouse_position() - LAUNCHER).normalized()
	if aim.y > -0.2:
		aim = Vector2(aim.x, -0.2).normalized()
	draw_line(LAUNCHER, LAUNCHER + aim * 60.0, Pal.HULL, 14.0)
	draw_circle(LAUNCHER, 34, Pal.PANEL)
	draw_circle(LAUNCHER, 24, Pal.HULL)

	if not net.is_empty():
		_draw_net()

	for pop in popups:
		draw_text(pop.pos, pop.text, 30, Color(pop.col, clampf(pop.t * 2.0, 0.0, 1.0)))

	# Punkte-Balken
	var bar := Rect2(32, 90, 360, 20)
	draw_rect(bar, Pal.PANEL)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * minf(float(score) / GOAL, 1.0), bar.size.y)), Pal.OK)
	draw_rect(bar, Pal.LINE, false, 2.0)
	draw_text(Vector2(408, 108), "%d / %d Punkte" % [score, GOAL], 22, Pal.TEXT)
	draw_text(Vector2(32, 146), "1 Teil = 10   ·   2 = 40   ·   3 = 90   ·   4 = 160", 18, Pal.DIM)

	# Verbleibende Netze
	draw_text(Vector2(900, 108), "Netze:", 22, Pal.DIM)
	for i in NETS:
		var c := Pal.ACCENT if i < nets_left else Pal.LINE
		draw_circle(Vector2(985 + i * 26, 101), 9, c)


func _draw_net() -> void:
	var p: Vector2 = net.pos
	draw_line(LAUNCHER, p, Color(Pal.HULL, 0.6), 2.0)   # Seil
	if net.state == "fly":
		draw_circle(p, 12, Pal.ACCENT)
		return
	var open: float = clampf(net.t / OPEN_TIME, 0.0, 1.0)
	var close: float = clampf((net.t - OPEN_TIME) / PULL_TIME, 0.0, 1.0)
	var r: float = NET_RADIUS * ease(open, 0.4) * (1.0 - 0.7 * close)
	if r < 2.0:
		return
	var col := Color(Pal.ACCENT, 0.8)
	draw_arc(p, r, 0, TAU, 32, col, 3.0)
	var step := 16.0
	var o := -r + step
	while o < r:
		var half := sqrt(r * r - o * o)
		draw_line(p + Vector2(-half, o), p + Vector2(half, o), Color(col, 0.5), 1.5)
		draw_line(p + Vector2(o, -half), p + Vector2(o, half), Color(col, 0.5), 1.5)
		o += step
	for c in net.caught:
		draw_debris(c.pos, c.r * (1.0 - 0.5 * close), c.rot, Pal.DEBRIS, c.seed)
