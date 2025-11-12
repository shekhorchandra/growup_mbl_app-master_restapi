import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/my_projects_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/project_Descriotion_page.dart';
import 'package:growup_agro/widgets/project_card.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MyProjectsPage extends StatefulWidget {
  final bool hideAppBar;
  const MyProjectsPage({super.key, this.hideAppBar = false});

  @override
  State<MyProjectsPage> createState() => _MyProjectsPageState();
}

class _MyProjectsPageState extends State<MyProjectsPage> {
  late Future<List<MyProjectsModel>> futureMyProjects;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<MyProjectsModel> _allProjects = [];
  List<MyProjectsModel> _filteredProjects = [];

  bool _isSearching = false;
  bool _showBackToTopButton = false;
  Set<int> _loadingProjectIds = {};

  @override
  void initState() {
    super.initState();
    futureMyProjects = fetchMyProjects();
    _searchController.addListener(_filterProjects);

    _scrollController.addListener(() {
      if (_scrollController.offset >= 300) {
        if (!_showBackToTopButton) setState(() => _showBackToTopButton = true);
      } else {
        if (_showBackToTopButton) setState(() => _showBackToTopButton = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<MyProjectsModel>> fetchMyProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final investorId = prefs.getString('investor_id');

    if (token == null || investorId == null) {
      throw Exception("Missing token or investor ID");
    }

    final url = Uri.parse(ApiConstants.investorProjectList(investorId));
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic>? projects = decoded['data'];

      if (projects == null || projects.isEmpty) return [];

      _allProjects = projects
          .map<MyProjectsModel>((p) => MyProjectsModel.fromJson(p))
          .toList();
      _filteredProjects = _allProjects;
      return _allProjects;
    } else {
      throw Exception('Failed to load projects');
    }
  }

  void _filterProjects() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProjects = _allProjects
          .where((p) => p.projectName?.toLowerCase().contains(query) ?? false)
          .toList();
    });
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(rawDate));
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> _handleReinvest(MyProjectsModel project, BuildContext context) async {
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      title: _isSearching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        cursorColor: Colors.white,
        decoration: const InputDecoration(
          hintText: 'Search by project name...',
          hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      )
          : const Text(
        'My Projects',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon:
          Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
          onPressed: () {
            setState(() {
              if (_isSearching) _searchController.clear();
              _isSearching = !_isSearching;
            });
          },
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // ✅ Your project status logic integrated here
  Map<String, dynamic> _getProjectStatus(MyProjectsModel project) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar ? null : _buildAppBar(),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<MyProjectsModel>>(
        future: futureMyProjects,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No My Projects found.'));
          }

          final projects =
          _filteredProjects.isEmpty ? snapshot.data! : _filteredProjects;

          return ListView.builder(
            controller: _scrollController,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];

              final statusData = _getProjectStatus(project);
              final statusText = statusData['status'];

              final goal = double.tryParse(
                  project.investmentGoal?.replaceAll(',', '') ?? '0') ??
                  0;
              final raised = double.tryParse(
                  project.totalInvestment?.replaceAll(',', '') ?? '0') ??
                  0;
              final inWaiting = goal - raised;

              final showUpcoming = statusText == 'Upcoming';
              final showInvestNow = statusText == 'Investment Collecting';

              DateTime? startDate;
              try {
                if (project.project_start_date?.isNotEmpty ?? false) {
                  startDate = DateTime.parse(project.project_start_date!);
                }
              } catch (_) {}

              return ProjectCard(
                buttonText: "Re-Invest",
                projectName: project.projectName ?? 'N/A',
                businessType: project.businessTypeName ?? 'N/A',
                imageUrl: project.image != null
                    ? 'https://growupagro.tech${project.image}'
                    : null,
                projectDuration: project.projectDurationViewer ?? 'N/A',
                startDate: formatDate(project.project_start_date),
                endDate: formatDate(project.project_end_date),
                roiStartDate: formatDate(project.roi_start_date),
                investmentGoal: goal,
                minInvestment: double.tryParse(
                    project.minInvestmentAmount?.replaceAll(',', '') ?? '0') ??
                    0,
                raised: raised,
                inWaiting: inWaiting,
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
                onInvestNowPressed: () => _handleReinvest(project, context),
              );
            },
          );
        },
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: Colors.orange,
        child:
        const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
      )
          : null,
    );
  }
}
