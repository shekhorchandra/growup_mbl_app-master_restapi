import 'dart:convert';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Total_projects_model.dart';

class ApiService {
  Future<List<TotalProject>> getAllProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('Token not found');

    final response = await http.get(
      Uri.parse(ApiConstants.allProjects()),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = json.decode(response.body);

      List<TotalProject> allProjects = [];

      // Loop through all project categories except "Live Projects"
      decoded['projects'].forEach((key, value) {
        if (key != "Shariah" && key != "Live Projects") {
          allProjects.addAll(
            (value as List).map((e) => TotalProject.fromJson(e)),
          );
        }
      });

      return allProjects;
    } else {
      throw Exception('Failed to fetch projects');
    }
  }
}
