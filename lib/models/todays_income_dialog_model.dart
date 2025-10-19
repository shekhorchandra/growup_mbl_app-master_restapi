class RoiDetail {
  final double total_roi;
  final String projectName;
  final String createdAt;
  final String endedAt;

  RoiDetail({
    required this.total_roi,
    required this.projectName,
    required this.createdAt,
    required this.endedAt,
  });

  factory RoiDetail.fromJson(Map<String, dynamic> json) {
    return RoiDetail(
      total_roi: double.tryParse(json['total_roi'].toString()) ?? 0.0,
      projectName: json['project']?['project_name'] ?? 'N/A',
      createdAt: json['project']?['project_start_date'] ?? '',
      endedAt: json['project']?['project_end_date'] ?? '',
    );
  }


}