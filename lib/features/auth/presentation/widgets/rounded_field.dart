// Campo reutilizable (igual al anterior, con onChanged)
import 'package:flutter/material.dart';

class RoundedField extends StatelessWidget {
  final String hint;
  final String? error;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  const RoundedField({
    super.key,
    required this.hint,
    this.obscureText = false,
    this.prefix,
    this.error,
    this.suffix,
    this.keyboardType,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscureText,
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: Colors.black),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        errorText: error,
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,

        fillColor: Colors.white.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF0E4560), width: 1.2),
        ),
      ),
    );
  }
}
