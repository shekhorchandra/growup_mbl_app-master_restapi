import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/Total_projects_model.dart';
import '../utils/total_projects_api.dart';
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

  String formatAmount(dynamic amount) {
    if (amount == null) return '0 Tk';
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(amount)} Tk';
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

  // ✅ Determine project status, color, and priority for sorting
  Map<String, dynamic> getProjectStatus(TotalProject project) {
    final now = DateTime.now();

    DateTime? startDate = project.project_start_date != null && project.project_start_date!.isNotEmpty
        ? DateTime.tryParse(project.project_start_date!)
        : null;

    DateTime? roiStartDate = project.roi_start_date != null && project.roi_start_date!.isNotEmpty
        ? DateTime.tryParse(project.roi_start_date!)
        : null;

    DateTime? endDate = project.project_end_date != null && project.project_end_date!.isNotEmpty
        ? DateTime.tryParse(project.project_end_date!)
        : null;

    String status = 'Unknown';
    Color color = Colors.grey;
    int priority = 5;

    if (startDate != null && roiStartDate != null && now.isAfter(startDate) && now.isBefore(roiStartDate)) {
      status = 'Investment Collecting';
      color = Colors.blue;
      priority = 1;
    } else if (roiStartDate != null && endDate != null && now.isAfter(roiStartDate) && now.isBefore(endDate)) {
      status = 'Running';
      color = Colors.green;
      priority = 2;
    } else if (startDate != null && now.isBefore(startDate)) {
      status = 'Upcoming';
      color = Colors.orange;
      priority = 3;
    } else if (endDate != null && now.isAfter(endDate)) {
      status = 'Matured';
      color = Colors.red;
      priority = 4;
    }

    return {
      'status': status,
      'color': color,
      'priority': priority,
    };
  }

  int getProjectPriority(TotalProject project) {
    return getProjectStatus(project)['priority'];
  }

  TableRow _buildTableRow(String label, String value, {Color valueColor = Colors.black}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(value, style: TextStyle(fontSize: 8, color: valueColor)),
        ),
      ],
    );
  }

  Widget _buildProjectCard({
    required TotalProject project,
    required BuildContext context,
  }) {
    final now = DateTime.now();
    final statusInfo = getProjectStatus(project);
    final String statusText = statusInfo['status'];
    final Color statusColor = statusInfo['color'];

    DateTime? startDate = project.project_start_date != null && project.project_start_date!.isNotEmpty
        ? DateTime.tryParse(project.project_start_date!)
        : null;

    final bool isRunning = project.status == 1;
    final double goal = project.investmentGoal ?? 0;
    final double raised = project.raised ?? 0;

    final bool canInvest = isRunning && (raised <= goal);

    bool showInvestNow = false;
    bool showUpcoming = false;

    if (startDate != null && now.isBefore(startDate)) {
      showUpcoming = true;
    } else if (canInvest) {
      showInvestNow = true;
    }

    String countdownText = '';
    if (showUpcoming && startDate != null) {
      final daysLeft = startDate.difference(now).inDays;
      if (daysLeft > 1) {
        countdownText = 'Starts in $daysLeft days';
      } else if (daysLeft == 1) {
        countdownText = 'Starts tomorrow';
      } else {
        countdownText = 'Starts soon';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          project.imageUrl != null && project.imageUrl!.isNotEmpty
                              ? Image.network(
                            project.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/placeholder1.jpg',
                              fit: BoxFit.contain,
                            ),
                          )
                              : Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.contain),
                          const SizedBox(height: 6),
                          Text(
                            project.projectName ?? 'N/A',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(4),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          _buildTableRow('Business Type', project.businessType_name ?? 'N/A'),
                          _buildTableRow('Investment Time', '${project.remaining_opportunity_days ?? 0} days'),
                          _buildTableRow('Project Duration', "${project.project_duration_viewer ?? 'N/A'}"),
                          _buildTableRow('Start Date', formatDate(project.project_start_date)),
                          _buildTableRow('Mature Date', formatDate(project.project_end_date)),
                          _buildTableRow('ROI Start Date', formatDate(project.roi_start_date)),
                          _buildTableRow('Investment Goal', formatAmount(goal)),
                          _buildTableRow('Min. Investment', formatAmount(project.min_investment_amount ?? 0)),
                          _buildTableRow('Raised', formatAmount(raised)),
                          _buildTableRow('In Waiting', formatAmount(project.remaining_goal)),
                          _buildTableRow('ROI', project.annualRoi != null ? 'Annually ${project.annualRoi}%' : 'N/A'),
                          _buildTableRow('Status', statusText, valueColor: statusColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Row(
                  children: [
                    if (showUpcoming)
                      Expanded(
                        child: Container(
                          height: 35,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            startDate != null
                                ? 'Investment starts: ${DateFormat('dd MMM, yyyy').format(startDate)}'
                                : 'Upcoming',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    if (showInvestNow)
                      Expanded(
                        child: SizedBox(
                          height: 35,
                          child: ElevatedButton(
                            onPressed: _loadingProjectIds.contains(project.id)
                                ? null
                                : () async {
                              final projectId = project.id;
                              if (projectId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Project ID is missing')),
                                );
                                return;
                              }

                              setState(() {
                                _loadingProjectIds.add(projectId);
                              });

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
                                setState(() {
                                  _loadingProjectIds.remove(projectId);
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _loadingProjectIds.contains(project.id)
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'Invest Now',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Total Projects', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by project name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
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

                // ✅ Sort by project priority (Investment Collecting → Running → Upcoming → Matured)
                _allProjects.sort((a, b) => getProjectPriority(a).compareTo(getProjectPriority(b)));

                final projects = _filteredProjects.isEmpty ? _allProjects : _filteredProjects;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: projects.length,
                  itemBuilder: (context, index) => _buildProjectCard(
                    context: context,
                    project: projects[index],
                  ),
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
