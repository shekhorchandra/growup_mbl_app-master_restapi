import 'package:flutter/material.dart';
import 'package:growup_agro/views/todays_income_dialog.dart';
import 'package:growup_agro/views/total_income_dialog.dart';
import 'package:growup_agro/views/total_investment_dialog.dart';
import 'package:growup_agro/views/my_growup_projects_dialog.dart';
import 'package:growup_agro/views/wallet_balance_dialog.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double width;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.width = 160,
  });

  String formatValue(String val) {
    if (val.isEmpty) return "0";
    if (val.length <= 3) return val;
    return val.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  void _handleDialog(BuildContext context) {
    if (title == 'Total Investment') {
      _showDialog(context, const TotalInvestmentHistoryPage());
    } else if (title == "Today's Income") {
      _showDialog(context, const TodaysIncomeDialog());
    } else if (title == "Total Income") {
      _showDialog(context, const TotalIncomeDialog());
    } else if (title == "My Grow Up Projects") {
      _showDialog(context, const MyGrowupProjectsDialog());
    } else if (title == "Wallet Balance") {
      _showDialog(context, const WalletHistoryDialog());
    } else {
      _showAlert(context);
    }
  }

  void _showDialog(BuildContext context, Widget child) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        );
      },
    );
  }

  void _showAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Details'),
          content: Text('Here are more details about "$title".'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Close", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInnerCard(String title, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.green, size: 26),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          formatValue(value),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.4),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: _buildInnerCard(title, value, icon)),
          Positioned(
            top: -20,
            right: -10,
            child: IconButton(
              icon: const Icon(Icons.more_horiz, size: 16),
              padding: EdgeInsets.zero,
              splashRadius: 20,
              onPressed: () => _handleDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
