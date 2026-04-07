import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../generated/assets.dart';

class APPasswordField extends StatefulWidget {
  const APPasswordField({
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
  State<APPasswordField> createState() => _APPasswordFieldState();
}

class _APPasswordFieldState extends State<APPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: _obscure,
      focusNode: widget.focusNode,
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        hintText: "Enter password",
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        enabledBorder: const UnderlineInputBorder(),
        errorText: widget.errorText,
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Padding(
            padding: EdgeInsets.all(8.r),
            child: _obscure
                ? Image.asset(Assets.iconsVisibilityOn, scale: 3.5)
                : const Icon(Icons.visibility_off_outlined, size: 20),
          ),
        ),
      ),
    );
  }
}
