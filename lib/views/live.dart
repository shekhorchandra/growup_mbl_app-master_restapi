import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/project_Descriotion_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/live_project_model.dart';
import '../utils/project_status_utils.dart';
import '../widgets/project_card.dart';
import '../widgets/search_bar.dart';

class LiveProjectsPage extends StatefulWidget {
  final bool hideAppBar;
  const LiveProjectsPage({super.key, this.hideAppBar = false});

  @override
  State<LiveProjectsPage> createState() => _LiveProjectsPageState();
}

class _LiveProjectsPageState extends State<LiveProjectsPage> {
  Set<int> _loadingProjectIds = {};
  late Future<List<LiveProject>> futureProjects;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  List<LiveProject> _allProjects = [];
  List<LiveProject> _filteredProjects = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureProjects = fetchLiveProjects();
    _searchController.addListener(_onSearchChanged);

    _scrollController.addListener(() {
      if (_scrollController.offset >= 300) {
        if (!_showBackToTopButton) setState(() => _showBackToTopButton = true);
      } else {
        if (_showBackToTopButton) setState(() => _showBackToTopButton = false);
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProjects = _allProjects.where((project) {
        return project.projectName?.toLowerCase().contains(query) ?? false;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<List<LiveProject>> fetchLiveProjects() async {
    final url = Uri.parse(ApiConstants.allProjects());
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('Token not found. Please log in again.');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = json.decode(response.body);
      final List<dynamic>? projects = decoded['projects']?['Live Projects'];

      if (projects == null) throw Exception('Live projects not found.');

      _allProjects =
          projects.map<LiveProject>((p) => LiveProject.fromJson(p)).toList();
      _filteredProjects = _allProjects;
      return _allProjects;
    } else {
      throw Exception('Failed to load projects');
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

  Future<void> _handleInvestNow(LiveProject project, BuildContext context) async {
    final projectId = project.id;
    if (projectId == null) return;

    setState(() => _loadingProjectIds.add(projectId));

    try {
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
    } finally {
      setState(() => _loadingProjectIds.remove(projectId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'Live Projects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search Bar
          CustomSearchBar(searchController: _searchController),

          // Project List
          Expanded(
            child: FutureBuilder<List<LiveProject>>(
              future: futureProjects,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No live projects found.'));
                }

                final projects = _filteredProjects.isEmpty
                    ? snapshot.data!
                    : _filteredProjects;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final statusInfo = _getProjectStatus(project);
                    final String statusText = statusInfo['status'];

                    final now = DateTime.now();
                    final startDate = project.project_start_date != null &&
                        project.project_start_date!.isNotEmpty
                        ? DateTime.tryParse(project.project_start_date!)
                        : null;

                    final goal = project.investmentGoal ?? 0;
                    final raised = project.raised ?? 0;

                    final showUpcoming = startDate != null && now.isBefore(startDate);
                    // final showInvestNow = project.status == 1 && raised <= goal;
                    final showInvestNow = statusText == 'Investment Collecting';


                    return ProjectCard(
                      projectName: project.projectName ?? 'N/A',
                      businessType: project.businessType_name ?? 'N/A',
                      imageUrl: project.imageUrl,
                      projectDuration:
                      '${project.project_duration_viewer ?? 'N/A'} Months',
                        startDate: formatDate(project.project_start_date),
                      endDate: formatDate(project.project_end_date),
                      roiStartDate: formatDate(project.roi_start_date),
                      investmentGoal: goal,
                      minInvestment: project.min_investment_amount ?? 0,
                      raised: (project.raised ?? 0).toDouble(),
                      inWaiting: (project.remaining_goal ?? 0).toDouble(),
                      roi: project.annualRoi != null
                          ? 'Annually ${project.annualRoi}%'
                          : 'N/A',
                      statusText: statusText,
                      showInvestNow: showInvestNow,
                      showUpcoming: showUpcoming,
                      investmentStartDate: startDate != null
                          ? DateFormat('dd MMM, yyyy').format(startDate)
                          : null,
                      isLoading: _loadingProjectIds.contains(project.id),
                      onInvestNowPressed: () =>
                          _handleInvestNow(project, context),
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

  /// Determine dynamic project status, color, and priority for sorting
  Map<String, dynamic> _getProjectStatus(LiveProject project) {
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

    return {'status': status, 'priority': priority};
  }

}