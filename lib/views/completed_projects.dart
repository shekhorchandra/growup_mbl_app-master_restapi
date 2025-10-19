import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/project_Descriotion_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/completed_projects_model.dart';

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
  String formatAmount(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatted = NumberFormat('#,##0').format(number);
    return '$formatted Tk';
  }

  // String formatAmount(dynamic amount) {
  //   if (amount == null || amount.toString().isEmpty) return '0 Tk';
  //   final formatter = NumberFormat('#,##0');
  //   return '${formatter.format(int.tryParse(amount.toString()) ?? 0)} Tk';
  // }
  // String formatAmount1(double? value) {
  //   if (value == null) return '0 Tk';
  //   final formatter = NumberFormat('#,##0.00');
  //   return '${formatter.format(value)} Tk';
  // }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(rawDate); // parse "2025-09-24"
      return DateFormat('dd MMM yyyy').format(date); // → "24 Sep 2025"
    } catch (_) {
      return rawDate; // fallback
    }
  }

  TableRow _buildTableRow(String label, String value,
      {Color valueColor = Colors.black}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            value,
            style:
            TextStyle(fontWeight: FontWeight.normal, fontSize: 8, color: valueColor),
          ),
        ),
      ],
    );
  }



  Widget _buildProjectCard({required CompletedProject project}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Content Row (Image + Table)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Image
                // Expanded(
                //   flex: 1,
                //   child: ClipRRect(
                //     borderRadius: BorderRadius.circular(8),
                //     child: Container(
                //       color: Colors.white,
                //       child: project.imageUrl != null && project.imageUrl!.isNotEmpty
                //           ? Image.network(
                //         project.imageUrl!,
                //         fit: BoxFit.contain,
                //         errorBuilder: (_, __, ___) =>
                //             Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.contain),
                //       )
                //           : Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.contain),
                //     ),
                //   ),
                // ),
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🖼️ Image section
                          project.imageUrl != null && project.imageUrl!.isNotEmpty
                              ? Image.network(
                            project.imageUrl!,
                            fit: BoxFit.contain,
                            // height: 100, // adjust height as needed
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/placeholder1.jpg',
                              fit: BoxFit.contain,
                              // height: 100,
                            ),
                          )
                              : Image.asset(
                            'assets/images/placeholder1.jpg',
                            fit: BoxFit.contain,
                            // height: 100,
                          ),

                          const SizedBox(height: 6),

                          // 📝 Project name under image
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
                // Right: Table Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   project.projectName,
                      //   style: const TextStyle(
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: 12,
                      //     color: Colors.green,
                      //   ),
                      // ),
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
                          _buildTableRow('Investment Goal', formatAmount(project.investmentGoal)),
                          _buildTableRow('Min. Investment', formatAmount(project.min_investment_amount ?? 0)),
                          _buildTableRow('Raised', formatAmount(project.raised)),
                          _buildTableRow('In Waiting', formatAmount(project.remaining_goal)),
                          _buildTableRow('ROI', project.annualRoi != null ? 'Annually ${project.annualRoi}%' : 'N/A'),
                          _buildTableRow(
                            'Status',
                            project.status == 1 ? 'Running' : 'Closed',
                            valueColor: project.status == 1 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8), // spacing before button

            // 2. Full-Width "Details" Button
            // SizedBox(
            //   width: double.infinity,
            //   height: 35,
            //   child: ElevatedButton(
            //     onPressed: () async {
            //       final projectId = project.id;
            //       if (projectId == null) {
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           const SnackBar(content: Text('Project ID is missing')),
            //         );
            //         return;
            //       }
            //
            //       final prefs = await SharedPreferences.getInstance();
            //       final investorCode = prefs.getString('investor_code');
            //       if (investorCode == null || investorCode.isEmpty) {
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           const SnackBar(content: Text('Investor code not found.')),
            //         );
            //         return;
            //       }
            //
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (_) => ProjectDescriptionPage(
            //             projectId: projectId,
            //             investorCode: investorCode,
            //           ),
            //         ),
            //       );
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.blueGrey,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       padding: const EdgeInsets.symmetric(vertical: 4),
            //       minimumSize: const Size(double.infinity, 35),
            //     ),
            //     child: const Text(
            //       'Details',
            //       style: TextStyle(color: Colors.white, fontSize: 14),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }


  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
          'Matured Projects',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                    return _buildProjectCard(project: project);
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
