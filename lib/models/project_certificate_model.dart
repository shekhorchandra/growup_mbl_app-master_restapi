class ProjectCertificate {
  final int id;
  final String name;
  final String code;
  final String roi;
  final String endDate;
  final String previewUrl;
  final String viewUrl;
  final String downloadUrl;

  ProjectCertificate({
    required this.id,
    required this.name,
    required this.code,
    required this.roi,
    required this.endDate,
    required this.previewUrl,
    required this.viewUrl,
    required this.downloadUrl,
  });

  factory ProjectCertificate.fromJson(Map<String, dynamic> json) {
    return ProjectCertificate(
      id: json['id'],
      name: json['name'],
      code: json['code'].toString(),
      roi: json['roi'].toString(),
      endDate: json['end_date'],
      previewUrl: json['preview_url'] ?? '',
      viewUrl: json['view_url'] ?? '',
      downloadUrl: json['download_url'] ?? '',
    );
  }
}