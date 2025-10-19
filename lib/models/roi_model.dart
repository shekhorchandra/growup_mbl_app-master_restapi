class RoiModel {
  final int id;
  final int projectId;
  final int investorId;
  final double roiAmount;
  final String countingDate;
  final String createdAt;

  RoiModel({
    required this.id,
    required this.projectId,
    required this.investorId,
    required this.roiAmount,
    required this.countingDate,
    required this.createdAt,
  });

  factory RoiModel.fromJson(Map<String, dynamic> json) {
    return RoiModel(
      id: int.parse(json['id'].toString()),
      projectId: int.parse(json['project_id'].toString()),
      investorId: int.parse(json['investor_id'].toString()),
      roiAmount: double.parse(json['roi_amount'].toString()),
      countingDate: json['counting_date'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

}
