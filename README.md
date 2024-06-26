# Kifferkarte

[![Github releases](docs/images/badge_github.png)](https://github.com/Y0ngg4n/kifferkarte/releases)
[![Google Play download](docs/images/googleplay.png)](https://play.google.com/store/apps/details?id=pro.obco.kifferkarte)

> Die Karte ist aktuell im Beta Status. Fehler sind zu erwarten

[DE]: Die Kifferkarte bietet ähnlich zur Bubatzkarte einen Überblick über die Konsumzonen, bietet jedoch eine zusätzliche unterstützung für Positionen und vibriert wahlweiße und benachrichtigt beim verlassen und eintreten von Zonen.
Die Kifferkarte beinhaltet auch die Fußgängerzonen und verhält sich der Uhrzeit entsprechend.

Die Kifferkarte ist eventuell nicht korrekt und soll eine Übersicht darstellen. Die Kifferkarte übernimmt jedoch keine Verantwortung für dein Handeln. Du musst immer noch selbst prüfen.

---


> The Map is currently in Beta state. Errors are expected

[EN]: The Kifferkarte offers an overview of the consumption zones, similar to the Bubatzkarte, but offers additional support for positions and vibrates white and alerts when leaving and entering zones.
The box card also includes the pedestrian zones and behaves according to the time.

The Kifferkarte may not be correct and should be an overview. However, the box card does not take responsibility for your actions. You still have to check yourself.

## Features
[DE]:
* Vibrieren und Benachrichtigung wenn Zonenänderung
* Automatisches freischalten von Fußgängerzonen, wenn außerhalb des Zeitfensters
* Zeigt Umrisse von Gebäuden an, sodass man besser nach Eingängen suchen kann
* Zeigt die 100 Meter Umkreis an
* Farblich unterschiedliche Pois je nach Typ
* Zusammenfassung der Gesetzeslagen

## Datenschutz
Die Kifferkarte sammelt keinerlei Daten.
Es gibt in der gehosteten Version einen Serverlog aber das war es auch.

## Datenherkunft
Folgende Services werden benutzt:
[Openstreetmap Tile Server](https://operations.osmfoundation.org/policies/tiles/) 
[Nomatim Server](https://operations.osmfoundation.org/policies/nominatim/)
[Overpass API](https://overpass-api.de/)

## Hosting
[EN]: To host your own version of the Kifferkarte you can use the docker containers. 
The container can be found in the [Repository Github Container Registry](https://github.com/Y0ngg4n/kifferkarte/pkgs/container/kifferkarte) and on [Dockerhub](https://hub.docker.com/r/yonggan/kifferkarte)

The port is `80`.

## Screenshots
![Phone Screenshot](fastlane/metadata/android/de-DE/images/phoneScreenshots/Screenshot_2024-04-12-01-00-45-172_pro.obco.kifferkarte.jpg)
![Phone Screenshot](fastlane/metadata/android/de-DE/images/phoneScreenshots/Screenshot_2024-04-12-01-00-45-172_pro.obco.kifferkarte.jpg)

## Contribute

Contributions are very welcome.
To contribute i recommend to use the flake.nix with the Nix package manager.
Just make a PR or ask for help in a PR.

## Help needed and TODO
- Currently is tile caching on the web version only with MemoryCaching. I need help with integrating drift in flutter web for better caching
- Fdroid builds are currently not working as the exclude of the gms modules needed for fdroid are not recursive
