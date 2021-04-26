import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Lyrics extends StatelessWidget {
  final String past;
  final String future;

  const Lyrics({required this.past, required this.future});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          this.past,
          style: TextStyle(color: Colors.white, fontSize: 27),
        ),
        Text(
          this.future,
          style: TextStyle(color: Colors.red, fontSize: 27),
        )
      ],
    );
  }
}
