import 'package:flutter/material.dart';

class APUsernameField extends StatelessWidget {
  const APUsernameField({
    super.key,
    this.errorText,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        hintText: "Username",
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        enabledBorder: const UnderlineInputBorder(),
        errorText: errorText,
      ),
    );
  }
}
