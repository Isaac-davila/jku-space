extends Minigame
## FUNKVERBINDUNG – Frequenz auf das wandernde Signal einstellen und halten.
## Nebenbei fallen auf der Erde Dienste aus → Perspektive "wir alle hängen davon ab".
## Owner: Rolle 2 oder 3 (wer zuerst fertig ist)

const DIAL := Rect2(160, 520, 960, 40)
const LOCK_NEED := 4.0

const SERVICES := ["GPS / Navigation", "Wetterbericht", "Kartenzahlung", "Notruf-Ortung", "Videocall nach Hause"]

var freq := 0.2
var target := 0.7
var lock := 0.0
var strength := 0.0


func _init() -> void:
	title = "Funkverbindung"
	instructions = "A/D oder Pfeiltasten – oder ziehen – Frequenz halten, bis die Verbindung steht"
	time_limit = 22.0


func tick(delta: float) -> void:
	target = clampf(target + (sin(elapsed * 0.9) * 0.12 + sin(elapsed * 2.3) * 0.05) * delta, 0.08, 0.92)
	var dir := Input.get_axis("move_left", "move_right")
	freq += dir * 0.45 * delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mx := get_global_mouse_position().x
		freq = (mx - DIAL.position.x) / DIAL.size.x
	freq = clampf(freq, 0.0, 1.0)
	strength = clampf(1.0 - absf(freq - target) / 0.12, 0.0, 1.0)
	if strength > 0.75:
		lock += delta
	else:
		lock = maxf(lock - delta * 0.6, 0.0)
	if lock >= LOCK_NEED:
		finish(true, "VERBINDUNG STEHT")


func on_timeout() -> void:
	finish(false, "KEIN KONTAKT ZUR ERDE")


func _draw() -> void:
	draw_stars()
	# Wellenform: je schlechter das Signal, desto mehr Rauschen
	var pts := PackedVector2Array()
	var noise := 1.0 - strength
	for i in 86:
		var x := 160.0 + i * 8.0
		var y := 300.0 + sin(i * 0.25 + elapsed * 8.0) * 60.0 * (0.3 + strength) + randf_range(-70, 70) * noise
		pts.append(Vector2(x, y))
	draw_polyline(pts, Pal.ACCENT.lerp(Pal.ALERT, noise), 3.0)

	# Regler
	draw_rect(DIAL, Pal.PANEL)
	draw_rect(DIAL, Pal.LINE, false, 2.0)
	var tx := DIAL.position.x + target * DIAL.size.x
	draw_rect(Rect2(tx - 0.12 * DIAL.size.x * 0.75, DIAL.position.y, 0.24 * DIAL.size.x * 0.75, DIAL.size.y), Color(Pal.OK, 0.15))
	var fx := DIAL.position.x + freq * DIAL.size.x
	draw_rect(Rect2(fx - 6, DIAL.position.y - 12, 12, DIAL.size.y + 24), Pal.WARN)

	# Lock-Fortschritt
	var lw := 300.0 * lock / LOCK_NEED
	draw_rect(Rect2(160, 110, 300, 18), Pal.PANEL)
	draw_rect(Rect2(160, 110, lw, 18), Pal.OK)
	draw_text(Vector2(160, 100), "Verbindungsaufbau", 20, Pal.DIM)
	draw_text(Vector2(480, 126), "Signal %d %%" % int(strength * 100), 20, Pal.TEXT)

	# Status Erde – fällt Stück für Stück aus
	var offline := int(elapsed / (time_limit / (SERVICES.size() + 1)))
	draw_text(Vector2(880, 100), "STATUS ERDE", 20, Pal.DIM)
	for i in SERVICES.size():
		var ok := i >= offline
		draw_text(Vector2(880, 130 + i * 28), ("[OK]  " if ok else "[AUS] ") + SERVICES[i], 18, Pal.OK if ok else Pal.ALERT)
