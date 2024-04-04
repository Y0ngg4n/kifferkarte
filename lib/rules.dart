import 'package:flutter/material.dart';

class Rules extends StatelessWidget {
  const Rules({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Konsumverbot"),
        Text(
            "1) Der Konsum von Cannabis in unmittelbarer Gegenwart von Personen, die das 18. Lebensjahr noch nicht vollendet haben, ist verboten"),
        Text("2) Der öffentliche Konsum von Cannabis ist verboten:"),
        Row(
          children: [
            Text("1. in Schulen und in "),
            Text(
              "deren Sichtweite,",
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        )
      ],
    );
  }
}
