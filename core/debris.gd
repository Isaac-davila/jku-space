class_name Debris
## Weltraummüll-Assets – gemeinsam genutzt von "Ausweichmanöver" und "Abwehrlaser".
##
## Zwei Asset-Gruppen + ein Easter Egg:
##   SOLARZELLEN:  panel (groß)  → panel_half, panel_half, strut
##   METALLTEILE:  stage (groß, ausgebrannte Raketenoberstufe) → nozzle, tank, strut
##   EASTER EGG:   vanguard (Vanguard 1, ältester Satellit, der noch im Orbit ist – seit 1958)
##                 → shell, shell, antenna
##
## Zerfall bei Treffer (2 Stufen):
##   Stufe 0 (groß)  → 3 sinnvolle Bauteile (Stufe 1)
##   Stufe 1 (Teil)  → 3 kleine blaue Dreiecke (Stufe 2 = "shard")
##   Stufe 2 (shard) → zu klein zum Treffen, bleibt einfach im Orbit.
##
## Ein Teil ist ein Dictionary:
##   kind, level, pos, vel, rot, spin, scale, r (Kollisionsradius)
##
## Grafiken ersetzen: nur die _draw_<kind>()-Funktionen unten ändern
## (oder dort draw_texture() mit einem PNG aus assets/ verwenden).

const LEVEL := {
	"panel": 0, "stage": 0, "vanguard": 0,
	"panel_half": 1, "strut": 1, "nozzle": 1, "tank": 1, "shell": 1, "antenna": 1,
	"shard": 2,
	"iss_panel": 1,
}
const BASE_R := {
	"panel": 42.0, "stage": 36.0, "vanguard": 28.0,
	"panel_half": 20.0, "strut": 18.0, "nozzle": 14.0, "tank": 16.0, "shell": 12.0, "antenna": 14.0,
	"shard": 6.0,
	"iss_panel": 16.0,
}
const SPLITS := {
	"panel": ["panel_half", "panel_half", "strut"],
	"stage": ["nozzle", "tank", "strut"],
	"vanguard": ["shell", "shell", "antenna"],
}
const SMALL_PARTS := ["panel_half", "strut", "nozzle", "tank", "shell", "antenna"]
const VANGUARD_CHANCE := 0.1

# Farben
const C_FRAME := Color("1d2f5e")
const C_CELL := Color("2f5fb3")
const C_CELL_HI := Color("6f9be8")
const C_METAL := Color("b8bec9")
const C_METAL_DARK := Color("7d8594")
const C_METAL_LIGHT := Color("d9dde4")
const C_NOZZLE := Color("5c6370")
const C_FOIL := Color("c9a43a")
const C_STRUT := Color("9aa3b5")
const C_SHARD := Color("4da3ff")
const C_SILVER := Color("d7dbe2")
const C_ISS_ARRAY := Color("b5893a")
const C_ISS_ARRAY_LINE := Color("7a5a22")


static func make(kind: String, pos: Vector2, vel: Vector2, scale: float = 1.0) -> Dictionary:
	return {
		"kind": kind,
		"level": LEVEL[kind],
		"pos": pos,
		"vel": vel,
		"rot": randf() * TAU,
		"spin": randf_range(-2.5, 2.5),
		"scale": scale,
		"r": BASE_R[kind] * scale,
	}


## Zufälliges großes Teil: Solarpanel oder Raketenstufe, selten Vanguard 1.
static func random_big(pos: Vector2, vel: Vector2, scale: float = 1.0) -> Dictionary:
	var kind := "vanguard" if randf() < VANGUARD_CHANCE else ("panel" if randf() < 0.5 else "stage")
	return make(kind, pos, vel, scale)


static func random_small(pos: Vector2, vel: Vector2, scale: float = 1.0) -> Dictionary:
	return make(SMALL_PARTS.pick_random(), pos, vel, scale)


static func can_split(p: Dictionary) -> bool:
	return p.level < 2


## Gibt die Bruchstücke zurück (Stufe 0 → Bauteile, Stufe 1 → blaue Dreiecke).
static func split(p: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not can_split(p):
		return out
	var kinds: Array = SPLITS.get(p.kind, ["shard", "shard", "shard"])
	var n := kinds.size()
	var offset := randf() * TAU
	for i in n:
		var dir := Vector2.from_angle(offset + TAU * i / n + randf_range(-0.3, 0.3))
		var child := make(kinds[i], p.pos + dir * p.r * 0.35, p.vel + dir * randf_range(70, 160), p.scale)
		child.spin = randf_range(-5, 5)
		out.append(child)
	return out


# --- Zeichnen ----------------------------------------------------------------

static func draw(ci: CanvasItem, p: Dictionary) -> void:
	ci.draw_set_transform(p.pos, p.rot, Vector2(p.scale, p.scale))
	match p.kind:
		"panel": _draw_panel(ci)
		"panel_half": _draw_panel_half(ci)
		"strut": _draw_strut(ci)
		"stage": _draw_stage(ci)
		"nozzle": _draw_nozzle(ci)
		"tank": _draw_tank(ci)
		"vanguard": _draw_vanguard(ci)
		"shell": _draw_shell(ci)
		"antenna": _draw_antenna(ci)
		"shard": _draw_shard(ci)
		"iss_panel": _draw_iss_panel(ci)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if p.kind == "vanguard" and p.scale >= 0.9:
		ci.draw_string(ThemeDB.fallback_font, p.pos + Vector2(-62, -38), "Vanguard 1 · seit 1958",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.55))


static func _rect(ci: CanvasItem, x: float, y: float, w: float, h: float, c: Color) -> void:
	ci.draw_rect(Rect2(x, y, w, h), c)


# SOLARZELLEN ---------------------------------------------------------------

static func _draw_panel(ci: CanvasItem) -> void:
	_rect(ci, -52, -3, 14, 6, C_STRUT)                 # Ausleger
	_rect(ci, -40, -20, 80, 40, C_FRAME)              # Rahmen
	for col in 4:
		for row in 2:
			var x := -38.0 + col * 19.5
			var y := -18.0 + row * 18.5
			_rect(ci, x, y, 18, 17, C_CELL)
			ci.draw_line(Vector2(x + 2, y + 15), Vector2(x + 16, y + 2), Color(C_CELL_HI, 0.5), 1.0)
	# abgerissene Ecke
	ci.draw_colored_polygon(PackedVector2Array([Vector2(28, 20), Vector2(40, 20), Vector2(40, 8), Vector2(34, 14)]), Pal.BG)


static func _draw_panel_half(ci: CanvasItem) -> void:
	var outline := PackedVector2Array([
		Vector2(-18, -16), Vector2(18, -16), Vector2(13, -6), Vector2(19, 2),
		Vector2(11, 9), Vector2(16, 16), Vector2(-18, 16)])
	ci.draw_colored_polygon(outline, C_FRAME)
	_rect(ci, -16, -14, 13, 13, C_CELL)
	_rect(ci, -1, -14, 11, 13, C_CELL)
	_rect(ci, -16, 1, 13, 13, C_CELL)
	_rect(ci, -1, 1, 9, 9, C_CELL)
	ci.draw_line(Vector2(-14, -3), Vector2(-5, -12), Color(C_CELL_HI, 0.5), 1.0)


static func _draw_strut(ci: CanvasItem) -> void:
	_rect(ci, -20, -3, 40, 6, C_STRUT)
	for x in [-14.0, 0.0, 14.0]:
		ci.draw_circle(Vector2(x, 0), 1.6, C_METAL_DARK)
	ci.draw_line(Vector2(20, -3), Vector2(23, 4), C_STRUT, 2.0)  # verbogenes Ende


# METALLTEILE (Raketenoberstufe) ----------------------------------------------

static func _draw_stage(ci: CanvasItem) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-28, -15), Vector2(-28, 15), Vector2(-36, 8), Vector2(-36, -8)]), C_STRUT)
	_rect(ci, -28, -15, 50, 30, C_METAL)
	_rect(ci, -28, -15, 50, 5, C_METAL_LIGHT)
	for x in [-18.0, 0.0, 14.0]:
		ci.draw_line(Vector2(x, -15), Vector2(x, 15), C_METAL_DARK, 2.0)
	_rect(ci, -12, -6, 10, 10, C_FOIL)                 # Isolierfolie
	ci.draw_colored_polygon(PackedVector2Array([Vector2(22, -8), Vector2(22, 8), Vector2(38, 14), Vector2(38, -14)]), C_NOZZLE)


static func _draw_nozzle(ci: CanvasItem) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-8, -6), Vector2(-8, 6), Vector2(10, 13), Vector2(10, -13)]), C_NOZZLE)
	ci.draw_line(Vector2(10, -13), Vector2(10, 13), C_METAL_DARK, 2.0)
	ci.draw_line(Vector2(-8, -6), Vector2(-8, 6), C_METAL_LIGHT, 2.0)


static func _draw_tank(ci: CanvasItem) -> void:
	_rect(ci, -14, -12, 28, 24, C_METAL)
	_rect(ci, -14, -12, 28, 4, C_METAL_LIGHT)
	ci.draw_line(Vector2(-4, -12), Vector2(-4, 12), C_METAL_DARK, 2.0)
	_rect(ci, 2, -2, 8, 7, C_FOIL)
	# Bruchkante
	ci.draw_polyline(PackedVector2Array([Vector2(14, -12), Vector2(11, -5), Vector2(15, 2), Vector2(11, 12)]), C_METAL_DARK, 2.0)


# EASTER EGG: Vanguard 1 -------------------------------------------------------

static func _draw_vanguard(ci: CanvasItem) -> void:
	for i in 6:
		var dir := Vector2.from_angle(TAU * i / 6.0 + 0.3)
		ci.draw_line(dir * 14.0, dir * 30.0, C_STRUT, 1.5)
		ci.draw_circle(dir * 30.0, 1.5, C_STRUT)
	ci.draw_circle(Vector2.ZERO, 14, C_SILVER)
	ci.draw_circle(Vector2(-4, -4), 5, Color.WHITE)
	ci.draw_arc(Vector2.ZERO, 14, 0, TAU, 24, C_METAL_DARK, 1.0)


static func _draw_shell(ci: CanvasItem) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		pts.append(Vector2.from_angle(PI * i / 12.0) * 12.0)
	ci.draw_colored_polygon(pts, C_SILVER)
	ci.draw_line(Vector2(-12, 0), Vector2(12, 0), C_METAL_DARK, 2.0)


static func _draw_antenna(ci: CanvasItem) -> void:
	ci.draw_line(Vector2(-14, 0), Vector2(14, 0), C_STRUT, 2.0)
	ci.draw_circle(Vector2(14, 0), 2, C_STRUT)
	ci.draw_rect(Rect2(-16, -3, 4, 6), C_SILVER)


# ISS-Solarflügel (fällt beim Ausweichspiel von der Station ab) ----------------

static func _draw_iss_panel(ci: CanvasItem) -> void:
	_rect(ci, -9, -14, 18, 28, C_ISS_ARRAY)
	for k in range(1, 4):
		ci.draw_line(Vector2(-9, -14 + k * 7), Vector2(9, -14 + k * 7), C_ISS_ARRAY_LINE, 1.0)
	ci.draw_line(Vector2(0, -14), Vector2(0, 14), C_ISS_ARRAY_LINE, 1.0)


# KLEINSTE STUFE --------------------------------------------------------------

static func _draw_shard(ci: CanvasItem) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(5, 4), Vector2(-5, 4)]), C_SHARD)
