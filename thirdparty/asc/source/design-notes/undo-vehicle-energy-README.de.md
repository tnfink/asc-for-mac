# Undo stellt die Fahrzeug-Energie wieder her

Patch für das ursprüngliche Advanced Strategic Command, Stand
`741c21609b7945297f20caa90a2ea9823b991b71`
(https://github.com/ValHaris/asc-hq).

Lizenz: GPL-2.0-or-later, wie ASC selbst. Der Godot-Port bleibt unverändert;
dieser Patch ist nur für den Originalquelltext.

Anlass, Martins Formulierung: „5.2a: rückgängig sollte den exakt identischen
Zustand wiederherstellen, also auch Energie ins Vehicle.“

## Fehler

`ConsumeResource::undoAction` gibt die verbrauchte Menge mit `putResource`
zurück. `Vehicle::putResource` speichert Energie nicht und liefert 0
(Kommentar im Quelltext: „no energy storable“). Energie, die direkt aus dem
Fahrzeugtank kam, fehlt nach dem Undo.

Kommt die Energie über das Ressourcennetz, ist das ein zweiter Weg. Der
Verbrauch nimmt zuerst aus Gebäuden und danach aus einem laufenden
Matter-Converter. Die Rückgabe (`PutResource`) füllt Gebäude und, im globalen
Modus, den Spielerpool. Fahrzeugtanks werden dabei nicht beschrieben. Die
Energie aus dem Fahrzeug bleibt weg, das Gebäude endet höher.

Beispiel mit denselben Zahlen wie Einheit 285798: Tank 2000, Verbrauch 833,
nach dem bisherigen Undo bleibt 1167.

`Vehicle::putResource` für Energie bleibt bewusst wie bisher. Eine Änderung
dort würde Vorwärtstransfers und Replays verschieben und das Fahrzeug trotzdem
nicht bevorzugen, solange Gebäude noch Platz haben.

## Änderung

Solange `ConsumeResource::runAction` läuft, merkt sich der Code jede
tatsächlich ausgeführte Änderung: Fahrzeugtank, Gebäudelager, globaler Pool,
Tribut verfügbar und Tribut gezahlt. Undo addiert genau diese Beträge zurück,
in umgekehrter Reihenfolge. Es gibt keine zweite Gutschrift über `putResource`.

Die Liste steht nicht im Befehlsstrom. `ConsumeResource` bleibt Version 1,
`writeData` ist unverändert. Für einen Spielstand mitten im Zug hängt die
Liste am bestehenden Properties-Beutel, Schlüssel `asc.resourceUndoLedger`.
`GameMap::write` legt sie ab, `GameMap::read` setzt sie wieder an die
`ConsumeResource`-Knoten in derselben Baumreihenfolge. Nach `breakUndo`, wenn
keine solche Aktion mehr offen ist, wird der Schlüssel entfernt.

Fehlt die Liste (Speicherstand von vor dem Patch, oder der Eintrag lässt sich
nicht lesen), läuft das bisherige `putResource`.

## Anwenden

Im Quellbaum von `741c21609`:

```
patch -p1 < undo-vehicle-energy-741c21609.patch
```

Geprüft: `patch -p1 --dry-run` auf einem frischen Archiv genau dieses Commits
endet mit Status 0.

Die später für den Port notierten Commits `21803ec7`, `1a46bfac` und
`8aeb89d9` ändern die hier angefassten Dateien nicht. Ob der Patch auf einem
Baum mit genau diesen drei zusätzlichen Commits sauber liegt, ist damit
plausibel und hier nicht durch einen Merge geprüft worden.

Neu gebaut wird wie gewohnt. Der Regressionstest hängt an `make` über
`source/unittests/Makefile.am` und `Makefile.in`.

## Tests

Umgebung: der Quellbaum von `741c21609`, `./configure --disable-extradata`,
`unittester` aus `unittester/` mit `SDL_VIDEODRIVER=dummy`. Karte
`unittest-repair.map`. Ein Matter-Converter-Typ mit Tank 2000/500/8000 erzeugt
per `endRound` 2000 Energie. `putResource` von 50 Energie liefert weiterhin 0.

Vor dem Fix, derselbe Test, Exit 2:

```
direct undo energy: got 1167, expected 2000
```

Die übrigen Testgruppen liefen davor durch. Der Netzteil des neuen Tests kam
nicht mehr dran, weil der direkte Teil abbrach.

Nach dem Fix, kompletter `./unittester`, Exit 0:

```
unittests completed successfully
```

Der neue Test prüft:

- direkter Verbrauch 833 Energie, 30 Material, 10 Treibstoff; Undo stellt
  2000, das ursprüngliche Material und den ursprünglichen Treibstoff her;
  erneutes Ausführen und ein zweites Undo ebenso
- Netz: Gebäude gibt 100 Energie und 40 Material, der Generator daneben die
  restlichen 833 Energie (2000 auf 1167); Undo stellt Gebäude 100/200 und
  Generator 2000 her, Treibstoff bleibt, Material des Generators bleibt 80
- globaler Pool: 100 Energie aus `bi_resource`, 833 aus dem Generator;
  Gebäudelager bleibt unberührt; Undo stellt Pool und Tank her
- der geschriebene `ConsumeResource`-Strom ist mit und ohne Liste bytegleich;
  `readFromStream` liest ihn
- die Liste übersteht `Properties::write`/`read`; Undo über den
  `ActionContainer` stellt danach 2000 Energie sowie Material und Treibstoff
  her

Das ist ein Quelltext-Regressionstest. Ein Replay des Spielstands
`ww1OesterreichUngarnR18.sav` (6 738 978 Bytes) ist hier nicht gelaufen; die
Datei lag nicht vor. Die Verteilung in diesem Spielstand, einschliesslich der
früher notierten Materialdifferenz am Gebäude (216,367), ist damit nicht
erneut gemessen. Ein bereits gespeicherter Stand, in dem das Undo die 833
schon verloren hat, enthält die Aktion nicht mehr auf dem Stapel und wird von
dem Patch nicht nachträglich korrigiert.

## Replay und alte Spielstände

Ein festgeschriebener Replay-Befehl führt `Command::redo` aus. Das löscht die
Kinder und ruft `go()` neu auf. Die Liste wird dabei neu aufgezeichnet und
muss im Replay-Byte-Strom nicht stehen. Neue Replays bleiben für ein ASC ohne
diesen Patch lesbar. Undo in einem Spielstand von vor dem Patch hat keine
Liste und behält die bisherige, unvollständige Rückerstattung.

Ein Spielstand mitten im Zug kann den zusätzlichen Properties-Eintrag
enthalten. Ein älteres ASC lässt unbekannte Properties liegen und behält beim
Undo das alte Verhalten. Ein Zugende nach `breakUndo` schreibt den Eintrag
nicht, solange keine offene `ConsumeResource` mehr eine Liste hat.

## Port

`port/asc-source.patch` und der mitgelieferte Kern sind nicht geändert. Dort
bleibt das bisherige Undo, bis der Patch im Original angenommen und der
Snapshot neu gezogen wird.
