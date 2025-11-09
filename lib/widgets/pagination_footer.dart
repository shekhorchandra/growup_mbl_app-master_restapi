import 'package:flutter/material.dart';
import 'custom_button.dart'; // make sure to import your CustomButton file

class PaginationFooter extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int rowsPerPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationFooter({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.rowsPerPage,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / rowsPerPage).ceil();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -2),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomButton(
              text: "Previous",
              height: 30,
              backgroundColor: Colors.green[300]!,
              textColor: Colors.white,
              onPressed: currentPage > 1 ? onPrevious : null,
            ),
            Text(
              'Page $currentPage of $totalPages',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            CustomButton(
              text: "Next",
              height: 30,
              backgroundColor: Colors.green[300]!,
              textColor: Colors.white,
              onPressed: currentPage < totalPages ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}
