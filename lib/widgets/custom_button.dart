import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double height;
  final FontWeight fontWeight;
  final bool useExtraRoundedCorners;
  final bool isRound;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.backgroundColor = const Color(0xFF8BC34A),
    this.textColor = Colors.white,
    this.borderRadius = 50,
    this.fontSize = 12,
    this.horizontalPadding = 16,
    this.verticalPadding = 0,
    this.height = 24,
    this.fontWeight = FontWeight.w500,
    this.useExtraRoundedCorners = false,
    this.isRound = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || loading;

    final double radiusMultiplier = useExtraRoundedCorners ? 4 : 2;

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey[300] : backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                isRound ? 25 : borderRadius * radiusMultiplier,
              ),
              bottomRight: Radius.circular(
                isRound ? 25 : borderRadius * radiusMultiplier,
              ),
              topRight: Radius.circular(isRound ? 25 : borderRadius / 2),
              bottomLeft: Radius.circular(isRound ? 25 : borderRadius / 2),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) Icon(icon, size: 18, color: textColor),
                  if (icon != null) const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
