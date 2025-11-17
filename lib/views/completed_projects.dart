import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/project_Descriotion_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/completed_projects_model.dart';
import '../widgets/project_card.dart';
import '../widgets/search_bar.dart';

class CompletedProjectsPage extends StatefulWidget {
  final bool hideAppBar;
  const CompletedProjectsPage({super.key, this.hideAppBar = false});

  @override
  State<CompletedProjectsPage> createState() => _CompletedProjectsPageState();
}

class _CompletedProjectsPageState extends State<CompletedProjectsPage> {
  late Future<List<CompletedProject>> futureCompletedProjects;
  List<CompletedProject> _allProjects = [];
  List<CompletedProject> _filteredProjects = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    futureCompletedProjects = fetchCompletedProjects();
    _searchController.addListener(_onSearchChanged);

    _scrollController.addListener(() {
      if (_scrollController.offset >= 300 && !_showBackToTopButton) {
        setState(() => _showBackToTopButton = true);
      } else if (_scrollController.offset < 300 && _showBackToTopButton) {
        setState(() => _showBackToTopButton = false);
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProjects = _allProjects
          .where((project) => project.projectName.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<List<CompletedProject>> fetchCompletedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    final url = Uri.parse(ApiConstants.completedProjects(investorCode));
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        final List<dynamic> projectsJson = jsonData['projects'];
        _allProjects =
            projectsJson.map((json) => CompletedProject.fromJson(json)).toList();
        _filteredProjects = _allProjects;
        return _allProjects;
      } else {
        throw Exception(jsonData['message']);
      }
    } else {
      throw Exception('Failed to load Matured projects');
    }
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDetails(CompletedProject project, BuildContext context) async {
    final projectId = project.id;
    if (projectId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final investorCode = prefs.getString('investor_code');
    if (investorCode == null || investorCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Investor code not found.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDescriptionPage(
          projectId: projectId,
          investorCode: investorCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.hideAppBar
          ? null
          : AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'Matured Projects',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          CustomSearchBar(searchController: _searchController),

          // Project List
          Expanded(
            child: FutureBuilder<List<CompletedProject>>(
              future: futureCompletedProjects,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No matured projects found.'));
                }

                final projects = _filteredProjects.isEmpty
                    ? snapshot.data!
                    : _filteredProjects;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];

                    final startDate = project.project_start_date != null &&
                        project.project_start_date!.isNotEmpty
                        ? DateTime.tryParse(project.project_start_date!)
                        : null;

                    return ProjectCard(
                      projectName: project.projectName ?? 'N/A',
                      businessType: project.businessType_name ?? 'N/A',
                      imageUrl: project.imageUrl,
                      projectDuration: '${project.project_duration_viewer ?? 'N/A'} Months',
                      startDate: formatDate(project.project_start_date),
                      endDate: formatDate(project.project_end_date),
                      roiStartDate: formatDate(project.roi_start_date),
                      investmentGoal: project.investmentGoal ?? 0,
                      minInvestment: project.min_investment_amount ?? 0,
                      raised: (project.raised ?? 0).toDouble(),
                      inWaiting: (project.remaining_goal ?? 0).toDouble(),
                      roi: project.annualRoi != null
                          ? 'Annually ${project.annualRoi}%'
                          : 'N/A',
                      statusText: 'Matured',
                      showInvestNow: false,
                      showUpcoming: false,
                      investmentStartDate: startDate != null
                          ? DateFormat('dd MMM, yyyy').format(startDate)
                          : null,
                      isLoading: false,
                      onInvestNowPressed: () => _handleDetails(project, context),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      )
          : null,
    );
  }
}
