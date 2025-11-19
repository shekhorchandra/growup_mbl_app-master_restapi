class InvestmentHistoryItem {
  final int sl;
  final int project_id;
  final String? projectTitle;
  final String? projectCategory;
  final String? firstInvestmentDate;
  final int? totalInvestment;
  final int investmentCount;
  final double? projectProgress;
  final String status;
  final String? projectImage;
  final double? roiDetails;
  final double? capitalReturnDetails;
  final int ? days_remaining;
  final String? roi_details;


  InvestmentHistoryItem({
    required this.sl,
    required this.project_id,
    this.projectTitle,
    this.projectCategory,
    required this.firstInvestmentDate,
    required this.totalInvestment,
    required this.investmentCount,
    required this.projectProgress,
    required this.status,
    required this.roiDetails,
    required this.capitalReturnDetails,
    required this.projectImage,
    required this.days_remaining,
    required this.roi_details,
  });

  factory InvestmentHistoryItem.fromJson(Map<String, dynamic> json) {
    return InvestmentHistoryItem(
      sl: int.tryParse(json['sl']?.toString() ?? '') ?? 0,

      project_id: int.tryParse(json['project_id']?.toString() ?? '') ?? 0,

      projectImage: json['project_image'],
      projectTitle: json['project_title'],
      projectCategory: json['project_category'],
      firstInvestmentDate: json['first_investment_date'],

      totalInvestment: int.tryParse(json['total_investment']?.toString() ?? '') ?? 0,

      investmentCount:
      int.tryParse(json['investment_count']?.toString() ?? '') ?? 0,

      days_remaining:
      int.tryParse(json['days_remaining']?.toString() ?? '') ?? 0,

      projectProgress:
      double.tryParse(json['project_progress']?.toString() ?? '') ?? 0.0,

      roiDetails:
      double.tryParse(json['roi_details']?.toString() ?? '') ?? 0.0,

      capitalReturnDetails:
      double.tryParse(json['capital_return_details']?.toString() ?? '') ?? 0.0,

      status: json['status'] ?? "",

      roi_details: json['roi_details']?.toString(),

    );
  }


}
