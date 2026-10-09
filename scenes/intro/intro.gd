extends StoryScreen
## Cold Open: max. ~30 Sekunden, dann sofort Alarm. Texte: Rolle 6 (Story).


func build_pages() -> Array:
	return [
		{"text": "STATION AURORA\n412 km über der Erde", "color": Pal.DIM, "auto": 2.5},
		{"text": "Tag 183 von 183.\nMorgen fliegst du nach Hause.", "auto": 3.0},
		{
			"text": "NEUE SPRACHNACHRICHT\n\n„Hey! Morgen holen wir dich ab.\nIch hab dir ein Bild gemalt – du im Weltall!“",
			"color": Pal.ACCENT,
		},
		{"text": "KOLLISIONSALARM", "size": 84, "color": Pal.TEXT, "bg": Color("5a0f18"), "auto": 1.8},
		{
			"text": "Ein ausgedienter Satellit ist zerbrochen.\nSeine Trümmer rasen mit 28.000 km/h auf eure Bahn zu.\n\nHalte die Station zusammen.",
			"color": Pal.TEXT,
		},
	]


func on_end() -> void:
	GameState.reset()
	GameState.goto(GameState.SCENE_HUB)
