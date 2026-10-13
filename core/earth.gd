class_name Earth
extends RefCounted
## Erde im Hintergrund – nur die obere Kappe (weniger als eine Halbkugel), von der Umlaufbahn aus gesehen.
## Ablauf über `progress` (0 → 1):  Nacht mit Stadtlichtern → Sonnenaufgang am Horizont → Tag.
## Kontinente und Wolken ziehen langsam nach links – wie unter einer echten Station im Orbit.
##
## Benutzung in einem Minispiel:
##   var earth := Earth.new()
##   func _draw(): draw_stars(); earth.draw(self, elapsed, elapsed / time_limit)

const VIEW := Vector2(1280, 720)
const R := 1500.0                 # Erdradius in Pixeln (größer = flacherer Horizont)
const CAP := 165.0                # wie hoch die Erde in der Bildmitte reinragt
const CENTER := Vector2(640, 720 + R - CAP)
const SLICES := 80
const DRIFT_LAND := 22.0          # px/s nach links
const DRIFT_CLOUDS := 30.0
const WRAP := 1800.0              # Breite der "Welt", die sich wiederholt

const C_OCEAN_NIGHT := Color("050b1a")
const C_OCEAN_DAY := Color("1d4f91")
const C_LAND_NIGHT := Color("08110d")
const C_LAND_DAY := Color("3f6b3a")
const C_DESERT_DAY := Color("8a7a52")
const C_CLOUD_DAY := Color(1, 1, 1, 0.85)
const C_CLOUD_NIGHT := Color(0.15, 0.18, 0.25, 0.5)
const C_ATMO_DAY := Color("6fb6ff")
const C_ATMO_NIGHT := Color("1a3a7a")
const C_SUNRISE := Color("ff7a33")
const C_CITY := Color("ffc46b")
const SUN_X := 1080.0

var _land: Array[Dictionary] = []
var _clouds: Array[Dictionary] = []


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42                 # immer dieselbe "Erde"
	for i in 7:
		_land.append(_blob(rng, rng.randf() * WRAP, rng.randf_range(40, 150), 70.0, rng.randf() < 0.3))
	for i in 14:
		_clouds.append(_blob(rng, rng.randf() * WRAP, rng.randf_range(15, 150), 40.0, false))


func _blob(rng: RandomNumberGenerator, x: float, depth_px: float, size: float, desert: bool) -> Dictionary:
	var parts: Array[Vector3] = []
	for k in rng.randi_range(4, 7):
		parts.append(Vector3(rng.randf_range(-size, size), rng.randf_range(-size * 0.4, size * 0.4), rng.randf_range(size * 0.35, size * 0.8)))
	var lights: Array[Vector2] = []
	for k in 8:
		lights.append(Vector2(rng.randf_range(-size, size), rng.randf_range(-size * 0.3, size * 0.3)))
	return {"x": x, "d": depth_px, "parts": parts, "lights": lights, "desert": desert}


## Höhe des Horizonts (Erdrand) an Bildschirm-Position x.
static func limb_y(x: float) -> float:
	var dx := x - CENTER.x
	return CENTER.y - sqrt(maxf(R * R - dx * dx, 0.0))


func draw(ci: CanvasItem, t: float, progress: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	var term_x := lerpf(1700.0, -500.0, smoothstep(0.25, 1.0, p))   # Tag-Nacht-Grenze wandert nach links
	var glow := smoothstep(0.2, 0.45, p) * (1.0 - 0.5 * smoothstep(0.85, 1.0, p))

	_draw_sun(ci, p)

	# Erdkörper in senkrechten Streifen (jeder Streifen hat eigene Helligkeit)
	var w := VIEW.x / SLICES
	for i in SLICES:
		var x0 := i * w
		var x1 := x0 + w
		var l0 := _lit(x0, term_x)
		var l1 := _lit(x1, term_x)
		var top0 := C_OCEAN_NIGHT.lerp(C_OCEAN_DAY, l0).lightened(0.15 * l0)
		var top1 := C_OCEAN_NIGHT.lerp(C_OCEAN_DAY, l1).lightened(0.15 * l1)
		var bot0 := C_OCEAN_NIGHT.lerp(C_OCEAN_DAY, l0).darkened(0.25)
		var bot1 := C_OCEAN_NIGHT.lerp(C_OCEAN_DAY, l1).darkened(0.25)
		ci.draw_polygon(
			PackedVector2Array([Vector2(x0, limb_y(x0)), Vector2(x1, limb_y(x1)), Vector2(x1, VIEW.y), Vector2(x0, VIEW.y)]),
			PackedColorArray([top0, top1, bot1, bot0]))

	_draw_features(ci, _land, fmod(t * DRIFT_LAND, WRAP), term_x, true)
	_draw_features(ci, _clouds, fmod(t * DRIFT_CLOUDS, WRAP), term_x, false)

	# Atmosphäre: dünner leuchtender Saum über dem Horizont
	for i in SLICES:
		var x0 := i * w
		var x1 := x0 + w
		var c0 := _atmo_color(x0, term_x, glow)
		var c1 := _atmo_color(x1, term_x, glow)
		var y0 := limb_y(x0)
		var y1 := limb_y(x1)
		var clear0 := Color(c0, 0.0)
		var clear1 := Color(c1, 0.0)
		ci.draw_polygon(
			PackedVector2Array([Vector2(x0, y0 - 22), Vector2(x1, y1 - 22), Vector2(x1, y1 + 6), Vector2(x0, y0 + 6)]),
			PackedColorArray([clear0, clear1, c1, c0]))
		ci.draw_line(Vector2(x0, y0), Vector2(x1, y1), Color(c0, minf(c0.a + 0.25, 1.0)), 1.5)


func _lit(x: float, term_x: float) -> float:
	return clampf((x - term_x) / 350.0 + 0.5, 0.0, 1.0)


func _atmo_color(x: float, term_x: float, glow: float) -> Color:
	var l := _lit(x, term_x)
	var c := C_ATMO_NIGHT.lerp(C_ATMO_DAY, l)
	c.a = lerpf(0.3, 0.85, l)
	# Sonnenaufgangs-Orange rund um die Tag-Nacht-Grenze
	var band := exp(-pow((x - term_x) / 260.0, 2.0)) * glow
	return c.lerp(Color(C_SUNRISE, 0.95), band)


func _draw_sun(ci: CanvasItem, p: float) -> void:
	var rise := smoothstep(0.3, 0.8, p)
	if rise <= 0.0:
		return
	var base := limb_y(SUN_X)
	var pos := Vector2(SUN_X, base + lerpf(20.0, -55.0, rise))
	for k in range(16, 0, -1):
		ci.draw_circle(pos, 10.0 + k * 7.0, Color(1.0, 0.85, 0.6, 0.022 * rise))
	ci.draw_circle(pos, 13.0, Color(1.0, 0.97, 0.88, minf(rise * 2.0, 1.0)))


func _draw_features(ci: CanvasItem, list: Array[Dictionary], scroll: float, term_x: float, is_land: bool) -> void:
	for f in list:
		var x: float = fposmod(f.x - scroll, WRAP) - 260.0
		if x < -200.0 or x > VIEW.x + 200.0:
			continue
		var limb := limb_y(x)
		var y: float = limb + f.d
		# Perspektive: nah am Horizont flach und blass, weiter unten voll sichtbar
		var depth := clampf(f.d / 150.0, 0.0, 1.0)
		var sy := lerpf(0.18, 0.55, depth)
		var fade := smoothstep(0.08, 0.35, depth)
		var l := _lit(x, term_x)
		var col: Color
		if is_land:
			var day := C_DESERT_DAY if f.desert else C_LAND_DAY
			col = C_LAND_NIGHT.lerp(day, l)
		else:
			col = C_CLOUD_NIGHT.lerp(C_CLOUD_DAY, l)
		col.a *= fade
		ci.draw_set_transform(Vector2(x, y), 0.0, Vector2(1.0, sy))
		for part in f.parts:
			ci.draw_circle(Vector2(part.x, part.y), part.z, col)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Stadtlichter auf der Nachtseite
		if is_land and l < 0.9:
			for pt in f.lights:
				var lp := Vector2(x + pt.x, y + pt.y * sy)
				if lp.y > limb_y(lp.x) + 4.0:
					ci.draw_circle(lp, 1.6, Color(C_CITY, (1.0 - l) * 0.9 * fade))
