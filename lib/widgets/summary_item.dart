import 'package:flutter/material.dart';
import 'package:growup_agro/views/todays_income_dialog.dart';
import 'package:growup_agro/views/total_income_dialog.dart';
import 'package:growup_agro/views/total_investment_dialog.dart';
import 'package:growup_agro/views/my_growup_projects_dialog.dart';
import 'package:growup_agro/views/wallet_balance_dialog.dart';

import 'custom_button.dart';

class SummaryItem {
  final Widget icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });
}

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    super.key,
    required this.items,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    this.bgColor = Colors.white,
    this.valueColor = const Color(0xFFED6E2F),
    this.labelColor = const Color(0xFF9AA3B2),
    this.dividerColor = const Color(0xFF8ED18F),
  }) : assert(items.length >= 2 && items.length <= 4, 'Use 2–4 items for best fit');

  final List<SummaryItem> items;
  final double borderRadius;
  final EdgeInsets padding;
  final Color bgColor;
  final Color valueColor;
  final Color labelColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 16, top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 3,
            ),
          ],
        ),
        padding: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxWidth < 360;
            final iconSize = 24.0;
            final dividerHeight = isTight ? 66.0 : 78.0;

            List<Widget> rowChildren = [];
            for (int i = 0; i < items.length; i++) {
              final item = items[i];

              rowChildren.add(
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: item.onTap ?? () => _handleDialogByLabel(context, item.label),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconTheme(
                          data: IconThemeData(size: iconSize,),
                          child: _wrapIcon(item.icon, iconSize),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: valueColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: labelColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (i != items.length - 1) {
                rowChildren.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      width: 1.5,
                      height: dividerHeight,
                      decoration: BoxDecoration(
                        color: dividerColor.withValues(alpha: .8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: rowChildren,
            );
          },
        ),
      ),
    );
  }

  // === Same dialog behavior as DashboardCard ===
  void _handleDialogByLabel(BuildContext context, String label) {
    if (label == 'Total Investment') {
      _showDialog(context, const TotalInvestmentHistoryPage());
    } else if (label == "Today's Income") {
      _showDialog(context, const TodaysIncomeDialog());
    } else if (label == "Total Income") {
      _showDialog(context, const TotalIncomeDialog());
    } else if (label == "My Grow Up Projects") {
      _showDialog(context, const MyGrowupProjectsDialog());
    } else if (label == "Wallet Balance") {
      _showDialog(context, const WalletHistoryDialog());
    } else {
      _showAlert(context, label);
    }
  }

  void _showDialog(BuildContext context, Widget child) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: child,
      ),
    );
  }

  void _showAlert(BuildContext context, String label) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Details'),
        content: Text('Here are more details about "$label".'),
        actions: [
          CustomButton(
            text: "Close",
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.red,
            textColor: Colors.white,
            height: 32,
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  Widget _wrapIcon(Widget icon, double size) {
    if (icon is Icon) {
      return Icon(icon.icon, size: size,);
    }
    return SizedBox(height: size, width: size, child: FittedBox(child: icon));
  }
}
