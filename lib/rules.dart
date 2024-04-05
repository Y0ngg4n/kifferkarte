import 'package:flutter/material.dart';

class Rules extends StatelessWidget {
  const Rules({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: const Column(
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
            Bitte informiere dich vor Ort und wenn du nicht sicher bist, bubatze nicht öffentlich.
            """,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
