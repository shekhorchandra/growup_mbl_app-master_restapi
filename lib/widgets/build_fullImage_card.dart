import 'dart:ui';
import 'package:flutter/material.dart';

class FullImageCard extends StatelessWidget {
  final String title;
  final String value;
  final String imagePath;
  final VoidCallback? onMorePressed;
  final double height;

  const FullImageCard({
    super.key,
    required this.title,
    required this.value,
    required this.imagePath,
    this.onMorePressed,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 🔹 Background image
            Image.asset(imagePath, fit: BoxFit.cover),

            // 🔹 Blur overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),

            // 🔹 Centered content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳ $value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 3-dot action button
            Positioned(
              top: -6,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                splashRadius: 20,
                onPressed: onMorePressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
