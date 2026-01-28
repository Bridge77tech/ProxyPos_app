import 'package:flutter/material.dart';

class APPasswordField extends StatelessWidget {
  const APPasswordField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
            hintText: "Enter password",
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            enabledBorder: UnderlineInputBorder()
        )
    );;
  }
}
