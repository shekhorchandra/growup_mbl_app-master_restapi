class UpcomingProject {
  final int id;
  final String? businessType_name;
  final String projectName;
  final String? imageUrl;
  final int? remaining_opportunity_days;
  final double? investmentGoal;
  final int? raised;
  final int? remaining_goal;
  final int? projectDurationViewer;
  final double? min_investment_amount;
  final String? projected;
  final int annualRoi;
  final int status;
  final String? project_start_date;
  final String? project_end_date;

  String? category; // ← NEW: store category (Shariah, Live, etc.)

  UpcomingProject({
    required this.id,
    this.businessType_name,
    required this.projectName,
    this.imageUrl,
    required this.remaining_opportunity_days,
    required this.investmentGoal,
    required this.raised,
    required this.remaining_goal,
    required this.projectDurationViewer,
    this.min_investment_amount,
    this.projected,
    required this.annualRoi,
    required this.status,
    this.project_start_date,
    this.project_end_date,
    this.category, // ← NEW
  });

  factory UpcomingProject.fromJson(Map<String, dynamic> json) {
    return UpcomingProject(
      id: json['id'],
      businessType_name: json['businessType_name'] ?? 'N/A',
      projectName: json['project_name'] ?? 'N/A',
      imageUrl: json['image_url'],
      remaining_opportunity_days: json['remaining_opportunity_days'] != null
          ? int.tryParse(json['remaining_opportunity_days'].toString()) ?? 0
          : 0,

      investmentGoal: double.tryParse(json['investment_goal'].toString()),
      raised: json['raised'] ?? 0,
      remaining_goal: json['remaining_goal'] ?? 0,
      projectDurationViewer: json['project_duration_viewer'],
      min_investment_amount:
      double.tryParse(json['min_investment_amount'].toString()),
      projected: json['projected'],
      annualRoi: json['annual_roi'] ?? 0,
      status: json['status'] ?? 0,
      project_start_date: json['project_start_date'],
      project_end_date: json['project_end_date'],
    );
  }
}
