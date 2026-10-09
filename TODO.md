# TODO – Kaskade

> Kästchen abhaken (`- [x]`) und mitcommitten. So sieht das ganze Team den Stand.
> Zeitplan ist ein Vorschlag für ca. 4 Wochen. Passt ihn an eure Abgabe an.

## Phase 0 – Setup (Tag 1–2, alle)

- [ ] **Abgabedatum, Bewertungskriterien und Präsentationsform klären** (Ausstellung? Online? Vortrag?) – alle
- [ ] GitHub-Repo anlegen, alle 6 einladen, `main` schützen (nur per Pull Request) – Rolle 1
- [ ] Dieses Projekt als ersten Commit pushen – Rolle 1
- [ ] Alle: Godot **4.5 stable** installieren, klonen, F5 drücken → einmal komplett durchspielen
- [ ] Rollen verteilen (siehe README) und Namen hier eintragen:
  - Rolle 1 Lead/Hub: ____
  - Rolle 2 Ausweichen + Funk: ____
  - Rolle 3 Leck: ____
  - Rolle 4 Laser: ____
  - Rolle 5 Bergung: ____
  - Rolle 6 Story/Art/Sound: ____
- [ ] Gemeinsamen Chat + wöchentlichen 20-Minuten-Termin festlegen – alle
- [ ] **Look festlegen:** 3 Referenzbilder, Farbpalette (`core/pal.gd`), Schriftart – Rolle 6 + alle

## Phase 1 – Alles spielbar (Woche 1)

**Ziel am Ende der Woche:** Komplett durchspielbar, mit Platzhaltergrafik, unter 5 Minuten.

- [ ] Jede:r macht das eigene Minispiel *verständlich ohne Erklärung*. Testen: Mitbewohner:in spielen lassen und nichts sagen.
- [ ] Balancing-Ziel: jedes Minispiel 15–25 s, erster Versuch klappt bei ~70 % der Leute – Rollen 2–5
- [ ] Story-Texte Intro & Ende final schreiben (`intro.gd`, `ending.gd`) – Rolle 6
- [ ] **Alle Fakten in `data/facts.gd` mit Primärquelle prüfen** (ESA Space Environment Report, NASA ODPO) und `verified = true` setzen – Rolle 6
- [ ] Call to Action formulieren: Was soll die Person *nach* dem Spiel tun? (teilen, Petition, Infoseite …) – alle entscheiden, Rolle 6 schreibt
- [ ] Ersten Web-Export bauen und auf itch.io (privat) hochladen – Rolle 1
- [ ] Am Handy testen (Querformat, Touch!) – alle

## Phase 2 – Gut machen (Woche 2–3)

### Grafik & Sound (Rolle 6, Hilfe von allen)
- [ ] Station, Trümmer und Satellit als Sprites (z. B. Kenney *Space Kit*), Platzhalter-`_draw()` ersetzen
- [ ] Hub-Hintergrund: Erde im Fenster, Sterne, Raumnamen-Schilder
- [ ] Sounds: Alarm-Sirene (Loop im Hub), Treffer, Laser, Funkrauschen, Erfolg/Fehlschlag
- [ ] Musik: ruhig im Intro → Spannung im Hub → still im Ende
- [ ] Sprachnachricht im Intro **als echte Audiodatei** einsprechen (macht emotional am meisten aus!)
- [ ] Lizenzen aller Assets in `CREDITS.md` sammeln

### Juice (jede:r im eigenen Minispiel)
- [ ] Screen-Shake bei Treffern, Partikel bei Explosionen/Lecks
- [ ] Kurzer Countdown „3-2-1“ vor Spielstart
- [ ] Erfolg-/Fehlschlag-Animation statt nur Text

### Hub & Ablauf (Rolle 1)
- [ ] Übergänge zwischen Szenen (Fade)
- [ ] Hub-Alarm eskaliert: Licht flackert stärker, je weniger Zeit bleibt
- [ ] Hülle unter 50 % → Risse/Funken im Hub sichtbar
- [ ] Startbildschirm mit „Tippen zum Starten“ (nötig, damit Browser Audio erlaubt!)
- [ ] Optional: Gesamtzeit messen und anzeigen

### Story-Feinschliff (Rolle 6 + alle)
- [ ] Ende: unterschiedliche Texte für gut/mittel/schlecht testen
- [ ] Kessler-Moment im Laser-Spiel: Funkspruch mit Stimme/Sound verstärken
- [ ] Optional: Name des Crewmitglieds/Kindes, kleines Foto im Quartier

## Phase 3 – Testen & Abgabe (Woche 4)

- [ ] **Playtest mit 5+ Fremden.** Notieren: Dauer, wo hängen sie, was sagen sie am Ende? – alle
- [ ] Nach dem Test fragen: *„Was ist Weltraummüll und warum ist er gefährlich?“* Können sie es erklären? → Ziel erreicht
- [ ] Bugs fixen, Schwierigkeit nachjustieren
- [ ] Gesamtdauer prüfen: **≤ 5 Minuten** inkl. Intro & Ende
- [ ] itch.io-Seite öffentlich: Titel, Beschreibung, Screenshots, Credits, Quellen
- [ ] QR-Code + Plakat/Flyer für die Präsentation – Rolle 6
- [ ] Präsentation/Abgabe-Doku: Idee, Zielgruppe, Lernziel, Ablauf, Quellen, Teamaufteilung
- [ ] Finaler Durchlauf auf 3 Geräten (Laptop, iPhone, Android)

## Nice-to-have (nur wenn Zeit bleibt)

- [ ] Automatisches Deployment auf itch.io via GitHub Action (butler)
- [ ] Englische Übersetzung
- [ ] Highscore/Statistik („X % haben die Station gerettet“)
- [ ] Teilen-Button am Ende

## Definition of Done – ein Minispiel ist fertig, wenn …

- [ ] es ohne Erklärung verständlich ist (Anleitung ≤ 1 Zeile)
- [ ] es mit Maus **und** Touch funktioniert
- [ ] es 15–25 Sekunden dauert
- [ ] es eine echte Tatsache über Weltraummüll spürbar macht
- [ ] `tests/smoke_test.gd` grün ist
- [ ] es echte Grafik und Sound hat
