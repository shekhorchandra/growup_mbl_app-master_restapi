class MyProjectsModel {
  final int? id;
  final String? projectName;
  final String? projectDurationViewer;
  final String? minInvestmentAmount;
  final String? investmentGoal;
  final String? totalInvestment;
  final int? annualRoi;
  final int? status;
  final String? image;
  final String? projected;
  final int? investmentOpportunityDays;
  final String? businessTypeName;
  final String? project_start_date;
  final String? project_end_date;
  final String roi_start_date;

  MyProjectsModel({
    this.id,
    this.projectName,
    this.projectDurationViewer,
    this.minInvestmentAmount,
    this.investmentGoal,
    this.totalInvestment,
    this.annualRoi,
    this.status,
    this.image,
    this.projected,
    this.investmentOpportunityDays,
    this.businessTypeName,
    this.project_start_date,
    this.project_end_date,
    required this.roi_start_date,
  });

  factory MyProjectsModel.fromJson(Map<String, dynamic> json) {
    return MyProjectsModel(
      id: json['id'],
      projectName: json['project_name'],
      projectDurationViewer: json['project_duration_viewer'],
      minInvestmentAmount: json['min_investment_amount']?.toString(),
      investmentGoal: json['investment_goal']?.toString(),
      totalInvestment: json['total_investment']?.toString(),
      annualRoi: json['annual_roi'] != null ? int.parse(json['annual_roi'].toString()) : null,
      status: json['status'] != null ? int.parse(json['status'].toString()) : null,
      image: json['image_url'],
      projected: json['projected'],
      investmentOpportunityDays: json['investment_opportunity_days'] != null ? int.parse(json['investment_opportunity_days'].toString()) : null,
      businessTypeName: json['businessType_name'],
      project_start_date: json['project_start_date'],
      project_end_date: json['project_end_date'],
      roi_start_date: json['roi_start_date']?.toString() ?? 'N/A',
    );
  }

}
