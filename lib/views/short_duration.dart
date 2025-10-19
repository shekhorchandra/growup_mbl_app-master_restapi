import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/project_Descriotion_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/short_project_model.dart';

class ShortProjectsPage extends StatefulWidget {
  final bool hideAppBar;
  const ShortProjectsPage({super.key, this.hideAppBar = false});

  @override
  State<ShortProjectsPage> createState() => _ShortProjectsPageState();
}

class _ShortProjectsPageState extends State<ShortProjectsPage> {
  Set<int> _loadingProjectIds = {};
  late Future<List<ShortProjectModel>> futureShortProjects;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<ShortProjectModel> _allProjects = [];
  List<ShortProjectModel> _filteredProjects = [];
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    futureShortProjects = fetchShortTermProjects();
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

  Future<List<ShortProjectModel>> fetchShortTermProjects() async {
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
      final List<dynamic>? shortTermProjects = decoded['projects']?['Short Term'];

      if (shortTermProjects == null) throw Exception('Short Term projects not found.');

      _allProjects = shortTermProjects
          .map<ShortProjectModel>((project) => ShortProjectModel.fromJson(project))
          .toList();
      _filteredProjects = _allProjects;
      return _allProjects;
    } else {
      throw Exception('Failed to load projects');
    }
  }
  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(rawDate); // parse "2025-09-24"
      return DateFormat('dd MMM yyyy').format(date); // → "24 Sep 2025"
    } catch (_) {
      return rawDate; // fallback
    }
  }

  String formatAmount(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatted = NumberFormat('#,##0').format(number);
    return '$formatted Tk';
  }


  // String formatAmount1(double? value) {
  //   if (value == null) return '0 Tk';
  //   final formatter = NumberFormat('#,##0.00');
  //   return '${formatter.format(value)} Tk';
  // }

  // Widget _buildProjectCard({required ShortProjectModel project, required BuildContext context}) {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     elevation: 5,
  //     child: Padding(
  //       padding: const EdgeInsets.all(4.0),
  //       child: Column( // ⬅️ CHANGE 1: Use a Column to stack the content Row and the Button
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // 1. Content Row (Image + Details)
  //           Row(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // Left: Image
  //               Expanded(
  //                 flex: 1, // adjust ratio between image and table (e.g. 4:6)
  //                 child: ClipRRect(
  //                   borderRadius: BorderRadius.circular(8),
  //                   child: Container(
  //                     color: Colors.white, // background if aspect ratio doesn’t match
  //                     child: project.imageUrl != null && project.imageUrl!.isNotEmpty
  //                         ? Image.network(
  //                       project.imageUrl!,
  //                       fit: BoxFit.contain, // ✅ keeps full image visible
  //                       errorBuilder: (_, __, ___) =>
  //                           Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.contain),
  //                     )
  //                         : Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.contain),
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               // Right: Table Details (This is where the button *used* to be)
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       project.projectName ?? 'N/A',
  //                       style: const TextStyle(
  //                           fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
  //                     ),
  //                     Table(
  //                       columnWidths: const {
  //                         0: FlexColumnWidth(4),
  //                         1: FlexColumnWidth(4),
  //                       },
  //                       defaultVerticalAlignment: TableCellVerticalAlignment.middle,
  //                       children: [
  //                         _buildTableRow('Business Type', project.name ?? 'N/A'),
  //                         _buildTableRow('Investment Time',
  //                             '${project.remaining_opportunity_days ?? 0} days'),
  //                         _buildTableRow('Project Duration', "${project.project_duration_viewer ?? 'N/A'}"),
  //                         _buildTableRow('Start Date', formatDate(project.project_start_date)),
  //                         _buildTableRow('Mature Date', formatDate(project.project_end_date)),
  //                         _buildTableRow('Investment Goal', formatAmount(project.investmentGoal)),
  //                         _buildTableRow(
  //                           'Min. Investment',
  //                           formatAmount1(project.min_investment_amount ?? 0),
  //                         ),
  //                         _buildTableRow('Raised', formatAmount(project.raised)),
  //                         _buildTableRow('In Waiting', formatAmount(project.remaining_goal)),
  //                         _buildTableRow(
  //                           'ROI',
  //                           project.annualRoi != null ? 'Annually ${project.annualRoi}%' : 'N/A',
  //                         ),
  //                         _buildTableRow(
  //                           'Status',
  //                           project.status == 1 ? 'Running' : 'Closed',
  //                           valueColor: project.status == 1 ? Colors.green : Colors.red,
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //
  //           const SizedBox(height: 8), // ⬅️ Add spacing before the button
  //
  //           // 2. Full-Width Button (Moved Outside the Row)
  //           SizedBox( // ⬅️ CHANGE 2: The button is now a direct child of the main Column
  //             width: double.infinity, // This ensures it takes the full width of the card's padding
  //             height: 35, // Adjusted height for better visibility (was 22)
  //             child: ElevatedButton(
  //               onPressed: _loadingProjectIds.contains(project.id)
  //                   ? null
  //                   : () async {
  //                 final projectId = project.id;
  //                 if (projectId == null) {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(content: Text('Project ID is missing')),
  //                   );
  //                   return;
  //                 }
  //
  //                 setState(() {
  //                   _loadingProjectIds.add(projectId);
  //                 });
  //
  //                 try {
  //                   final prefs = await SharedPreferences.getInstance();
  //                   final investorCode = prefs.getString('investor_code');
  //                   if (investorCode == null || investorCode.isEmpty) {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(content: Text('Investor code not found.')),
  //                     );
  //                     return;
  //                   }
  //
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (_) => ProjectDescriptionPage(
  //                         projectId: projectId,
  //                         investorCode: investorCode,
  //                       ),
  //                     ),
  //                   );
  //                 } finally {
  //                   setState(() {
  //                     _loadingProjectIds.remove(projectId);
  //                   });
  //                 }
  //               },
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: const Color(0xFF2E7D32),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(8), // Optional: Match card border radius
  //                 ),
  //                 padding: const EdgeInsets.symmetric(vertical: 4),
  //                 minimumSize: const Size(double.infinity, 35), // Sets minimum size to full width
  //               ),
  //               child: _loadingProjectIds.contains(project.id)
  //                   ? const SizedBox(
  //                 width: 16,
  //                 height: 16,
  //                 child: CircularProgressIndicator(
  //                   color: Colors.white,
  //                   strokeWidth: 2,
  //                 ),
  //               )
  //                   : const Text(
  //                 'Invest Now',
  //                 style: TextStyle(color: Colors.white, fontSize: 14), // Increased font size
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildProjectCard({required ShortProjectModel project, required BuildContext context}) {
  //   // print("UI investment goal: ${project.investmentGoal}");
  //   // Parse project start date safely
  //   DateTime? startDate;
  //   if (project.project_start_date != null && project.project_start_date!.isNotEmpty) {
  //     try {
  //       startDate = DateTime.parse(project.project_start_date!);
  //     } catch (_) {}
  //   }
  //
  //   final today = DateTime.now();
  //   // Button should only be shown if today < startDate
  //   final bool showInvestButton = (startDate != null && today.isBefore(startDate));
  //
  //   return Card(
  //     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     elevation: 5,
  //     child: Padding(
  //       padding: const EdgeInsets.all(4.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // ==== CONTENT (Image + Table) ====
  //           Row(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // Left: Image
  //               // Expanded(
  //               //   flex: 1,
  //               //   child: ClipRRect(
  //               //     borderRadius: BorderRadius.circular(8),
  //               //     child: Container(
  //               //       color: Colors.white,
  //               //       child: project.imageUrl != null && project.imageUrl!.isNotEmpty
  //               //           ? Image.network(
  //               //         project.imageUrl!,
  //               //         fit: BoxFit.contain,
  //               //         errorBuilder: (_, __, ___) =>
  //               //             Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.contain),
  //               //       )
  //               //           : Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.contain),
  //               //     ),
  //               //   ),
  //               // ),
  //
  //               Expanded(
  //                 flex: 1,
  //                 child: ClipRRect(
  //                   borderRadius: BorderRadius.circular(8),
  //                   child: Container(
  //                     color: Colors.white,
  //                     child: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         // 🖼️ Image section
  //                         project.imageUrl != null && project.imageUrl!.isNotEmpty
  //                             ? Image.network(
  //                           project.imageUrl!,
  //                           fit: BoxFit.contain,
  //                           // height: 100, // adjust height as needed
  //                           errorBuilder: (_, __, ___) => Image.asset(
  //                             'assets/images/placeholder1.jpg',
  //                             fit: BoxFit.contain,
  //                             // height: 100,
  //                           ),
  //                         )
  //                             : Image.asset(
  //                           'assets/images/placeholder1.jpg',
  //                           fit: BoxFit.contain,
  //                           // height: 100,
  //                         ),
  //
  //                         const SizedBox(height: 6),
  //
  //                         // 📝 Project name under image
  //                         Text(
  //                           project.projectName ?? 'N/A',
  //                           textAlign: TextAlign.center,
  //                           style: const TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                             fontSize: 12,
  //                             color: Colors.green,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               // Right: Table
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     // Text(
  //                     //   project.projectName ?? 'N/A',
  //                     //   style: const TextStyle(
  //                     //       fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
  //                     // ),
  //                     Table(
  //                       columnWidths: const {
  //                         0: FlexColumnWidth(4),
  //                         1: FlexColumnWidth(4),
  //                       },
  //                       defaultVerticalAlignment: TableCellVerticalAlignment.middle,
  //                       children: [
  //                         _buildTableRow('Business Type', project.name ?? 'N/A'),
  //                         _buildTableRow('Investment Time',
  //                             '${project.remaining_opportunity_days ?? 0} days'),
  //                         _buildTableRow('Project Duration', "${project.project_duration_viewer ?? 'N/A'}"),
  //                         _buildTableRow('Start Date', formatDate(project.project_start_date)),
  //                         _buildTableRow('Mature Date', formatDate(project.project_end_date)),
  //
  //
  //                         _buildTableRow('Investment Goal', formatAmount(project.investmentGoal)),
  //
  //
  //
  //                         _buildTableRow('Min. Investment',
  //                             formatAmount(project.min_investment_amount ?? 0)),
  //                         _buildTableRow('Raised', formatAmount(project.raised)),
  //                         _buildTableRow('In Waiting', formatAmount(project.remaining_goal)),
  //                         _buildTableRow(
  //                           'ROI',
  //                           project.annualRoi != null ? 'Annually ${project.annualRoi}%' : 'N/A',
  //                         ),
  //                         _buildTableRow(
  //                           'Status',
  //                           project.status == 1 ? 'Running' : 'Closed',
  //                           valueColor: project.status == 1 ? Colors.green : Colors.red,
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //
  //           const SizedBox(height: 8),
  //
  //           // ==== BUTTON ROW (Details + Invest Now) ====
  //           Row(
  //             children: [
  //               // Details Button
  //               Expanded(
  //                 child: SizedBox(
  //                   height: 35,
  //                   child: ElevatedButton(
  //                     onPressed: () {
  //                       final projectId = project.id;
  //                       if (projectId == null) {
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           const SnackBar(content: Text('Project ID is missing')),
  //                         );
  //                         return;
  //                       }
  //
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(
  //                           builder: (_) => ProjectDescriptionPage(
  //                             projectId: projectId,
  //                             investorCode: "", // if you don’t need investorCode for details
  //                           ),
  //                         ),
  //                       );
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.blueGrey,
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                     ),
  //                     child: const Text(
  //                       'Details',
  //                       style: TextStyle(color: Colors.white, fontSize: 14),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //
  //               // Only show spacing if Invest button is visible
  //               if (showInvestButton) const SizedBox(width: 8),
  //
  //               // Invest Now Button (only if today < startDate)
  //               if (showInvestButton)
  //                 Expanded(
  //                   child: SizedBox(
  //                     height: 35,
  //                     child: ElevatedButton(
  //                       onPressed: _loadingProjectIds.contains(project.id)
  //                           ? null
  //                           : () async {
  //                         final projectId = project.id;
  //                         if (projectId == null) {
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             const SnackBar(content: Text('Project ID is missing')),
  //                           );
  //                           return;
  //                         }
  //
  //                         setState(() {
  //                           _loadingProjectIds.add(projectId);
  //                         });
  //
  //                         try {
  //                           final prefs = await SharedPreferences.getInstance();
  //                           final investorCode = prefs.getString('investor_code');
  //                           if (investorCode == null || investorCode.isEmpty) {
  //                             ScaffoldMessenger.of(context).showSnackBar(
  //                               const SnackBar(content: Text('Investor code not found.')),
  //                             );
  //                             return;
  //                           }
  //
  //                           Navigator.push(
  //                             context,
  //                             MaterialPageRoute(
  //                               builder: (_) => ProjectDescriptionPage(
  //                                 projectId: projectId,
  //                                 investorCode: investorCode,
  //                               ),
  //                             ),
  //                           );
  //                         } finally {
  //                           setState(() {
  //                             _loadingProjectIds.remove(projectId);
  //                           });
  //                         }
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: const Color(0xFF2E7D32),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                       ),
  //                       child: _loadingProjectIds.contains(project.id)
  //                           ? const SizedBox(
  //                         width: 16,
  //                         height: 16,
  //                         child: CircularProgressIndicator(
  //                           color: Colors.white,
  //                           strokeWidth: 2,
  //                         ),
  //                       )
  //                           : const Text(
  //                         'Invest Now',
  //                         style: TextStyle(color: Colors.white, fontSize: 14),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           )
  //
  //
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildProjectCard({
    required ShortProjectModel project,
    required BuildContext context,
  }) {
    final now = DateTime.now();

    // ✅ Parse all relevant dates safely
    DateTime? startDate = project.project_start_date != null && project.project_start_date!.isNotEmpty
        ? DateTime.tryParse(project.project_start_date!)
        : null;

    DateTime? roiStartDate = project.roi_start_date != null && project.roi_start_date!.isNotEmpty
        ? DateTime.tryParse(project.roi_start_date!)
        : null;

    DateTime? endDate = project.project_end_date != null && project.project_end_date!.isNotEmpty
        ? DateTime.tryParse(project.project_end_date!)
        : null;

    // ✅ Logic flags
    final bool isRunning = project.status == 1;
    final double goal = project.investmentGoal ?? 0;
    final int raised = project.raised ?? 0;

    // ✅ Investment condition
    final bool canInvest = isRunning && (raised <= goal);

    bool showInvestNow = false;
    bool showUpcoming = false;

    if (startDate != null && now.isBefore(startDate)) {
      showUpcoming = true;
    } else if (canInvest) {
      showInvestNow = true;
    }

    // 🕒 Countdown text for upcoming projects
    // String countdownText = '';
    // if (showUpcoming && startDate != null) {
    //   final daysLeft = startDate.difference(now).inDays;
    //   if (daysLeft > 1) {
    //     countdownText = 'Starts in $daysLeft days';
    //   } else if (daysLeft == 1) {
    //     countdownText = 'Starts tomorrow';
    //   } else {
    //     countdownText = 'Starts soon';
    //   }
    // }

    // ✅ Determine project status text and color
    String statusText;
    Color statusColor;

    if (endDate != null && now.isAfter(endDate)) {
      statusText = 'Matured';
      statusColor = Colors.red;
    } else if (startDate != null && now.isBefore(startDate)) {
      statusText = 'Upcoming';
      statusColor = Colors.orange;
    } else if (startDate != null &&
        roiStartDate != null &&
        now.isAfter(startDate) &&
        now.isBefore(roiStartDate)) {
      statusText = 'Investment Collecting';
      statusColor = Colors.blue;
    } else if (roiStartDate != null &&
        endDate != null &&
        now.isAfter(roiStartDate) &&
        now.isBefore(endDate)) {
      statusText = 'Running';
      statusColor = Colors.green;
    } else {
      statusText = 'Unknown';
      statusColor = Colors.grey;
    }

    // 🕒 Countdown calculation
    // String countdownText = '';
    // if (showUpcoming && startDate != null) {
    //   final daysLeft = startDate.difference(today).inDays;
    //   if (daysLeft > 1) {
    //     countdownText = 'Starts in $daysLeft days';
    //   } else if (daysLeft == 1) {
    //     countdownText = 'Starts tomorrow';
    //   } else {
    //     countdownText = 'Starts soon';
    //   }
    // }

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
                // Left: Image + Project Name
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

                // Right: Table Details
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
                          _buildTableRow(
                            'ROI',
                            project.annualRoi != null ? 'Annually ${project.annualRoi}%' : 'N/A',
                          ),
                          _buildTableRow(
                            'Status',
                            statusText,
                            valueColor: statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ==== BUTTON ROW (Invest Now / Upcoming) ====
            Column(
              children: [
                Row(
                  children: [
                    if (showUpcoming) ...[
                      // const SizedBox(width: 8),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (showInvestNow) ...[
                      // const SizedBox(width: 8),
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
                  ],
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'Short Term Projects',
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
            child: FutureBuilder<List<ShortProjectModel>>(
              future: futureShortProjects,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No short term projects found.'));
                }

                final projects =
                _filteredProjects.isEmpty ? snapshot.data! : _filteredProjects;

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
