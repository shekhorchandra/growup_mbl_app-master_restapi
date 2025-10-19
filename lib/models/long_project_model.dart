class LongProjectModel {
  final String? imageUrl;
  final String? businessType_name;
  final String? name;
  final String? investmentType_name;
  final int? id;
  final int? remaining_opportunity_days;
  final double? investmentGoal;
  final int? raised;
  final int? remaining_goal;
  final String? project_duration_viewer;
  final double? min_investment_amount;
  final String? projected;
  final int? annualRoi;
  // final String? image;
  final int? status;
  final String? projectName;
  final String? project_start_date;
  final String? project_end_date;
  final String roi_start_date;

  LongProjectModel({
    this.imageUrl,
    this.businessType_name,
    this.name,
    this.investmentType_name,
    this.id,
    this.remaining_opportunity_days,
    this.investmentGoal,
    this.raised,
    this.remaining_goal,
    this.project_duration_viewer,
    this.min_investment_amount,
    this.projected,
    this.annualRoi,
    // this.image,
    this.status,
    this.projectName,
    this.project_start_date,
    this.project_end_date,
    required this.roi_start_date,
  });

  factory LongProjectModel.fromJson(Map<String, dynamic> json) {
    return LongProjectModel(
      name: json['name'] ?? json['project_name'],
      businessType_name: json['businessType_name'] ?? 'N/A',
      id: json['id'],
      remaining_opportunity_days: int.tryParse(json['remaining_opportunity_days'].toString()) ?? 0,
      roi_start_date: json['roi_start_date']?.toString() ?? 'N/A',
      investmentGoal: double.tryParse(json['investment_goal'].toString()) ?? 0,
      raised: json['raised'] == null ? 0 : int.tryParse(json['raised'].toString()) ?? 0,
      remaining_goal: int.tryParse(json['remaining_goal'].toString()) ?? 0,
      project_duration_viewer: json['project_duration_viewer'],
      min_investment_amount: double.tryParse(json['min_investment_amount'].toString()) ?? 0,
      projected: json['projected'],
      annualRoi: json['annual_roi'] == null ? 0 : int.tryParse(json['annual_roi'].toString()) ?? 0,
      imageUrl: json['image_url'],
      status: int.tryParse(json['status'].toString()) ?? 0,
      projectName: json['project_name'],
      investmentType_name: json['investmentType_name'],
      project_start_date: json['project_start_date'],
      project_end_date: json['project_end_date'],
    );
  }

}
