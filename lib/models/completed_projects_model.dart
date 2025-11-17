class CompletedProject {
  final int id;
  final String? businessType_name;
  final String? investmentType_name;
  final String projectName;
  final String? imageUrl;
  final int? remaining_opportunity_days;
  final double? investmentGoal;
  final num raised;
  final num remaining_goal;
  final String? project_duration_viewer;
  final int projectDurationActual;
  final double? min_investment_amount;
  final String? projected;
  final int annualRoi;
  final int status;
  final String? project_start_date;
  final String? project_end_date;
  final String? roi_start_date;

  CompletedProject({
    required this.id,
    this.businessType_name,
    this.investmentType_name,
    required this.projectName,
    this.imageUrl,
    this.remaining_opportunity_days,
    required this.investmentGoal,
    required this.raised,
    required this.remaining_goal,
    this.project_duration_viewer,
    required this.projectDurationActual,
    required this.min_investment_amount,
    this.projected,
    required this.annualRoi,
    required this.status,
    this.project_start_date,
    this.project_end_date,
    this.roi_start_date,
  });

  factory CompletedProject.fromJson(Map<String, dynamic> json) {
    return CompletedProject(
      id: json['id'],
      businessType_name: json['businessType_name'] ?? 'N/A',
      investmentType_name: json['investmentType_name'] ?? 'N/A',
      projectName: json['project_name'] ?? 'N/A',
      imageUrl: json['image_url'],
      remaining_opportunity_days:
      int.tryParse(json['remaining_opportunity_days'].toString()) ?? 0,
      investmentGoal:
      double.tryParse(json['investment_goal'].toString()) ?? 0,
      raised: num.tryParse(json['raised'].toString()) ?? 0,
      remaining_goal: num.tryParse(json['remaining_goal'].toString()) ?? 0,
      project_duration_viewer: json['project_duration_viewer'],
      projectDurationActual:
      int.tryParse(json['project_duration_actual'].toString()) ?? 0,
      min_investment_amount:
      double.tryParse(json['min_investment_amount'].toString()) ?? 0,
      projected: json['projected'],
      annualRoi: int.tryParse(json['annual_roi'].toString()) ?? 0,
      status: int.tryParse(json['status'].toString()) ?? 0,
      project_start_date: json['project_start_date'],
      project_end_date: json['project_end_date'],
      roi_start_date: json['roi_start_date'],
    );
  }

}
