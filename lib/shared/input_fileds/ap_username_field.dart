import 'package:flutter/material.dart';

class APUsernameField extends StatelessWidget {
  const APUsernameField({
    super.key,
    this.errorText,
    this.onChanged,
    this.controller,
  });

  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Username",
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        enabledBorder: const UnderlineInputBorder(),
        errorText: errorText,
      ),
    );
  }
}
