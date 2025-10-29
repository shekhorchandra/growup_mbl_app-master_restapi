import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // This adds left and right margin.
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            // First Row
            IntrinsicHeight(
              // Added to make the VerticalDivider visible
              child: Row(
                children: [
                  // Card 1: Fund Disburse
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Icon(
                            FontAwesomeIcons.handHoldingDollar,
                            size: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "৳ 1Billion++",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            "Fund Disburse",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // NEW: Vertical line separator
                  const VerticalDivider(width: 1, thickness: 1),
                  // Card 2: Fund Reimburse
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Icon(
                            FontAwesomeIcons.moneyBillTransfer,
                            size: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "৳ 1Billion++",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            "Fund Reimburse",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // NEW: Horizontal line separator
            const Divider(height: 1, thickness: 1),
            // Second Row
            IntrinsicHeight(
              // Added to make the VerticalDivider visible
              child: Row(
                children: [
                  // Card 3: Farmers Engaged
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Icon(
                            FontAwesomeIcons.wheatAwn,
                            size: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "12K+",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            "Farmers Engaged",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // NEW: Vertical line separator
                  const VerticalDivider(width: 1, thickness: 1),
                  // Card 4: Active Projects
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Icon(
                            FontAwesomeIcons.seedling,
                            size: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "100k Ton++",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            "Farm Produce Sold",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}