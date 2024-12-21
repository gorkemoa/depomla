import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;

  final IconData? prefixIcon;
  final TextInputType? keyboardType;

  const MyTextfield(
      {super.key,
      this.controller,
      required this.hintText,
      required this.obscureText, this.prefixIcon, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        controller: controller,
              keyboardType: keyboardType,

        obscureText: obscureText,
        decoration: InputDecoration(
                  prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,

            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400)),
            fillColor: Colors.grey.shade300,
            filled: true,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400])),
      ),
    );
  }
}
