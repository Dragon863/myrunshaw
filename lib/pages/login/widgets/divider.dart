import 'package:flutter/material.dart';

class WordDivider extends StatelessWidget {
  const WordDivider({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 375,
      ),
      child: Row(children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 12.0),
            child: Divider(),
          ),
        ),
        Text(text),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 8.0),
            child: Divider(),
          ),
        ),
      ]),
    );
  }
}
