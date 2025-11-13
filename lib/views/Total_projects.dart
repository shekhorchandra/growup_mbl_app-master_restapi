import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/Total_projects_model.dart';
import '../utils/project_status_utils.dart';
import '../utils/total_projects_api.dart';
import '../widgets/project_card.dart';
import '../widgets/search_bar.dart';
import 'project_Descriotion_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TotalProjectsPage extends StatefulWidget {
  final bool hideAppBar;
  const TotalProjectsPage({super.key, this.hideAppBar = false});

  @override
  State<TotalProjectsPage> createState() => _TotalProjectsPageState();
}

class _TotalProjectsPageState extends State<TotalProjectsPage> {
  late Future<List<TotalProject>> futureProjects;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;
  Set<int> _loadingProjectIds = {};
  final TextEditingController _searchController = TextEditingController();
  List<TotalProject> _allProjects = [];
  List<TotalProject> _filteredProjects = [];

  @override
  void initState() {
    super.initState();
    futureProjects = ApiService().getAllProjects();
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

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return rawDate;
    }
  }


  int getProjectPriority(TotalProject project) => getProjectStatus(project: project)['priority'];

  Future<void> _openProjectDetails(
      int projectId, BuildContext context) async {
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
          'Total Projects',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          CustomSearchBar(searchController: _searchController),

          // Project List
          Expanded(
            child: FutureBuilder<List<TotalProject>>(
              future: futureProjects,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No projects found.'));
                }

                _allProjects = snapshot.data!;

                // Sort by project priority
                _allProjects.sort(
                        (a, b) => getProjectPriority(a).compareTo(getProjectPriority(b)));

                final projects =
                _filteredProjects.isEmpty ? _allProjects : _filteredProjects;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final statusInfo = getProjectStatus(project: project);

                    final String statusText = statusInfo['status'];

                    final now = DateTime.now();
                    final startDate =
                    project.project_start_date != null &&
                        project.project_start_date!.isNotEmpty
                        ? DateTime.tryParse(project.project_start_date!)
                        : null;

                    // final bool isRunning = project.status == 1;
                    // final double goal = project.investmentGoal ?? 0;
                    // final double raised = project.raised ?? 0;
                    // final bool canInvest = isRunning && (raised <= goal);
                    //
                    // bool showInvestNow = false;
                    // bool showUpcoming = false;
                    //
                    // if (startDate != null && now.isBefore(startDate)) {
                    //   showUpcoming = true;
                    // } else if (canInvest) {
                    //   showInvestNow = true;
                    // }

                    final double goal = project.investmentGoal ?? 0;
                    final double raised = project.raised ?? 0;



                    final bool showInvestNow = statusText == 'Investment Collecting';
                    final bool showUpcoming = startDate != null && now.isBefore(startDate);


                    return ProjectCard(
                      projectName: project.projectName ?? 'N/A',
                      businessType: project.businessType_name ?? 'N/A',
                      imageUrl: project.imageUrl,
                      projectDuration:
                      '${project.project_duration_viewer ?? 'N/A'} Months',
                      startDate: formatDate(project.project_start_date),
                      endDate: formatDate(project.project_end_date),
                      roiStartDate:
                      formatDate(project.roi_start_date), // hidden if blank
                      investmentGoal: goal,
                      minInvestment:
                      (project.min_investment_amount ?? 0).toDouble(),
                      raised: raised,
                      inWaiting:
                      (project.remaining_goal ?? 0).toDouble(),
                      roi: project.annualRoi != null
                          ? 'Annually ${project.annualRoi}%'
                          : 'N/A',
                      statusText: statusText,
                      showInvestNow: showInvestNow,
                      showUpcoming: showUpcoming,
                      investmentStartDate: startDate != null
                          ? DateFormat('dd MMM, yyyy').format(startDate)
                          : null,
                      isLoading:
                      _loadingProjectIds.contains(project.id ?? 0),
                      onInvestNowPressed: () async {
                        final projectId = project.id;
                        if (projectId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Project ID is missing')),
                          );
                          return;
                        }

                        setState(() {
                          _loadingProjectIds.add(projectId);
                        });

                        try {
                          await _openProjectDetails(projectId, context);
                        } finally {
                          setState(() {
                            _loadingProjectIds.remove(projectId);
                          });
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // 🔝 Floating Back-to-top
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
