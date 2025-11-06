import 'package:flutter/material.dart';
import 'package:growup_agro/widgets/status_test.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_button.dart';

class ProjectCard extends StatelessWidget {
  final String projectName;
  final String businessType;
  final String? imageUrl;
  final String projectDuration;
  final String startDate;
  final String endDate;
  final String roiStartDate;
  final double investmentGoal;
  final double minInvestment;
  final double raised;
  final double inWaiting;
  final String roi;
  final String statusText;
  final bool showInvestNow;
  final bool showUpcoming;
  final String? investmentStartDate;
  final bool isLoading;
  final VoidCallback? onInvestNowPressed;

  /// 🔹 Optional custom button text (defaults to "Invest Now")
  final String buttonText;

  const ProjectCard({
    super.key,
    required this.projectName,
    required this.businessType,
    this.imageUrl,
    required this.projectDuration,
    required this.startDate,
    required this.endDate,
    required this.roiStartDate,
    required this.investmentGoal,
    required this.minInvestment,
    required this.raised,
    required this.inWaiting,
    required this.roi,
    required this.statusText,
    required this.showInvestNow,
    required this.showUpcoming,
    this.investmentStartDate,
    this.isLoading = false,
    this.onInvestNowPressed,

    /// Default label text for the button
    this.buttonText = "Invest Now",
  });

  String _formatAmount(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatted = NumberFormat('#,##0').format(number);
    return '$formatted Tk';
  }

  TableRow _buildTableRow(String label, String value) {
    final bool isStatusRow = label.toLowerCase() == 'status';

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: isStatusRow
              ? Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(status: value),
          )
              : Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== IMAGE + DETAILS ====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Image + Name + Button
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          imageUrl != null && imageUrl!.isNotEmpty
                              ? Image.network(
                            imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/placeholder1.jpg',
                              fit: BoxFit.contain,
                            ),
                          )
                              : Image.asset(
                            'assets/images/placeholder1.jpg',
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 6),
                          Text(
                            projectName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),

                          // 🔹 Invest Now Button BELOW image
                          if (showInvestNow) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                text: isLoading ? "Loading..." : buttonText,
                                backgroundColor: const Color(0xFF2E7D32),
                                textColor: Colors.white,
                                height: 24,
                                fontSize: 12,
                                borderRadius: 8,
                                isRound: true,
                                onPressed: isLoading ? null : onInvestNowPressed,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Right: Table Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(4),
                        },
                        defaultVerticalAlignment:
                        TableCellVerticalAlignment.middle,
                        children: [
                          _buildTableRow('Business Type', businessType),
                          _buildTableRow('Project Duration', projectDuration),
                          _buildTableRow('Start Date', startDate),
                          _buildTableRow('Mature Date', endDate),

                          if (roiStartDate.isNotEmpty)
                            _buildTableRow('ROI Start Date', roiStartDate),

                          _buildTableRow('Investment Goal',
                              _formatAmount(investmentGoal)),
                          _buildTableRow('Min. Investment',
                              _formatAmount(minInvestment)),
                          _buildTableRow('Raised', _formatAmount(raised)),
                          _buildTableRow(
                              'In Waiting', _formatAmount(inWaiting)),
                          _buildTableRow('ROI', roi),
                          _buildTableRow('Status', statusText),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🔹 Upcoming Info
            if (showUpcoming) ...[
              const SizedBox(height: 8),
              Container(
                height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  investmentStartDate != null
                      ? 'Investment starts: $investmentStartDate'
                      : 'Upcoming',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
