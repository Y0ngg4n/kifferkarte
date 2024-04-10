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
            """Die Kifferkarte übernimmt keine Verantwortung für dein Handeln und hat keine Gewährleistung auf Korrektheit.
Bitte informiere dich vor Ort und wenn du nicht sicher bist, kiffe nicht öffentlich.
Es werden keine persönlichen Daten gespeichert. Es gibt einen Serverlog aber das ist auch alles. Es werden Daten aus Openstreetmap, Overpass und Nomatim geladen.
Es werden ausschließlich die Öffentlichen Instanzen benutzt. Sollten Daten fehlen, trage diese bitte in OpenStreetMap ein, dann sollten sie auch hier auftauchen.
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
