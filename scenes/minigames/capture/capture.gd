extends Minigame
## WRACK BERGEN – Ein taumelnder toter Satellit. Zugreifen, wenn der gelbe
## Haltegriff oben beim Greifarm ist. 3 Griffe = stabilisiert.
## Echter Hintergrund: Missionen wie ClearSpace-1 / RemoveDEBRIS. Owner: Rolle 5

const CENTER := Vector2(640, 430)
const CLAW_TOP := Vector2(640, 90)
const GRAB_WINDOW := 0.28   # rad Toleranz
const NEED := 3
const MAX_MISS := 3

var angle := 0.0
var ang_vel := 2.4
var grabs := 0
var misses := 0
var claw_t := 0.0
var feedback := ""
var feedback_col := Pal.TEXT
var feedback_t := 0.0


func _init() -> void:
	title = "Wrack bergen"
	instructions = "Leertaste oder Tippen, wenn der gelbe Griff OBEN ist"
	time_limit = 22.0


func tick(delta: float) -> void:
	var wobble := 1.0 + 0.35 * sin(elapsed * 1.7)
	angle = wrapf(angle + ang_vel * wobble * delta, -PI, PI)
	claw_t = maxf(claw_t - delta, 0.0)
	feedback_t = maxf(feedback_t - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if done:
		return
	if not (is_click(event) or event.is_action_pressed("interact")):
		return
	if claw_t > 0.0:
		return
	claw_t = 0.45
	# Griff sitzt lokal bei Winkel 0 → zeigt nach oben, wenn angle == -PI/2
	var diff := absf(wrapf(angle + PI / 2.0, -PI, PI))
	if diff < GRAB_WINDOW:
		grabs += 1
		ang_vel *= 0.65
		_feedback("GEGRIFFEN!", Pal.OK)
		if grabs >= NEED:
			finish(true, "WRACK STABILISIERT")
	else:
		misses += 1
		ang_vel *= 1.2
		_feedback("Daneben – es taumelt stärker!", Pal.ALERT)
		if misses >= MAX_MISS:
			finish(false, "WRACK ENTGLITTEN")


func _feedback(text: String, col: Color) -> void:
	feedback = text
	feedback_col = col
	feedback_t = 1.0


func _draw() -> void:
	draw_stars()
	# Greifarm
	var ext := sin(clampf(claw_t / 0.45, 0.0, 1.0) * PI) * 120.0
	var claw_end := CLAW_TOP + Vector2(0, 90 + ext)
	draw_line(CLAW_TOP, claw_end, Pal.HULL, 10.0)
	draw_line(claw_end, claw_end + Vector2(-22, 26), Pal.HULL, 6.0)
	draw_line(claw_end, claw_end + Vector2(22, 26), Pal.HULL, 6.0)
	# Zielzone
	draw_arc(CENTER, 150, -PI / 2.0 - GRAB_WINDOW, -PI / 2.0 + GRAB_WINDOW, 16, Color(Pal.OK, 0.5), 8.0)
	# Wrack
	draw_set_transform(CENTER, angle, Vector2.ONE)
	draw_rect(Rect2(-60, -45, 120, 90), Color("6b6f7a"))
	draw_rect(Rect2(-60, -45, 120, 90), Pal.DIM, false, 3.0)
	draw_rect(Rect2(-190, -28, 125, 56), Color("2b4a8c"))
	draw_rect(Rect2(65, -28, 70, 56), Color("2b4a8c"))           # abgebrochenes Panel
	draw_line(Vector2(135, -28), Vector2(150, 10), Color("2b4a8c"), 6.0)
	draw_circle(Vector2(150, 0), 14, Pal.WARN)                    # Haltegriff (lokal Winkel 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_text(Vector2(32, 100), "Griffe: %d / %d" % [grabs, NEED], 24, Pal.OK)
	draw_text(Vector2(32, 132), "Fehlgriffe: %d / %d" % [misses, MAX_MISS], 20, Pal.ALERT if misses > 0 else Pal.DIM)
	if feedback_t > 0.0:
		draw_text(Vector2(820, 300), feedback, 26, Color(feedback_col, feedback_t))
