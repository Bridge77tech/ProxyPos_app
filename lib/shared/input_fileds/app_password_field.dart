import 'package:flutter/material.dart';

class APPasswordField extends StatelessWidget {
  const APPasswordField({
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
      obscureText: true,
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Enter password",
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        enabledBorder: const UnderlineInputBorder(),
        errorText: errorText,
      ),
    );
  }
}
