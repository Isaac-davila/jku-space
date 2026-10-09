# KASKADE – ein 5-Minuten-Spiel über Weltraummüll

Du bist Crew-Mitglied der Raumstation *Aurora*, an deinem letzten Tag vor dem Heimflug.
Ein toter Satellit zerbricht, und eine Trümmerwolke rast auf euch zu. Halte die Station in
fünf Minispielen zusammen. Am Ende zeigt das Spiel, dass der Müll echt ist.

**Engine:** Godot **4.5 stable** (GDScript, 2D, Renderer *Compatibility*).
**Ziel-Plattform:** Browser (Web-Export → itch.io / QR-Code), Querformat, Maus **und** Touch.

---

## Schnellstart (jede Person, Tag 1)

1. **Godot 4.5 stable** herunterladen (Standard-Version, **nicht** .NET/C#): <https://godotengine.org/download/archive/>
   → Alle im Team nutzen **exakt dieselbe Version**, sonst ändert der Editor ständig Dateien.
2. Repo klonen und in Godot öffnen: *Importieren* → `project.godot` auswählen.
3. **F5** startet das ganze Spiel. **F6** startet nur die gerade offene Szene. So testest du dein Minispiel allein.

## Projektstruktur

```
autoload/game_state.gd     Globaler Zustand: Reihenfolge, Countdown, Hülle, Flags, Szenenwechsel
core/minigame.gd           ★ Basisklasse für ALLE Minispiele (die Team-Schnittstelle)
core/story_screen.gd       Text-Seiten mit Schreibmaschinen-Effekt (Intro & Ende)
core/pal.gd, core/ui.gd    Farbpalette und Label-Helfer
data/facts.gd              Echte Fakten fürs Ende (mit Quellen – PRÜFEN!)
scenes/intro/              Cold Open (~30 s)
scenes/hub/                Raumstation: Spieler läuft in blinkenden Raum → Minispiel startet
scenes/minigames/<name>/   Ein Ordner pro Minispiel – gehört EINER Person
scenes/ending/             Ausgang → Sprachnachricht → Fakten → Call to Action
tests/smoke_test.gd        Automatischer Test aller Szenen + kompletter Durchlauf
```

## Ablauf

```
Intro (30 s) → Hub ─┬─ Ausweichmanöver ─┐
                    ├─ Leck abdichten   │  Reihenfolge: GameState.TASK_ORDER
                    ├─ Abwehrlaser      │  Countdown: 3:30 (GameState.TOTAL_TIME)
                    ├─ Funkverbindung   │  Fehlschlag = −25 % Hülle
                    └─ Trümmer einfangen┘
             → Ending (abhängig von Hülle / Zeit / ob der Laser-Twist gesehen wurde)
```

## ★ Die Minispiel-Schnittstelle

Jedes Minispiel ist eine Szene mit `Node2D` als Wurzel und einem Skript, das von `Minigame` erbt:

```gdscript
extends Minigame

func _init() -> void:
	title = "Mein Minispiel"
	instructions = "Kurze Anleitung, max. 1 Zeile"
	time_limit = 20.0

func start() -> void:          # einmalig
	pass

func tick(delta: float) -> void:   # jeden Frame, solange das Spiel läuft
	if gewonnen:
		finish(true)            # oder finish(false, "EIGENER TEXT")

func on_timeout() -> void:     # Zeit abgelaufen (Standard: verloren)
	finish(true)

func _draw() -> void:          # zeichnen; wird automatisch jeden Frame aufgerufen
	draw_stars()
```

**Regeln:**
- **Nicht** `_ready()` oder `_process()` überschreiben, sondern `start()` und `tick()` verwenden.
- Spielfeld ist **1280 × 720**. Klicks kommen auch per Touch an. Nutze `is_click(event)` in `_unhandled_input`.
- Helfer in der Basisklasse: `difficulty()` (0 → 1 über die Zeit), `show_message()`, `draw_debris()`, `draw_text()`, `draw_stars()`.
- Story-Infos für das Ende gehören in `GameState.flags["..."] = true`.
- **Neues Minispiel einbinden:** Eintrag in `GameState.TASKS` und `TASK_ORDER`, Raum in `hub.gd → ROOMS`, Pfad in `tests/smoke_test.gd`.

Die 5 Prototypen in `scenes/minigames/` sind **spielbar, aber hässlich**. Sie sind Startpunkte: Grafiken austauschen, Balancing anpassen, Sound und Juice ergänzen.

## Git-Regeln (wichtig bei 6 Leuten!)

1. **Eine Szene gehört einer Person.** Niemand bearbeitet die `.tscn`/`.gd` einer anderen Person ohne Absprache.
   `project.godot`, `game_state.gd` und `hub.gd` gehören **Rolle 1**.
2. **Branch pro Aufgabe:** `git switch -c minigame/leak-sound`, dann ein Pull Request auf `main`, den eine zweite Person kurz anschaut.
3. **Klein und oft committen**, und **vor dem Arbeiten immer `git pull`**.
4. Der Ordner `.godot/` wird **nie** committet (steht schon in `.gitignore`).
5. Godot-Szenen per Text-Merge zu reparieren ist mühsam. Bei einem Konflikt in einer `.tscn` lieber die eigene Version neu aufbauen.
6. Vor jedem PR den Test laufen lassen:
   ```
   godot --headless --import
   godot --headless --script res://tests/smoke_test.gd
   ```
   Die GitHub Action in `.github/workflows/test.yml` macht das bei jedem Push automatisch.

## Web-Export (für itch.io / QR-Code)

1. Godot → *Editor → Exportvorlagen verwalten* → Vorlagen für 4.5 herunterladen.
2. *Projekt → Exportieren → Hinzufügen → Web*. **„Thread Support“ AUS lassen**, dann läuft es auf jedem Hosting ohne Spezial-Header.
3. Exportieren nach `build/web/index.html` und den Ordner als ZIP auf **itch.io** hochladen (Projektart *HTML*, *„This file will be played in the browser“*).
4. Auf echten Handys im **Querformat** testen: iPhone Safari und Android Chrome.

## Rollen

| # | Rolle | Besitzt |
|---|-------|---------|
| 1 | Lead / Hub & Ablauf | `project.godot`, `autoload/`, `core/`, `scenes/hub/`, Builds, Git-Reviews |
| 2 | Minispiel Ausweichmanöver (+ Funk) | `scenes/minigames/dodge/`, `comms/` |
| 3 | Minispiel Leck | `scenes/minigames/leak/` |
| 4 | Minispiel Abwehrlaser (Kessler-Twist) | `scenes/minigames/laser/` |
| 5 | Minispiel Trümmer einfangen (Netze) | `scenes/minigames/capture/` |
| 6 | Story, Fakten, Grafik & Sound | `scenes/intro/`, `scenes/ending/`, `data/`, `assets/` |

Wer kein GDScript kann, übernimmt Rolle 6 oder Balancing und Playtests. Dann reichen auch 4 Minispiele.

Freie Assets (CC0): <https://kenney.nl/assets> (Space Kit, UI, Sounds), <https://freesound.org> (Lizenz prüfen!).
