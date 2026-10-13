extends Minigame
## AUSWEICHMANÖVER – Station per Schub hoch/runter steuern, Trümmern ausweichen.
## Echter Hintergrund: Die ISS führt regelmäßig Ausweichmanöver durch.
## Owner: Rolle 2

const SHIP_X := 220.0
const SHIP_R := 30.0
const MAX_HITS := 3
# Kamerafahrt nach dem Zerfall: die Kamera folgt einem Trümmerteil, bis es einen Satelliten trifft.
## (GPS-Satelliten fliegen auf ~20.000 km Höhe – ISS-Trümmer kommen da nie hin.
##  Realistisch sind Satelliten im niedrigen Orbit wie Wetter- oder Internetsatelliten.)
const VICTIM_NAME := "Wettersatellit"
const VICTIM_ACC := "einen Wettersatelliten"   # für den Satz "trifft …"
const CAM_ZOOM := 1.9          # wie nah die Kamera rangeht
const CAM_SPEED := 1.2         # wie schnell die Kamera ranfährt (kleiner = gemächlicher)
const ALONE_TIME := 2.0        # so lange sieht man das Teil ganz allein, bevor der Satellit kommt
const ALONE_MAX := 6.0         # Sicherheitsnetz: spätestens dann kommt der Satellit
const SAT_APPROACH := 110.0    # wie langsam sich der Satellit nähert (px/s im Bild)
const SLOWMO := 0.25           # Zeitlupe beim Einschlag (1.0 = normal)
const SLOWMO_TIME := 2.0       # Sekunden Zeitlupe
const ZOOM_OUT_AFTER := 1.5    # so lange nach dem Einschlag bleibt die Kamera nah dran
const RAMP_TIME := 4.0         # so lange dauert es, bis wieder gleich viel Müll kommt wie vorher
const END_DELAY := 6.5         # nach dem Einschlag, bis "STATION ZERBROCHEN" kommt
const CHAIN_TIMEOUT := 18.0    # Sicherheitsnetz

# Spielgefühl
const SPAWN_AHEAD := 380.0     # so weit rechts außerhalb entsteht Müll → Zeit für die Warnung am Rand
const SHAKE_HIT := 14.0        # Bildschirmwackeln bei einem Treffer (Pixel)
const SHAKE_BREAK := 22.0      # … beim Zerfall
const STAR_DRIFT := 12.0       # Sterne ziehen langsam vorbei (px/s) – man fliegt ja

# Physik
const IMPULSE := 0.35          # wie viel Schwung ein Treffer an die Stationsteile weitergibt
const MAX_PIECES := 220        # ab so vielen Teilen zerbricht nichts mehr (Leistung)

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
# Welcher Flügel abreißt, entscheidet der Einschlagsort: immer der, der am nächsten dran ist.

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
var thrust := 0.0                 # -1 = Schub nach oben, +1 = nach unten (für die Düsen-Animation)

# Kamerafahrt
var cam: Camera2D
var bg_layer: CanvasLayer
var bg: Node2D
var cap_label: Label
var follow: Dictionary = {}        # das Trümmerteil, dem die Kamera folgt
var victim: Dictionary = {}        # der Satellit, der getroffen wird
var impact_t := -1.0               # broken_t beim Einschlag (-1 = noch nicht)
var time_k := 1.0                  # Zeitlupen-Faktor
var flashes: Array[Dictionary] = []
var follow_t := 0.0                # wie lange wir dem Teil schon folgen
var alone_t := 0.0                 # wie lange das Teil schon allein im Bild ist
var spawning := true               # während der Kamerafahrt kommt kein neuer Müll
var spawn_ramp := 1.0              # 0 → 1: Müll kommt nach der Kamerafahrt langsam wieder

# Spielgefühl
var shake := 0.0                   # aktuelle Wackel-Stärke, klingt von selbst ab
var hit_flash := 0.0               # roter Bildschirmrand bei Treffern (1 → 0)
var hud_draw: Control              # Hüllenanzeige oben links
var lost_arrays: Array[int] = []   # Indizes der abgerissenen Solarflügel


func start() -> void:
	# Hintergrund (Sterne + Erde) in eigener Ebene → bleibt stehen, wenn die Kamera fährt
	bg_layer = CanvasLayer.new()
	bg_layer.layer = -5
	add_child(bg_layer)
	bg = Node2D.new()
	bg_layer.add_child(bg)
	bg.draw.connect(_draw_background)
	cam = Camera2D.new()
	cam.position = VIEW / 2.0
	add_child(cam)
	cam.enabled = true                # immer aktiv – für Bildschirmwackeln und Kamerafahrt
	cam.make_current()
	var hud := CanvasLayer.new()
	hud.layer = 6
	add_child(hud)
	cap_label = UI.make_centered("", 28, Pal.WARN, Rect2(40, 90, VIEW.x - 80, 90))
	cap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(cap_label)
	hud_draw = Control.new()
	hud_draw.size = VIEW
	hud_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_draw.draw.connect(_draw_hud)
	hud.add_child(hud_draw)


func _exit_tree() -> void:
	# Kamera zurücksetzen, damit der Hub danach nicht verschoben aussieht
	if is_inside_tree():
		get_viewport().canvas_transform = Transform2D.IDENTITY


func _init() -> void:
	title = "Ausweichmanöver"
	instructions = ""   # kein Steuerungstext unten
	time_limit = 20.0


func tick(delta: float) -> void:
	bg.queue_redraw()
	_update_feel(delta)
	_move_pieces(delta * time_k)
	if spawning:
		_spawn_debris(delta * time_k)
	if broken:
		broken_t += delta
		_update_cinematic(delta)
		if (impact_t >= 0.0 and broken_t >= impact_t + END_DELAY) or broken_t >= CHAIN_TIMEOUT:
			finish(false, "STATION ZERBROCHEN")
		return

	var input := Input.get_axis("move_up", "move_down")
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		input = clampf((get_global_mouse_position().y - ship_y) / 80.0, -1.0, 1.0)
	thrust = input
	vel += input * 1700.0 * delta
	vel -= vel * 2.2 * delta
	ship_y += vel * delta
	if ship_y < 110.0 or ship_y > 620.0:
		ship_y = clampf(ship_y, 110.0, 620.0)
		vel = 0.0

	invuln = maxf(invuln - delta, 0.0)
	var ship := Vector2(SHIP_X, ship_y)
	for d in debris:
		if invuln <= 0.0 and d.pos.distance_to(ship) < SHIP_R + d.r * 0.8:
			# das Trümmerteil verschwindet nicht – es zerbricht und fliegt gebremst weiter
			debris.erase(d)
			for frag in Debris.split(d):
				frag.vel = d.vel * 0.55 + (frag.vel - d.vel) * 0.6
				frag["immune"] = 0.5
				debris.append(frag)
			take_hit(d)
			return


## Ein Treffer: Station verliert ein Teil – beim letzten Treffer zerfällt sie.
## hit: das Trümmerteil, das uns getroffen hat (für Richtung und Einschlagsort).
func take_hit(hit: Dictionary = {}) -> void:
	hits += 1
	invuln = 1.0
	shake = SHAKE_HIT
	hit_flash = 1.0
	var ship := Vector2(SHIP_X, ship_y)
	var impact_pos: Vector2 = hit.get("pos", ship + Vector2(40, 0))
	var push: Vector2 = hit.get("vel", Vector2(-450, 0)) * IMPULSE
	flashes.append({"pos": ship + (impact_pos - ship).limit_length(40.0), "t": 0.3})
	if hits >= MAX_HITS:
		_break_apart(push, impact_pos)
		return
	# der Flügel, der dem Einschlag am nächsten ist, reißt ab – und fliegt in Stoßrichtung weg
	var best := -1
	var best_d := INF
	for i in ARRAYS.size():
		if _array_lost(i):
			continue
		var a: Vector2 = ARRAYS[i]
		var dist := (ship + _array_offset(a)).distance_to(impact_pos)
		if dist < best_d:
			best = i
			best_d = dist
	if best >= 0:
		lost_arrays.append(best)
		_throw_off("iss_panel", _array_offset(ARRAYS[best]), 1.0, push * 1.4)


func _array_offset(a: Vector2) -> Vector2:
	return Vector2(a.x * 70, a.y * 19)


## Auch nach "STATION ZERBROCHEN" / "AUSGEWICHEN!" fliegt der Müll im Hintergrund weiter.
func post_tick(delta: float) -> void:
	bg.queue_redraw()
	_update_feel(delta)
	_move_pieces(delta * time_k)
	if spawning:
		_spawn_debris(delta * time_k)
	if broken:
		broken_t += delta
		_update_cinematic(delta)


func _spawn_debris(delta: float) -> void:
	spawn_t -= delta
	if spawn_t > 0.0:
		return
	spawn_t = lerpf(0.5, 0.16, difficulty()) / maxf(spawn_ramp, 0.08)
	var view := _view_rect()
	var ahead := SPAWN_AHEAD if not broken else 60.0
	var pos := Vector2(view.end.x + ahead, view.position.y + randf_range(100, 630))
	var dv := Vector2(-randf_range(380, 600) * (1.0 + difficulty() * 0.6), 0)
	# 40 % große Teile (verkleinert), sonst einzelne Bauteile – siehe core/debris.gd
	if randf() < 0.4:
		debris.append(Debris.random_big(pos, dv, randf_range(0.55, 0.7)))
	else:
		debris.append(Debris.random_small(pos, dv))


func on_timeout() -> void:
	if not broken:
		finish(true, "AUSGEWICHEN!")


func _move_pieces(delta: float) -> void:
	for d in debris + wreck:
		d.pos += d.vel * delta
		d.rot += d.spin * delta
		if d.has("immune"):
			d.immune -= delta
	var left := _view_rect().position.x
	debris = debris.filter(func(d): return d.pos.x > left - 80.0)
	# großzügige Grenzen, weil die Kamera beim Zerfall mitfährt
	wreck = wreck.filter(func(d): return d.pos.x > -1500.0 and d.pos.y > -600.0 and d.pos.y < VIEW.y + 600.0)


# --- Schaden & Zerfall -------------------------------------------------------

## Löst ein Teil von der Station und lässt es wie normalen Müll wegtreiben.
## push: Schwung vom Einschlag – das Teil fliegt in die Richtung, in die es gestoßen wurde.
func _throw_off(kind: String, offset: Vector2, scale: float, push := Vector2.ZERO) -> void:
	var dir := offset.normalized() if offset != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
	var v := dir * randf_range(60, 140) + Vector2(-60, vel * 0.5) + push
	var piece := Debris.make(kind, Vector2(SHIP_X, ship_y) + offset, v, scale)
	piece.rot = 0.0                      # startet exakt so, wie es an der Station saß
	piece.spin = randf_range(-4, 4)
	wreck.append(piece)


## Die ganze Station zerfällt in ihre Bauteile – gleiche Mechanik wie bei den Trümmern.
func _break_apart(push := Vector2(-160, 0), impact_pos := Vector2.INF) -> void:
	broken = true
	set_timer_visible(false)           # nach dem Tod keine Zeit mehr oben rechts
	shake = SHAKE_BREAK
	var parts := [
		["strut", Vector2(-42, 0), 2.0],          # Gitterträger links
		["strut", Vector2(42, 0), 2.0],           # Gitterträger rechts
		["tank", Vector2(0, -14), 1.0],           # Module
		["tank", Vector2(0, 14), 1.0],
		["tank", Vector2(0, 34), 0.7],            # angedockter Progress-Frachter
		["strut", Vector2(-28, -10), 0.7],        # Radiatoren
		["strut", Vector2(28, 10), 0.7],
	]
	for i in ARRAYS.size():
		if not _array_lost(i):
			parts.append(["iss_panel", _array_offset(ARRAYS[i]), 1.0])
	var ship := Vector2(SHIP_X, ship_y)
	if impact_pos == Vector2.INF:
		impact_pos = ship + Vector2(40, 0)
	for part in parts:
		# Teile nahe am Einschlag bekommen mehr Schwung ab
		var near := 1.0 - clampf((ship + part[1]).distance_to(impact_pos) / 140.0, 0.0, 0.7)
		_throw_off(part[0], part[1], part[2], push * near)
	_start_cinematic()


# --- Kamerafahrt: ein Trümmerteil trifft einen Satelliten ---------------------

func _start_cinematic() -> void:
	spawning = false
	# Der linke Gitterträger treibt langsam davon – ihm folgt die Kamera
	follow = wreck[0]
	for w in wreck:
		if w.kind == "strut" and w.scale > 1.5 and w.pos.x < SHIP_X:
			follow = w
	follow.vel = Vector2(-50, -8)
	follow.spin = 0.8
	# alle anderen Teile driften deutlich weg, damit das eine Teil bald allein ist
	for w in wreck:
		if w != follow:
			var away: Vector2 = (w.pos - follow.pos).normalized()
			if away == Vector2.ZERO:
				away = Vector2.from_angle(randf() * TAU)
			w.vel = follow.vel + away * randf_range(180, 300) + (w.vel - follow.vel) * 0.25
	cam.position = VIEW / 2.0
	cam.zoom = Vector2.ONE
	cam.enabled = true
	cam.make_current()
	_say("Die Station ist zerbrochen.")


func _update_cinematic(delta: float) -> void:
	if follow.is_empty():
		return

	# 1) Dem Teil folgen, bis es allein im Bild ist → dann kommt der Satellit von rechts
	if victim.is_empty() and impact_t < 0.0:
		follow_t += delta
		if alone_t > 0.0 or (follow_t > 0.8 and _others_in_view() == 0) or follow_t >= ALONE_MAX:
			if alone_t == 0.0:
				_say("Ein einziges Trümmerteil. Niemand kann es mehr steuern.")
			alone_t += delta
			if alone_t >= ALONE_TIME:
				_spawn_victim()

	# 2) Satellit nähert sich langsam von rechts
	if not victim.is_empty():
		var dir: Vector2 = (follow.pos - victim.pos).normalized()
		victim.vel = follow.vel + dir * SAT_APPROACH
		victim.pos += victim.vel * delta * time_k
		if victim.pos.distance_to(follow.pos) < victim.r + follow.r * 0.4:
			_impact()

	# 3) Nach dem Einschlag: Zeitlupe, dann langsam zurück auf normal
	if impact_t >= 0.0:
		var since := broken_t - impact_t
		time_k = SLOWMO if since < SLOWMO_TIME else lerpf(time_k, 1.0, clampf(1.5 * delta, 0.0, 1.0))
		if since > ZOOM_OUT_AFTER:
			if not spawning:
				spawning = true
				spawn_ramp = 0.0
				spawn_t = 0.6
			spawn_ramp = minf(spawn_ramp + delta / RAMP_TIME, 1.0)

	# Kamera: langsam ranzoomen und dem Teil folgen, nach der Zeitlupe gemächlich rauszoomen
	var target_zoom := CAM_ZOOM
	var target_pos: Vector2 = follow.pos
	if impact_t >= 0.0 and broken_t - impact_t > ZOOM_OUT_AFTER:
		target_zoom = 1.0          # rauszoomen, aber über der Einschlagstelle bleiben
	var k := clampf(CAM_SPEED * delta, 0.0, 1.0)
	cam.zoom = cam.zoom.lerp(Vector2(target_zoom, target_zoom), k)
	cam.position = cam.position.lerp(target_pos, clampf(k * 2.5, 0.0, 1.0))


## Sichtbarer Bereich in Spielkoordinaten (folgt der Kamera, sobald sie aktiv ist).
func _view_rect() -> Rect2:
	if cam == null or not cam.enabled:
		return Rect2(Vector2.ZERO, VIEW)
	var half := VIEW / (2.0 * cam.zoom.x)
	return Rect2(cam.position - half, half * 2.0)


## Wie viele andere Teile gerade noch im Kamerabild sind.
func _others_in_view() -> int:
	var half := VIEW / (2.0 * cam.zoom.x)
	var view := Rect2(cam.position - half, half * 2.0).grow(20.0)
	var n := 0
	for d in debris + wreck:
		if d != follow and view.has_point(d.pos):
			n += 1
	return n


func _spawn_victim() -> void:
	var half_w := VIEW.x / (2.0 * cam.zoom.x)
	victim = Debris.make("sat", follow.pos + Vector2(half_w + 60.0, -25.0), follow.vel, 1.0)
	victim.rot = 0.0
	victim.spin = 0.15
	_say("Ein %s kreuzt seine Bahn …" % VICTIM_NAME)


func _impact() -> void:
	impact_t = broken_t
	flashes.append({"pos": victim.pos, "t": 0.3})
	var parts := Debris.split(victim)
	for part in parts:
		part.vel = part.vel * 1.3 + follow.vel * 0.3
	var shards := _split_in_two(follow)        # das Stationsteil bricht in zwei Hälften
	wreck.erase(follow)
	wreck.append_array(parts)
	wreck.append_array(shards)
	follow = {"pos": victim.pos, "vel": Vector2.ZERO, "r": 0.0}   # Kamera bleibt am Einschlagsort
	for part in parts + shards:
		part.vel *= 0.6                        # Bruchstücke treiben ruhiger auseinander
	victim = {}
	GameState.flags["kessler_seen"] = true
	_say("… und das Trümmerteil trifft %s.\nAus einem Trümmerteil werden viele – jedes kann den nächsten treffen.\nDas ist das Kessler-Syndrom." % VICTIM_ACC)


## Bricht ein Teil in zwei kleinere Hälften desselben Typs (z. B. ein halber Gitterträger).
func _split_in_two(p: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var axis := Vector2.RIGHT.rotated(p.rot)
	for side in [-1.0, 1.0]:
		var half_len: float = p.r * 0.5
		var piece := Debris.make(p.kind, p.pos + axis * side * half_len, p.vel, p.scale * 0.5)
		piece.rot = p.rot + side * 0.25          # leicht abgeknickt
		piece.vel = p.vel + (axis * side + Vector2(0, randf_range(-0.6, 0.6))).normalized() * randf_range(60, 110)
		piece.spin = side * randf_range(0.8, 1.6)
		out.append(piece)
	return out


func _say(text: String) -> void:
	cap_label.text = text


func _array_lost(i: int) -> bool:
	return lost_arrays.has(i)


# --- Zeichnen ----------------------------------------------------------------

func _draw_background() -> void:
	for st in _stars:
		# hellere (= nähere) Sterne ziehen etwas schneller → leichte Tiefenwirkung
		var x := fposmod(st.x - elapsed * STAR_DRIFT * st.z, VIEW.x)
		bg.draw_circle(Vector2(x, st.y), st.z, Color(1, 1, 1, 0.25 + st.z * 0.2))
	earth.draw(bg, elapsed, elapsed / time_limit)     # Nacht → Sonnenaufgang → Tag


func _draw() -> void:
	for d in debris:
		_draw_trail(d)
		Debris.draw(self, d)
	if not broken:
		_draw_warnings()
	if not broken:
		var blink := invuln > 0.0 and int(invuln * 12.0) % 2 == 0
		if not blink:
			_draw_station(Vector2(SHIP_X, ship_y))
	for w in wreck:
		Debris.draw(self, w)
	if not victim.is_empty():
		Debris.draw(self, victim)
		draw_string(ThemeDB.fallback_font, victim.pos + Vector2(-60, -34), VICTIM_NAME,
			HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(Pal.TEXT, 0.85))
	for f in flashes:
		var k: float = f.t / 0.3
		draw_circle(f.pos, 30.0 * (1.0 - k) + 4.0, Color(1, 1, 1, 0.85 * k))


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

	_draw_progress_and_thrusters()

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


## Angedockter Progress-Frachter unten an den Modulen. Wie bei der echten ISS
## übernehmen seine Triebwerke das Ausweichmanöver (Bahnanhebung).
## Hochfliegen = Haupttriebwerk am Frachter, Runterfliegen = kleine Lagedüsen oben.
func _draw_progress_and_thrusters() -> void:
	# Frachter
	draw_rect(Rect2(-6, 24, 12, 16), Color("9aa58a"))
	draw_rect(Rect2(-17, 29, 9, 6), Color("1d2f5e"))
	draw_rect(Rect2(8, 29, 9, 6), Color("1d2f5e"))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, 40), Vector2(4, 40), Vector2(6, 45), Vector2(-6, 45)]), Color("5c6370"))

	var flicker := 0.8 + 0.2 * sin(elapsed * 60.0)
	if thrust < -0.05 and not broken:
		# Haupttriebwerk: Flamme nach unten → Station steigt
		var length := (14.0 + 26.0 * -thrust) * flicker
		draw_colored_polygon(PackedVector2Array([Vector2(-5, 45), Vector2(5, 45), Vector2(0, 45 + length)]), Color(1.0, 0.55, 0.15, 0.85))
		draw_colored_polygon(PackedVector2Array([Vector2(-2.5, 45), Vector2(2.5, 45), Vector2(0, 45 + length * 0.55)]), Color(1.0, 0.95, 0.7, 0.95))
	elif thrust > 0.05 and not broken:
		# Lagedüsen oben: kurze Gas-Stöße → Station sinkt
		var length := (6.0 + 10.0 * thrust) * flicker
		for x in [-6.0, 6.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(x - 2.5, -24), Vector2(x + 2.5, -24), Vector2(x, -24 - length)]), Color(0.85, 0.92, 1.0, 0.8))


# --- Spielgefühl: Wackeln, Treffer-Blitz, Warnungen, Hüllenanzeige -------------

func _update_feel(delta: float) -> void:
	for f in flashes:
		f.t -= delta
	flashes = flashes.filter(func(f): return f.t > 0.0)
	if broken or done:
		_collide_pieces()
	shake = maxf(shake - 40.0 * delta, 0.0)
	hit_flash = maxf(hit_flash - 2.2 * delta, 0.0)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	hud_draw.queue_redraw()


## Bewegungsspur hinter jedem Teil: wird nach hinten blasser.
func _draw_trail(d: Dictionary) -> void:
	var start: Vector2 = d.pos + Vector2(d.r * 0.6, 0)
	var length := clampf(-d.vel.x * 0.12, 20.0, 90.0)
	for k in 4:
		var a := start + Vector2(length * k / 4.0, 0)
		var b := start + Vector2(length * (k + 1) / 4.0, 0)
		draw_line(a, b, Color(Pal.DEBRIS, 0.22 * (1.0 - k / 4.0)), 2.0)


## Rote Markierung am rechten Rand für Müll, der gleich ins Bild fliegt.
## (Wie bei der echten ISS: Bahnverfolgung warnt, bevor das Teil da ist.)
func _draw_warnings() -> void:
	var edge := _view_rect().end.x
	for d in debris:
		if d.pos.x <= edge:
			continue
		var dist: float = d.pos.x - edge
		var a := clampf(1.0 - dist / SPAWN_AHEAD, 0.15, 1.0)
		var size := 7.0 + 6.0 * clampf(d.r / 25.0, 0.0, 1.0)
		var tip := Vector2(edge - 12.0, d.pos.y)
		var pulse := 0.7 + 0.3 * sin(elapsed * 14.0)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(size, -size), tip + Vector2(size, size)]),
			Color(Pal.ALERT, a * pulse))


func _draw_hud() -> void:
	# roter Rand bei Treffern
	if hit_flash > 0.0:
		var c := Color(Pal.ALERT, 0.35 * hit_flash)
		var w := 26.0
		hud_draw.draw_rect(Rect2(0, 0, VIEW.x, w), c)
		hud_draw.draw_rect(Rect2(0, VIEW.y - w, VIEW.x, w), c)
		hud_draw.draw_rect(Rect2(0, 0, w, VIEW.y), c)
		hud_draw.draw_rect(Rect2(VIEW.x - w, 0, w, VIEW.y), c)
	if broken:
		return
	# Hüllenanzeige: 3 Segmente, die bei Treffern ausgehen
	var font := ThemeDB.fallback_font
	hud_draw.draw_string(font, Vector2(32, 92), "HÜLLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Pal.DIM)
	for i in MAX_HITS:
		var intact := i < MAX_HITS - hits
		var col := (Pal.OK if hits == 0 else (Pal.WARN if hits == 1 else Pal.ALERT)) if intact else Color(Pal.LINE, 0.6)
		if intact and hits == MAX_HITS - 1:
			col.a = 0.6 + 0.4 * sin(elapsed * 10.0)      # letztes Segment blinkt
		hud_draw.draw_rect(Rect2(95 + i * 34, 78, 28, 16), col)


# --- Zusammenstöße zwischen Trümmern (nach dem Tod / nach Spielende) ---------

## Alle Teile können sich gegenseitig treffen. Größere Teile zerbrechen dabei,
## blaue Splitter prallen nur ab. Die Bruchstücke übernehmen den gemeinsamen Schwung.
func _collide_pieces() -> void:
	var all: Array = []
	var view := _view_rect().grow(150.0)
	for d in debris + wreck:
		if d != follow and view.has_point(d.pos) and d.get("immune", 0.0) <= 0.0:
			all.append(d)
	var allow_split := debris.size() + wreck.size() < MAX_PIECES
	var used := PackedByteArray()
	used.resize(all.size())
	for i in all.size():
		if used[i]:
			continue
		var a: Dictionary = all[i]
		for j in range(i + 1, all.size()):
			if used[j]:
				continue
			var b: Dictionary = all[j]
			if not Debris.can_split(a) and not Debris.can_split(b):
				continue
			if a.pos.distance_to(b.pos) > (a.r + b.r) * 0.6:
				continue
			used[i] = 1
			used[j] = 1
			_resolve_collision(a, b, allow_split)
			break


func _resolve_collision(a: Dictionary, b: Dictionary, allow_split: bool) -> void:
	var ma: float = a.r * a.r
	var mb: float = b.r * b.r
	var common: Vector2 = (a.vel * ma + b.vel * mb) / (ma + mb)   # gemeinsamer Schwung
	flashes.append({"pos": (a.pos + b.pos) * 0.5, "t": 0.2})
	for p in [a, b]:
		var other: Dictionary = b if p == a else a
		var away: Vector2 = (p.pos - other.pos).normalized()
		if allow_split and Debris.can_split(p):
			var frags := Debris.split(p)
			for frag in frags:
				frag.vel = common + (frag.vel - p.vel) * 0.7 + away * 40.0
				frag["immune"] = 0.5
			if debris.has(p):
				debris.erase(p)
			else:
				wreck.erase(p)
			wreck.append_array(frags)
		else:
			p.vel = common + away * 70.0
			p["immune"] = 0.3
