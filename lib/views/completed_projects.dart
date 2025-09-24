import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
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

  String formatAmount(dynamic amount) {
    if (amount == null || amount.toString().isEmpty) return '0 Tk';
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(int.tryParse(amount.toString()) ?? 0)} Tk';
  }

  TableRow _buildTableRow(String label, String value,
      {Color valueColor = Colors.black}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 160,
                height: 220,
                child: project.imageUrl != null && project.imageUrl!.isNotEmpty
                    ? Image.network(
                  project.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/placeholder1.jpg',
                    fit: BoxFit.cover,
                  ),
                )
                    : Image.asset('assets/images/placeholder1.jpg',
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            // Right: Table
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.projectName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.green),
                  ),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(4),
                      1: FlexColumnWidth(4),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildTableRow('Business Type', project.projectName ?? 'N/A'),
                      _buildTableRow('Investment Time',
                          '${project.remainingOpportunityDays ?? 0} days'),
                      _buildTableRow(
                          'Investment Goal', formatAmount(project.investmentGoal)),
                      _buildTableRow('Raised', formatAmount(project.raised)),
                      _buildTableRow('In Waiting', formatAmount(project.remainingGoal)),
                      _buildTableRow('Duration',
                          project.projectDurationViewer?.toString() ?? 'N/A'),
                      _buildTableRow('Min. Investment',
                          formatAmount(project.minInvestmentAmount)),
                      // _buildTableRow('Projected', project.projected ?? 'N/A'),
                      _buildTableRow(
                          'ROI',
                          project.annualRoi != null
                              ? 'Annually ${project.annualRoi}%'
                              : 'N/A'),
                      _buildTableRow(
                        'Status',
                        project.status == 1 ? 'Running' : 'Closed',
                        valueColor:
                        project.status == 1 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: null, // completed project no action
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
