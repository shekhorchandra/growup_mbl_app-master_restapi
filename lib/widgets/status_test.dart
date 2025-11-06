import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String? status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize = 8,
    this.padding = const EdgeInsets.only(left: 10, right: 10, bottom: 3),
  });

  @override
  Widget build(BuildContext context) {
    final lowerStatus = status?.toLowerCase() ?? '';
    final color = switch (lowerStatus) {
      'approved' => Colors.green,
      'pending' => Colors.orange,
      'rejected' => Colors.red,
      'closed' => Colors.redAccent,
      'matured' => Colors.red,
      'failed' => Colors.red,
      'completed' => Colors.red,
      'running' => Colors.green,
      'investment collecting' => Colors.blue,
      _ => Colors.black54,
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(100),
          bottomRight: Radius.circular(100),
          topRight: Radius.circular(25),
          bottomLeft: Radius.circular(25),),
      ),
      child: Text(
        status ?? 'N/A',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
