import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double height;
  final FontWeight fontWeight;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor = const Color(0xFF8BC34A),
    this.textColor = Colors.white,
    this.borderRadius = 50,
    this.fontSize = 12,
    this.horizontalPadding = 16,
    this.verticalPadding = 0,
    this.height = 24,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? Colors.grey[300]
              : backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(borderRadius * 2), bottomRight: Radius.circular(borderRadius * 2), topRight: Radius.circular(borderRadius / 2), bottomLeft: Radius.circular(borderRadius / 2)),
          ),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 18,
                color: textColor,
              ),
            if (icon != null) const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
