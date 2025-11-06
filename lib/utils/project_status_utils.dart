
import '../models/Total_projects_model.dart';

Map<String, dynamic> getProjectStatus({
  required TotalProject project,
}) {
  final now = DateTime.now();

  DateTime? startDate = project.project_start_date != null &&
      project.project_start_date!.isNotEmpty
      ? DateTime.tryParse(project.project_start_date!)
      : null;

  DateTime? roiStartDate = project.roi_start_date != null &&
      project.roi_start_date!.isNotEmpty
      ? DateTime.tryParse(project.roi_start_date!)
      : null;

  DateTime? endDate = project.project_end_date != null &&
      project.project_end_date!.isNotEmpty
      ? DateTime.tryParse(project.project_end_date!)
      : null;

  String status = 'Unknown';
  int priority = 5;

  if (startDate != null &&
      roiStartDate != null &&
      now.isAfter(startDate) &&
      now.isBefore(roiStartDate)) {
    status = 'Investment Collecting';
    priority = 1;
  } else if (roiStartDate != null &&
      endDate != null &&
      now.isAfter(roiStartDate) &&
      now.isBefore(endDate)) {
    status = 'Running';
    priority = 2;
  } else if (startDate != null && now.isBefore(startDate)) {
    status = 'Upcoming';
    priority = 3;
  } else if (endDate != null && now.isAfter(endDate)) {
    status = 'Matured';
    priority = 4;
  }

  return {
    'status': status,
    'priority': priority,
  };
}
