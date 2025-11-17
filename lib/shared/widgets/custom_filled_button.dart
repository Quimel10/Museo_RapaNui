import 'package:flutter/material.dart';

class CustomFilledButton extends StatelessWidget {
  final void Function()? onPressed;
  final String text;
  final Color? buttonColor;

  const CustomFilledButton({
    super.key,
    this.onPressed,
    required this.text,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(20);

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: buttonColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: radius,
            bottomRight: radius,
            topRight: radius,
            topLeft: radius,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
