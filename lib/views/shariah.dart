import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/project_Descriotion_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shariah_project_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ShariahProjectsPage(),
    );
  }
}

class ShariahProjectsPage extends StatefulWidget {
  final bool hideAppBar;
  const ShariahProjectsPage({super.key, this.hideAppBar = false});

  @override
  State<ShariahProjectsPage> createState() => _ShariahProjectsPageState();
}

class _ShariahProjectsPageState extends State<ShariahProjectsPage> {
  Set<int> _loadingProjectIds = {};
  late Future<List<ShariahProject>> futureShariahProjects;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  List<ShariahProject> _allProjects = [];
  List<ShariahProject> _filteredProjects = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureShariahProjects = fetchShariahProjects();
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

  Future<List<ShariahProject>> fetchShariahProjects() async {
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
      final List<dynamic>? shariahProjects = decoded['projects']?['Live Projects'];

      if (shariahProjects == null) throw Exception('Live projects not found.');

      _allProjects = shariahProjects
          .map<ShariahProject>((project) => ShariahProject.fromJson(project))
          .toList();
      _filteredProjects = _allProjects;
      return _allProjects;
    } else {
      throw Exception('Failed to load projects');
    }
  }
  String formatAmount(dynamic amount) {
    if (amount == null || amount.toString().isEmpty) return '0 Tk';
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(int.tryParse(amount.toString()) ?? 0)} Tk';
  }


  Widget _buildProjectCard({required ShariahProject project, required BuildContext context}) {
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
                  errorBuilder: (_, __, ___) =>
                      Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.cover),
                )
                    : Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            // Right: Table + Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.projectName ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                  ),
                  // const SizedBox(height: 8),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(4), // label
                      1: FlexColumnWidth(4), // value
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildTableRow('Business Type', project.businessType_name ?? 'N/A'),
                      //_buildTableRow('Investment Type', project.investmentType_name ?? 'N/A'),
                      _buildTableRow('Investment Time', '${project.remaining_opportunity_days ?? 0} days'),
                      _buildTableRow('Investment Goal', formatAmount(project.investmentGoal)),
                      _buildTableRow('Raised', formatAmount(project.raised)),
                      _buildTableRow('In Waiting', formatAmount(project.remaining_goal)),
                      _buildTableRow('Duration', project.project_duration_viewer ?? 'N/A'),
                      _buildTableRow('Min. Investment', formatAmount(project.minInvestmentAmount)),
                      _buildTableRow('ROI', project.annualRoi != null ? 'Annually ${project.annualRoi}%' : 'N/A'),
                      _buildTableRow('Status', project.status == 1 ? 'Running' : 'Closed',
                          valueColor: project.status == 1 ? Colors.green : Colors.red),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 30, // keep your design
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
                        backgroundColor: const Color(0xFF2E7D32), // keep your design
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: _loadingProjectIds.contains(project.id)
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : const Text(
                        'Invest Now',
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

  TableRow _buildTableRow(String label, String value, {Color valueColor = Colors.black}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8,),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.normal, fontSize: 8, color: valueColor),
          ),
        ),
      ],
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
        title: const Text(
          'Live Projects',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
            child: FutureBuilder<List<ShariahProject>>(
              future: futureShariahProjects,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No live projects found.'));
                }

                final projects = _filteredProjects.isEmpty ? snapshot.data! : _filteredProjects;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _buildProjectCard(context: context, project: project);
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
