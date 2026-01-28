import 'package:flutter/material.dart';

class APUsernameField extends StatelessWidget {
  const APUsernameField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: "Username",
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        enabledBorder: UnderlineInputBorder()
      )
    );
  }
}
