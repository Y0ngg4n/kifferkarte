import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Rules extends StatelessWidget {
  const Rules({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Konsumverbot",
            style: TextStyle(fontSize: 20),
          ),
          Text(
            """1) Der Konsum von Cannabis in unmittelbarer Gegenwart von Personen, die das 18. Lebensjahr noch nicht vollendet haben, ist verboten
2) Der öffentliche Konsum von Cannabis ist verboten:
        1. in Schulen und in deren Sichtweite,
        2. auf Kinderspielplätzen und in deren Sichtweite,
        3. in Kinder- und Jugendeinrichtungen und in deren Sichtweite,
        4. in öffentlich zugänglichen Sportstätten und in deren Sichtweite,
        5. in Fußgängerzonen zwischen 7 und 20 Uhr und
        6. innerhalb des befriedeten Besitztums von Anbauvereinigungen und in deren Sichtweite
            """,
            textAlign: TextAlign.left,
          ),
          Text(
            "Daten und Korrektheit",
            style: TextStyle(fontSize: 20),
          ),
          Text(
            """Die Kifferkarte übernimmt keine Verantwortung für dein Handeln und hat keine Garantie auf Korrektheit.
Bitte informiere dich vor Ort und wenn du nicht sicher bist, kiffe nicht öffentlich.
Es werden keine persönlichen Daten gespeichert. Es gibt einen Serverlog aber das ist auch alles. Es werden Daten aus Openstreetmap, Overpass und Nomatim geladen.
Es werden ausschließlich die Öffentlichen Instanzen benutzt.
            """,
            textAlign: TextAlign.left,
          ),
          Text(
            "Anleitung",
            style: TextStyle(fontSize: 20),
          ),
          Text(
            """Zoome mit den Fingern oder den Tasten in die Karte bis du Kreise siehst.
Oder drücke auf das Navigationssymbol rechts unten und du springst direkt zu dir und folgst deiner Position mit der Karte.
Verwende die zweite Taste von unden rechts um die Vibration ein und auszuschalten.
Dadurch wirst du sofort über neue Zonenbegegnungen informiert.
Suche mit der Lupe nach Orten. Drehe die Karte nach deiner Gyroskopausrichtung mit der zweiten Taste links oben
und gehe zum Lockscreen durch das Schloss, da Android keine richtigen Backgroundlocations zulässt(Bitte PM wenn Idee).
Die roten Zonen zeigen die 100 Meter an. Die gelben Polygone eine Fußgängerzone zwischen 7 und 20 Uhr und die grünen Polygone Fußgängerzonen außerhalb dieser Zeiten.
Die orangenen Polygone zeigen die Gebäudeumrisse an.
            """,
            textAlign: TextAlign.left,
          ),
          Text(
            "FAQ",
            style: TextStyle(fontSize: 20),
          ),
          Text(
            """Warum muss ich erst reinzomen um die Zonen zu sehen? Die Bubatzkarte kann das doch auch so?
Die Bubatzkarte benutzt eine andere Technologie. Die Bubatzkarte verwendet vorgerenderte Kartenbereiche und benutzt einen eigens dafür entwickelten Tileserver. Die Kifferkarte benutzt die Overpass API und um diese nicht zu sehr zu belasten, beschränken wir das Zoom Level. Ansonsten würde es mehrere Minuten dauern um alle Punkte zu laden.

Warum finde ich Zonen auch im Ausland?
Die Kifferkarte überprüft nicht ob sich die Einschränkenden Plätze im Ausland befinden. Ich hatte mehrere Tests gemacht, jedoch keinen Zuverlässigen Weg gefunden nach dem Land zu filtern ohne nicht mehr alle Daten in Deutschland zu erhalten.

Was mache ich, wenn Daten fehlen?
Sollten Daten fehlen, gibt es 2 Möglichkeiten:
Die Daten sind nicht in OpenStreetMap verzeichnet -> Füge die Daten zu OpenStreetMap hinzu.
Die Kifferkarte verarbeitet die Daten falsch -> kontaktiere mich und ich werde versuchen das Problem zu beheben.
            """,
            textAlign: TextAlign.left,
          ),
          Text("Kontakt/Links", style: TextStyle(fontSize: 20)),
          GestureDetector(
              child: Text("Matrix: yonggan@matrixapp.chat",
                  style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue)),
              onTap: () => launchUrlString(
                  "https://matrix.to/#/@yonggan:matrixapp.chat")),
          GestureDetector(
            child: Text("Email: admin@obco.pro",
                style: TextStyle(
                    decoration: TextDecoration.underline, color: Colors.blue)),
            onTap: () => launchUrlString("mailto:admin@obco.pro"),
          ),
          GestureDetector(
            child: Text("Fedi: @yonggan@iceshrimp.de",
                style: TextStyle(
                    decoration: TextDecoration.underline, color: Colors.blue)),
            onTap: () => launchUrlString("https://iceshrimp.de/@Yonggan"),
          ),
          GestureDetector(
            child: Text("Source code: https://github.com/Y0ngg4n/kifferkarte",
                style: TextStyle(
                    decoration: TextDecoration.underline, color: Colors.blue)),
            onTap: () =>
                launchUrlString("https://github.com/Y0ngg4n/kifferkarte"),
          ),
        ],
      ),
    );
  }
}
