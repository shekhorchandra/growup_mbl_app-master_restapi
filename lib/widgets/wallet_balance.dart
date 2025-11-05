import 'package:flutter/material.dart';

import 'dart:async';

class WalletBalance extends StatefulWidget {
  const WalletBalance({
    super.key,
    required this.walletBalance,
    this.autoHideAfter = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 280),
  });

  final String walletBalance;
  final Duration autoHideAfter;
  final Duration animationDuration;

  @override
  State<WalletBalance> createState() => _WalletBalanceState();
}

class _WalletBalanceState extends State<WalletBalance> {
  bool _revealed = false;
  Timer? _hideTimer;

  void _showBalance() {
    if (_revealed) return; // already showing
    setState(() => _revealed = true);

    // auto hide after the configured duration
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.autoHideAfter, () {
      if (mounted) setState(() => _revealed = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showBalance,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 176,
        padding: const EdgeInsets.only(left: 8, right: 12, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon box
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Image.asset(
                'assets/icons/img_5.png',
                fit: BoxFit.cover,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),

            // Animated label/balance
            Expanded(
              child: AnimatedSwitcher(
                duration: widget.animationDuration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  // Combine slide + fade for a nicer feel
                  final offsetTween = Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(offsetTween),
                      child: child,
                    ),
                  );
                },
                child: _revealed
                    ? Text(
                  widget.walletBalance,
                  key: const ValueKey('balance'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    : Text(
                  'Tap for wallet balance',
                  key: const ValueKey('hint'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
