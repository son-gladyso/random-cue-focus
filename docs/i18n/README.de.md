# Random Cue Focus

[简体中文](README.zh-CN.md) · [English](../../README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · Deutsch · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [繁體中文](README.zh-TW.md)

**Mache aus „Ich sollte lernen“ einen konkreten nächsten Schritt und finde nach Ablenkung zurück.**

Random Cue Focus ist eine Flutter-Lernbegleitung mit lokaler Speicherung für iOS und Windows. Lege ein Lernziel und einen kleinen Rückkehrschritt fest und nutze gelegentliche freiwillige Zielprüfungen, ohne den Timer anzuhalten. Lokaler Verlauf und freiwillige Fortschrittsbewertungen helfen beim Rückblick.

Nutze die App neben Lehrbuch, Aufgaben oder Wiederholungsnotizen: Sie unterstützt Planung und Selbstbeobachtung beim Lernen. Version `0.2.0` verwendet seltene, überspringbare Prüfungen, standardmäßig lautlos und ohne Benachrichtigungen.

[Eine Sitzung ausprobieren](#a-session-in-practice) · [Entwicklungsumgebung](#develop) · [Freigabereife](#release-status) · [Häufige Fragen](#common-questions) · [Mitwirken](#help-make-it-easier-to-use-and-verify)

<a id="learning-workflow"></a>

## So begleitet die App eine Lernsitzung

Ersetze „Biologie lernen“ durch „den Abschnitt zur Zellteilung lesen und drei Unterschiede zwischen Mitose und Meiose aufschreiben“. Ergänze „Wenn ich einen fremden Tab öffne, kehre ich zum nächsten Absatz zurück und schreibe einen Vergleich“. Bei einer freiwilligen Prüfung orientierst du dich neu oder liest weiter; anschließend hältst du Fortschritt und Störbelastung fest.

Für Aufgaben benennst du die nächsten Übungen und den Wiedereinstieg, zum Wiederholen die mit eigenen Materialien abzurufenden und zu erklärenden Begriffe. Lesen, Lösen, Abrufen und Prüfen übernimmst du. Der bearbeitbare Rückkehrplan ist kein automatisches Coaching.

<a id="when-it-may-fit"></a>

## Wann es passen könnte

Nutze die App, wenn du mit geringem Aufwand wieder zu deiner eigenen Aufgabe finden möchtest, ohne jede Konzentrationsphase in eine Reihe von Meldungen zu verwandeln.

- Formuliere vor Beginn ein konkretes Ziel.
- Arbeite während einer gelegentlichen, freiwilligen Zielprüfung weiter.
- Wenn du eine Ablenkung bemerkst, nutze eine selbst formulierte Rückkehrhandlung.
- Sieh dir den lokalen Sitzungsverlauf an, ohne ein Konto anzulegen.

Du kannst eine Prüfung überspringen oder nicht wesentliche Prüfungen für eine Sitzung deaktivieren. Ziel ist es, Selbstprüfung zu ermöglichen, ohne Unterbrechungen vorzuschreiben. Ob es dir hilft, lässt sich nicht durch einen Timer oder die Anzahl von Sitzungen belegen.

<a id="a-session-in-practice"></a>

## Eine Sitzung in der Praxis

1. Lege ein Ziel und eine einfache Rückkehrhandlung fest: „Wenn ich abgelenkt werde, dann …“.
2. Starte eine Fokussitzung. Bei Neuinstallationen sind Benachrichtigungen und Vordergrundton ausgeschaltet.
3. Wenn eine Zielprüfung erscheint, wähle „weiter beim Ziel“, „gerade abgelenkt“ oder „überspringen“. Die Fokuszeit läuft weiter.
4. Pausiere, ruhe dich aus oder beende die Sitzung nach Bedarf. Erfasse danach optional den Fortschritt und die Belastung durch Unterbrechungen.
5. Sieh dir den auf deinem Gerät gespeicherten Verlauf an.

Anleitungen zum Bauen und Ausführen stehen unter [Entwicklung](#develop). Eine Geräteaufnahme ist hier noch nicht enthalten. Der [Freigabestatus](#release-status) unterscheidet automatisierte Prüfungen von noch ausstehenden Arbeiten auf echten Geräten.

<a id="what-is-implemented"></a>

## Was implementiert ist

- Ein gemeinsames, getestetes Dart-Paket für Einstellungen, Sitzungsmodelle, Migration, Hinweisplanung, adaptive Belastungsreduktion, freiwillige Crossover-Zuteilung, lokale Ergebniszusammenfassungen, nach Bedingungen geschichtete Datenbereitschaftsprofile, Datenqualitätsprüfungen und datenschutzwahrenden Forschungsexport.
- iOS- und Windows-Apps mit Fokus-/Pause-/Ruhe-/Stopp-Zuständen, Zielprüfungen, lokalem Verlauf und Plattformadaptern.
- Standardwerte bei Neuinstallation: 50 Minuten Fokus, 10 Minuten Ruhe, Prüfintervall von 12–18 Minuten, Antwortfenster von 20 Sekunden, Benachrichtigungen aus, Vordergrundton aus.
- Eindeutige Antworten: „weiter beim Ziel“, „gerade abgelenkt“ oder „überspringen“. Die Fokuszeit läuft während der Prüfung weiter.
- Nicht wesentliche Zielprüfungen können für eine gesamte Sitzung deaktiviert werden. Meldungen über ein Abschweifen führen niemals dazu, dass die Heuristik die Unterbrechungshäufigkeit erhöht.
- Ziel, Ablenkungsauslöser und nächste Rückkehrhandlung sind durch den Nutzer bearbeitbar und werden nicht als universelles Skript behandelt.
- Ausschließlich lokale Speicherung ohne Konto, Server, API-Schlüssel, Werbe-SDK oder entfernte Analysedienste.
- Optionale Antworten nach der Sitzung zu Fortschritt und Unterbrechungsbelastung werden lokal gespeichert und bleiben fehlend, wenn der Nutzer nicht antwortet.
- Ein experimentelles lokales Crossover ist nur nach ausdrücklicher Zustimmung verfügbar. Es wechselt zwischen Sitzungen ohne Prüfungen und mit seltenen Prüfungen, speichert die Zuteilung vor der Exposition dauerhaft, lädt niemals automatisch Daten hoch und kann jederzeit verlassen werden.
- CI für Tests des gemeinsamen Kerns, Analyse/Tests beider Apps, Windows-Release-Build und iOS-Simulator-Build.

Vorhandene Einstellungen und Sitzungsereignisse der Version `0.1.x` werden migriert, statt stillschweigend verworfen zu werden. Schemaversion `6` behält alle früheren Migrationen, die ausdrückliche Studienteilnahme und die Zuteilung pro Sitzung bei. Für neue Studiensitzungen ergänzt sie eine Momentaufnahme des tatsächlichen Aktivierungsstatus der Zielprüfung, des Intervalls und des Antwortfensters. Forschungsexportschema v2 entfernt den absoluten Zuteilungszeitstempel ebenso wie rohe Sitzungs-IDs, Datumsangaben und Freitext. Die adaptive Taktung ist eine deterministische, überprüfbare Heuristik, kein Modell des maschinellen Lernens. Sie wartet mindestens drei Sitzungen und sechs Antworten ab, bevor sie ein Intervall ändert.

<a id="evidence-boundary"></a>
<a id="grenzen-der-evidenz"></a>

## Forschung hinter dem Ablauf

| Studie und Experiment | Befund | Bezug und Grenze |
| --- | --- | --- |
| [Gollwitzer & Sheeran (2006)](https://doi.org/10.1016/S0065-2601(06)38002-1) | Die Metaanalyse zu Wenn-dann-Plänen fand einen mittleren Nutzen in unterschiedlichen Kontexten; neuere verzerrungsrobuste Schätzungen sind kleiner. | Stützt einen selbst verfassten Rückkehrplan; belegt keinen Lernvorteil zufälliger Erinnerungen. |
| [Harkin et al. (2016)](https://doi.org/10.1037/bul0000025) | 138 randomisierte Studien, 19.951 Personen: Mehr Fortschrittsbeobachtung verbesserte die Zielerreichung im Mittel. | Stützt Zielprüfung und Rückblick; untersuchte weder diese App noch ihre Wirkung auf Noten. |
| [Stothart et al. (2015)](https://doi.org/10.1037/xhp0000100) | Benachrichtigungen störten eine Aufmerksamkeitsaufgabe auch ohne Handynutzung. | Stützt stille, freiwillige Prüfungen; bestätigt kein optimales Intervall von 12–18 Minuten. |

**Das sind Befunde zu verwandten Methoden und Prozessen, keine gemessenen Lerngewinne dieser App.** Eine Produktstudie zu Lernergebnissen wurde nicht durchgeführt. Das Intervall ist eine anpassbare Heuristik. Der lokale Crossover vergleicht Bedingungen und Erleben; Ergebnisse liegen nicht vor. Verlauf und Selbstauskunft sind keine Lernnoten.

Abrufübung und verteiltes Lernen sind erforscht, aber die aktuelle App bietet keine Abruffragen, Antwortkorrektur oder geplante Inhaltswiederholung. Der [Lernmodus](../LEARNING_MODE_SPEC.md) ist eine Spezifikation. Eine künftige Studie könnte verzögerte Behaltensleistung, Transfer und Störbelastung vergleichen; sie wurde noch nicht durchgeführt.

Siehe [Quellen und Grenzen](../EVIDENCE_BASE.md), [Messplan](../MEASUREMENT_PLAN.md), [Datenwörterbuch](../DATA_DICTIONARY.md) und [lokales Crossover-Protokoll](../LOCAL_CROSSOVER_PROTOCOL.md).

<a id="common-questions"></a>

## Häufige Fragen

**Was unterscheidet die App von einem Timer mit Pflichtpausen?** Eine Zielprüfung stoppt die Fokuszeit nicht. Du kannst antworten, sie überspringen oder nicht wesentliche Prüfungen für die ganze Sitzung deaktivieren. Ruhe bleibt ein eigener Zustand.

**Werde ich häufiger unterbrochen, wenn ich Ablenkung melde?** Die dokumentierte Heuristik zur Belastungsreduktion erhöht nach Selbstberichten über Abschweifen nicht die Unterbrechungshäufigkeit. Sie ist deterministisch und überprüfbar, kein erlerntes Aufmerksamkeitsmodell.

**Warum höre ich keine Erinnerungen?** Bei Neuinstallationen sind Vordergrundton und externe Benachrichtigungen aus. Prüfe die Einstellungen bewusst, statt eine stille Sitzung als Fehlfunktion zu deuten. Betriebssystemberechtigungen und Hintergrundverhalten müssen ebenfalls plattformspezifisch überprüft werden.

**Kann ich die iPhone-App von Windows aus installieren?** Du kannst dort Dart-Code bearbeiten und testen. Ein echter iPhone-Build und die Signierung benötigen jedoch Xcode auf macOS. Siehe den [iOS-Leitfaden](../../apps/ios/README.md).

**Belegt der Verlauf, dass ich mehr gelernt habe?** Nein. Timerdauer, Abschluss und Selbstberichte sind keine objektiven Lern- oder Produktivitätsergebnisse. Optionale Ergebnisantworten bleiben fehlend, wenn sie nicht beantwortet werden.

**Muss ich am Experiment teilnehmen?** Nein. Das lokale Crossover erfordert ausdrückliche Zustimmung, kann verlassen werden und lädt nicht automatisch Daten hoch. Lies vor der Nutzung das [Protokoll](../LOCAL_CROSSOVER_PROTOCOL.md).

<a id="repository-layout"></a>

## Aufbau des Repositorys

```text
packages/focus_core/  gemeinsames Domänenmodell, Migration, Planer, Ergebnisse, Tests
apps/ios/             Flutter-iOS-App und Adapter für lokale Benachrichtigungen
apps/windows/         Flutter-Windows-App und nativer Toast-/Tray-Adapter
docs/                 Evidenz, Architektur, Datenschutz und Release-Abnahme
.github/               CI, Abhängigkeitsupdates und Beitragsprüfungen
```

<a id="develop"></a>

## Entwicklung

Installiere das aktuelle stabile Flutter SDK und die Werkzeuge für deine Zielplattform. Verwende einen Windows-Entwicklungsrechner für die Windows-App oder macOS mit Xcode für iOS-Builds. Die folgenden Befehle beginnen im Stammverzeichnis des Repositorys. Details stehen in den Plattformleitfäden für [Windows](../../apps/windows/README.md) und [iOS](../../apps/ios/README.md).

```powershell
cd packages\focus_core
dart pub get
dart analyze --fatal-infos
dart test

cd ..\..\apps\windows
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d windows
```

**Erster erfolgreicher Schritt:** Starte einen lokalen App-Build, gib ein Ziel und eine Rückkehrhandlung ein, starte eine Sitzung, pausiere sie und setze sie fort. Prüfe, ob sich der angezeigte Sitzungszustand ändert. Dies ist ein grundlegender lokaler Durchlauf, keine Abnahme des Sperrbildschirm-, Standby-/Aufwach- oder nativen Benachrichtigungsverhaltens.

Führe die entsprechenden Analyse-/Testbefehle in `apps/ios` aus. iOS-Builds benötigen Xcode auf macOS. Signierung und Benachrichtigungsprüfung auf echten Geräten erfordern eine Apple-Entwicklungsumgebung.

<a id="release-status"></a>

## Freigabestatus

| Freigabekriterium | Status |
|---|---|
| Tests des gemeinsamen Kerns | In CI automatisiert |
| iOS-Analyse/-Tests | In CI automatisiert |
| iOS-Simulator-Build | In CI automatisiert |
| Windows-Analyse/-Tests/-Release-Build | In CI automatisiert |
| Benachrichtigungslebenszyklus auf echtem iPhone | **Ausstehend** |
| Toasts, Benachrichtigungsassistent, Standby/Aufwachen und Tray-Verhalten auf echtem Windows-Gerät | **Ausstehend** |
| Wirksamkeitsstudie auf Produktebene | **Nicht durchgeführt** |

Dies ist eine technische Verbesserung mit A+-Kandidatenstatus, keine Erklärung einer A+-Freigabe. Die Release-Abnahme bleibt blockiert, bis die Prüfungen aus [Geräteabnahme](../DEVICE_ACCEPTANCE.md) auf konkret benannter Hardware ausgeführt und die Belege angehängt wurden.

<a id="privacy-and-security"></a>

## Datenschutz und Sicherheit

Siehe [Datenschutz](../PRIVACY.md), [Sicherheitsrichtlinie](../../SECURITY.md) und [Architektur](../ARCHITECTURE.md). Sämtliche derzeitigen Produktdaten verbleiben auf dem Gerät und können durch Löschen des Verlaufs oder Deinstallieren der App entfernt werden.

<a id="help-make-it-easier-to-use-and-verify"></a>

## Nutzung und Überprüfung gemeinsam vereinfachen

Klar eingegrenzte Beiträge sind willkommen, insbesondere zu Barrierefreiheit, Migrationssicherheit, plattformspezifischem Benachrichtigungsverhalten und verständlicheren Interaktionen bei Zielprüfungen.

- Beginne mit [CONTRIBUTING.md](../../CONTRIBUTING.md) und den Tests des Moduls, das du ändern möchtest.
- Gemeinsames Verhalten bleibt in `packages/focus_core`, plattformspezifisches Verhalten im jeweiligen App-Adapter.
- Verwende für Gerätetests [DEVICE_ACCEPTANCE.md](../DEVICE_ACCEPTANCE.md) und dokumentiere Hardware, Softwareversion, Commit, Schritte und beobachtetes Ergebnis.
- Beschreibe sowohl die ausgeführten als auch die nicht möglichen Prüfungen.

| Zu verbessernder Bereich | Einstiegspunkt | Beizufügende Überprüfung |
| --- | --- | --- |
| Hinweisplanung und Einstellungsmigration | `packages/focus_core` | Domänentests, Migrationseingaben und unveränderte Datenschutz-/Standardwertverträge. |
| iOS-Sitzungsoberfläche oder Benachrichtigungen | `apps/ios/lib`, `apps/ios/test` | Analyse-/Widget-Tests; Prüfungen auf echten Geräten separat nennen. |
| Windows-Steuerung, Persistenz oder Tray-Verhalten | `apps/windows/lib`, `apps/windows/test` | Relevante Controller-/Repository-Tests und ausdrückliche Plattformbelege. |
| Produkterklärungen | `docs/EVIDENCE_BASE.md`, `docs/PRIVACY.md` | Übereinstimmung mit tatsächlichen Standardwerten und der Grenze zwischen Evidenz und Aussagen. |

Berücksichtige bei Oberflächenänderungen auch wiederholte Aktionen, Pause/Fortsetzen, eine übersprungene Prüfung und unterbrochene Sitzungen. Markiere ein Freigabekriterium für echte Geräte nicht allein aufgrund eines Simulators oder eines nachgebildeten Adapters als abgeschlossen.

Öffne ein [Issue](https://github.com/son-gladyso/random-cue-focus/issues), um eine größere Änderung zu besprechen. Reiche keine persönlichen Ziele, Verläufe oder Forschungsexporte als öffentliche Beispiele ein. Beiträge müssen freiwillige Prüfungen, Datenschutz und die Unterscheidung zwischen einer implementierten Heuristik und einem nachgewiesenen Nutzen erhalten.
