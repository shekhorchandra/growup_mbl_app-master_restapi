import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String title;
  final String? value;
  final double fontSize;
  final bool showDivider;
  final TextStyle? style;
  final FontWeight fontWeight;

  const InfoRow({
    super.key,
    required this.title,
    required this.value,
    this.fontSize = 14,
    this.showDivider = true,
    this.fontWeight = FontWeight.w600,
    this.style,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              "$title:",
              style: TextStyle(fontWeight: fontWeight, fontSize: fontSize),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value ?? "N/A",
              textAlign: TextAlign.right,
              style: style ?? const TextStyle(),
            ),
          ),
        ],
      ),
      showDivider? const Divider(thickness: 0.5, color: Color(0xFFE0E0E0)) : const SizedBox(),
    ],
  );
}
