class TotalProject {
  final int id;
  final String? projectName;
  final String? businessType_name;
  final String? projectCode;
  final String? projectArea;
  final String? imageUrl;
  final String? project_start_date;
  final String? project_end_date;
  final double? investmentGoal;
  final double? min_investment_amount;
  final double? raised;
  final double? remaining_goal;
  final int? remaining_opportunity_days;
  final String? project_duration_viewer;
  final String? businessTypeName;
  final double? annualRoi;
  final int? status;
  final String roi_start_date;

  TotalProject({
    required this.id,
    this.projectName,
    this.businessType_name,
    this.projectCode,
    this.projectArea,
    this.imageUrl,
    this.project_start_date,
    this.project_end_date,
    this.investmentGoal,
    this.min_investment_amount,
    this.raised,
    this.remaining_goal,
    this.remaining_opportunity_days,
    this.project_duration_viewer,
    this.businessTypeName,
    this.annualRoi,
    this.status,
    required this.roi_start_date,
  });

  factory TotalProject.fromJson(Map<String, dynamic> json) {
    return TotalProject(
      id: json['id'],
      projectName: json['project_name'],
      roi_start_date: json['roi_start_date']?.toString() ?? 'N/A',
      businessType_name: json['businessType_name'] ?? 'N/A',
      projectCode: json['project_code'],
      projectArea: json['project_area'],
      imageUrl: json['image_url'],
      project_start_date: json['project_start_date'],
      project_end_date: json['project_end_date'],
      investmentGoal: double.tryParse(json['investment_goal'].toString()),
      min_investment_amount: double.tryParse(json['min_investment_amount'].toString()),
      raised: double.tryParse(json['raised'].toString()),
      remaining_goal: double.tryParse(json['remaining_goal'].toString()),
      remaining_opportunity_days: json['remaining_opportunity_days'],
      project_duration_viewer: json['project_duration_viewer'],
      businessTypeName: json['businessType_name'],
      annualRoi: double.tryParse(json['annual_roi'].toString()),
      status: int.tryParse(json['status'].toString()),
    );
  }
}
