class_name Facts
## Echte Fakten fürs Ende. ROLLE 6: Jede Zahl vor der Abgabe mit Quelle prüfen
## und "verified" auf true setzen. Ungeprüfte Fakten sind mit (?) markiert im Spiel.

const ITEMS := [
	{
		"text": "Trümmer im Erdorbit fliegen mit rund 28.000 km/h –\nschon ein zentimetergroßes Teil kann eine Raumstation beschädigen.",
		"source": "Bahngeschwindigkeit im niedrigen Erdorbit ≈ 7,8 km/s",
		"verified": false,
	},
	{
		"text": "Über eine Million Teile größer als 1 cm\nkreisen laut Schätzungen um die Erde.",
		"source": "ESA Space Environment Report – aktuelle Ausgabe prüfen!",
		"verified": false,
	},
	{
		"text": "2009 kollidierten zum ersten Mal zwei Satelliten:\nIridium 33 und Kosmos 2251. Tausende neue Trümmer entstanden.",
		"source": "NASA Orbital Debris Quarterly News – prüfen",
		"verified": false,
	},
	{
		"text": "2021 zerschoss ein Raketentest einen alten Satelliten.\nDie ISS-Crew musste Schutz in ihren Kapseln suchen.",
		"source": "Russischer ASAT-Test, Kosmos 1408, Nov. 2021 – prüfen",
		"verified": false,
	},
	{
		"text": "Die ISS muss regelmäßig Trümmern ausweichen –\nschon dutzende Male seit ihrem Start.",
		"source": "NASA – genaue Anzahl prüfen",
		"verified": false,
	},
]


static func text_for(item: Dictionary) -> String:
	return item.text if item.get("verified", false) else item.text + " (?)"
