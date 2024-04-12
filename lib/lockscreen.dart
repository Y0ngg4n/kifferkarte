import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';

class Lockscreen extends StatefulWidget {
  const Lockscreen({super.key});

  @override
  State<Lockscreen> createState() => _LockscreenState();
}

class _LockscreenState extends State<Lockscreen> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.black,
        child: Center(
          child: SlideAction(
            text: "Schlittern um zu entschlüsseln",
            onSubmit: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}
