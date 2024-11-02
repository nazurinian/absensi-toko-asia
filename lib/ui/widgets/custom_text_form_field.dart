import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final bool autoValidate;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool isPassword;
  final Color iconColor;
  final Color errorColor;
  final int? maxLines;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.autoValidate = false,
    this.validator,
    this.onChanged,
    this.isPassword = false, // Default to false for non-password fields
    this.iconColor = Colors.red,
    this.errorColor = Colors.red,
    this.maxLines = 1,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword ? _obscureText : false,
      validator: widget.validator ??
          (!widget.isPassword
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                }
              : (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan kata sandi';
                  } else if (value.length < 8) {
                    return 'Kata sandi minimal 8 karakter';
                  }
                  return null;
                }),
      autovalidateMode: widget.autoValidate
          ? AutovalidateMode.disabled
          : AutovalidateMode.onUserInteraction,
      onChanged: widget.onChanged,
      keyboardType: widget.isPassword
          ? TextInputType.visiblePassword
          : TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        labelText: widget.labelText,
        // labelStyle: widget.focusNode != null
        //     ? (widget.focusNode!.hasFocus
        //         ? const TextStyle(color: Colors.black)
        //         : const TextStyle(color: Colors.blueAccent))
        //     : const TextStyle(color: Colors.black),
        labelStyle: const TextStyle(color: Colors.blueAccent),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: widget.iconColor)
            : null,
        // errorStyle: TextStyle(color: widget.errorColor, fontSize: 18.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.0),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColorLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.0),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.blueAccent,
          ),
          borderRadius: BorderRadius.all(Radius.circular(9.0)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.0),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
      maxLines: widget.maxLines,
    );
  }
}
