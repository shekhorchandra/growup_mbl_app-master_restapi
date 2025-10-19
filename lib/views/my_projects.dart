import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/my_projects_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/project_Descriotion_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyProjectsPage(),
    );
  }
}

class MyProjectsPage extends StatefulWidget {
  final bool hideAppBar;
  const MyProjectsPage({super.key, this.hideAppBar = false});

  @override
  State<MyProjectsPage> createState() => _MyProjectsPageState();
}

class _MyProjectsPageState extends State<MyProjectsPage> {
  Set<int> _loadingProjectIds = {};
  late Future<List<MyProjectsModel>> futureMyProjectsModel;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _showBackToTopButton = false;
  List<MyProjectsModel> _allProjects = [];
  List<MyProjectsModel> _filteredProjects = [];


  @override
  void initState() {
    super.initState();
    futureMyProjectsModel = fetchMyProjectsModel();

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredProjects = _allProjects
            .where((project) =>
        project.projectName?.toLowerCase().contains(query) ?? false)
            .toList();
      });
    });

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

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<List<MyProjectsModel>> fetchMyProjectsModel() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final investorIdString = prefs.getString('investor_id');

    if (token == null || investorIdString == null) {
      throw Exception('Token or Investor ID not found');
    }

    final investorId = int.tryParse(investorIdString);
    if (investorId == null) {
      throw Exception('Invalid investor ID');
    }

    final url = Uri.parse(ApiConstants.investorProjectList(investorId.toString()));

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // if (response.statusCode == 200) {
    //   final decoded = json.decode(response.body);
    //   final List<dynamic>? projectList = decoded['data'];
    //
    //   if (projectList == null || projectList.isEmpty) {
    //     throw Exception('No My Projects found.');
    //   }
    //
    //   _allProjects = projectList
    //       .map<MyProjectsModel>((project) => MyProjectsModel.fromJson(project))
    //       .toList();
    //   _filteredProjects = _allProjects;
    //   return _allProjects;
    // } else {
    //   throw Exception('Failed to load projects');
    // }
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic>? projectList = decoded['data'];

      if (projectList == null || projectList.isEmpty) {
        print("No My Projects found."); // clean console message
        return []; // return empty list instead of crashing
      }

      _allProjects = projectList
          .map<MyProjectsModel>((project) => MyProjectsModel.fromJson(project))
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

  String formatAmount1(double? value) {
    if (value == null) return '0 Tk';
    final formatter = NumberFormat('#,##0.00');
    return '${formatter.format(value)} Tk';
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

  TableRow _buildTableRow(String label, String value, {Color valueColor = Colors.black}) {
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
            style: TextStyle(fontWeight: FontWeight.normal, fontSize: 8, color: valueColor),
          ),
        ),
      ],
    );
  }

  // conditions for showing buttons
  Widget _buildProjectCard({
    required MyProjectsModel project,
    required BuildContext context,
  }) {
    // --- Parse project start & end dates safely ---
    DateTime? startDate;
    DateTime? endDate;

    if (project.project_start_date != null && project.project_start_date!.isNotEmpty) {
      try {
        startDate = DateTime.parse(project.project_start_date!);
      } catch (_) {}
    }

    if (project.project_end_date != null && project.project_end_date!.isNotEmpty) {
      try {
        endDate = DateTime.parse(project.project_end_date!);
      } catch (_) {}
    }

    final today = DateTime.now();

    // --- Logic flags ---
    final bool isRunning = project.status == 1;

    // Convert investmentGoal and totalInvestment to numeric safely
    final double goal = double.tryParse(project.investmentGoal?.replaceAll(',', '') ?? '0') ?? 0;
    final double raised = double.tryParse(project.totalInvestment?.replaceAll(',', '') ?? '0') ?? 0;

    // ✅ Active investment condition
    final bool canInvest = isRunning && (raised <= goal);

    bool showInvestNow = false;
    bool showUpcoming = false;

    if (startDate != null && today.isBefore(startDate)) {
      showUpcoming = true;
    } else if (canInvest) {
      showInvestNow = true;
    }

    // 🕒 Countdown until start date
    String countdownText = '';
    if (showUpcoming && startDate != null) {
      final daysLeft = startDate.difference(today).inDays;
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
            // ==== CONTENT (image + table) ====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Left: Image + Project Name ---
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          project.image != null && project.image!.isNotEmpty
                              ? Image.network(
                            'https://growupagro.tech${project.image}',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/placeholder1.jpg',
                              fit: BoxFit.contain,
                            ),
                          )
                              : Image.asset(
                            'assets/images/placeholder1.jpg',
                            fit: BoxFit.contain,
                          ),
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

                // --- Right: Table ---
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
                          _buildTableRow('Business Type', project.businessTypeName ?? 'N/A'),
                          _buildTableRow('Project Duration', project.projectDurationViewer ?? 'N/A'),
                          _buildTableRow('Start Date', formatDate(project.project_start_date)),
                          _buildTableRow('Mature Date', formatDate(project.project_end_date)),
                          _buildTableRow('Investment Goal', project.investmentGoal ?? 'N/A'),
                          _buildTableRow('Min. Investment', project.minInvestmentAmount ?? 'N/A'),
                          _buildTableRow('Raised', project.totalInvestment ?? 'N/A'),
                          _buildTableRow(
                            'ROI',
                            project.annualRoi != null ? 'Annually ${project.annualRoi}%' : 'N/A',
                          ),
                          _buildTableRow(
                            'Status',
                            isRunning ? 'Running' : 'Closed',
                            valueColor: isRunning ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ==== ACTION BUTTONS ====
            if (showUpcoming)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 6),
                child: Text(
                  countdownText,
                  style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500),
                ),
              ),

            Row(
              children: [
                // --- Details Button ---
                // Expanded(
                //   flex: showInvestNow ? 1 : 2,
                //   child: SizedBox(
                //     height: 25,
                //     child: ElevatedButton(
                //       onPressed: () {
                //         final projectId = project.id;
                //         if (projectId == null) {
                //           ScaffoldMessenger.of(context).showSnackBar(
                //             const SnackBar(content: Text('Project ID is missing')),
                //           );
                //           return;
                //         }
                //
                //         Navigator.push(
                //           context,
                //           MaterialPageRoute(
                //             builder: (_) => ProjectDescriptionPage(
                //               projectId: projectId,
                //               investorCode: "",
                //             ),
                //           ),
                //         );
                //       },
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: Colors.blueGrey,
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(8),
                //         ),
                //       ),
                //       child: const Text(
                //         'Details',
                //         style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                //       ),
                //     ),
                //   ),
                // ),

                if (showInvestNow) ...[
                  // const SizedBox(width: 8),
                  // --- Invest Now Button ---
                  Expanded(
                    child: SizedBox(
                      height: 25,
                      child: ElevatedButton(
                        onPressed: () async {
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
                                projectId: project.id!,
                                investorCode: investorCode,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'RE-INVEST',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
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
        title: const Text(
          'My Projects',
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
            child: FutureBuilder<List<MyProjectsModel>>(
              future: futureMyProjectsModel,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No My Projects found.'));
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
