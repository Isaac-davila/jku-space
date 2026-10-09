extends StoryScreen
## Ende: Ausgang je nach Spielverlauf → emotionaler Schluss → echte Fakten → Call to Action.

var _replay: Button


func build_pages() -> Array:
	var p: Array = []
	var hull: int = GameState.hull
	if hull <= 0:
		p.append({"text": "Die Hülle hält nicht mehr.\n\nStation Aurora ist verloren.", "color": Pal.ALERT})
	elif not GameState.all_done():
		p.append({"text": "Die Zeit ist abgelaufen.\n\nDie Trümmerwolke trifft die Station mit voller Wucht.", "color": Pal.ALERT})
	else:
		p.append({"text": "Ihr habt überlebt.", "color": Pal.OK, "auto": 2.0})
		p.append({"text": "Aber ein Trümmerteil hat die Rückkehrkapsel getroffen.\n\nMorgen fliegt niemand nach Hause."})

	p.append({
		"text": "NEUE SPRACHNACHRICHT\n\n„Hast du meine Nachricht bekommen? Ruf an, wenn du kannst!“\n\n– nicht abgespielt –",
		"color": Pal.ACCENT,
	})

	if GameState.flags.get("kessler_seen", false):
		p.append({"text": "Du hast es selbst gesehen:\njeder Treffer erzeugt neue Trümmer.\n\nDas nennt man Kessler-Syndrom.", "color": Pal.WARN})

	p.append({"text": "Station Aurora gibt es nicht.\n\nDen Müll schon.", "size": 44})

	for f in Facts.ITEMS:
		p.append({"text": Facts.text_for(f), "sub": "Quelle: " + f.source, "size": 30})

	p.append({
		"text": "Der Weltraum ist geteilte Infrastruktur.\nGPS, Wetter, Internet – wir alle hängen davon ab.\n\n[CALL TO ACTION – vom Team ausformulieren]",
		"color": Pal.TEXT,
	})
	return p


func on_end() -> void:
	_replay = Button.new()
	_replay.text = "  Nochmal spielen  "
	_replay.add_theme_font_size_override("font_size", 28)
	_replay.position = Vector2(VIEW.x / 2.0 - 140, VIEW.y - 150)
	_replay.size = Vector2(280, 60)
	_replay.pressed.connect(func(): GameState.goto(GameState.SCENE_INTRO))
	add_child(_replay)
	_replay.grab_focus()
