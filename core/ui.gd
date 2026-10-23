class_name UI
## Kleine Helfer, um Labels per Code zu bauen.


## true auf Handys/Tablets → Texte sagen "Tippen" statt "Klicken / Leertaste".
static func is_touch() -> bool:
	return DisplayServer.is_touchscreen_available()


## Wählt den passenden Steuerungstext für Touch oder Maus/Tastatur.
static func ctrl(touch_text: String, desktop_text: String) -> String:
	return touch_text if is_touch() else desktop_text


static func make_label(text: String, size: int = 24, color: Color = Pal.TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Label, das einen ganzen Bereich ausfüllt und Text zentriert.
static func make_centered(text: String, size: int, color: Color, rect: Rect2) -> Label:
	var l := make_label(text, size, color)
	l.position = rect.position
	l.size = rect.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
