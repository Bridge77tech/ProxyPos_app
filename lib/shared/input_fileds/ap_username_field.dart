import 'package:flutter/material.dart';

class APUsernameField extends StatelessWidget {
  const APUsernameField({
    super.key,
    this.errorText,
    this.onChanged,
    this.focusNode,
  });

  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;


  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
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
