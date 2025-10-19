// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:growup_agro/utils/api_constants.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
//
// import '../models/upcoming_projects_model.dart';
// import 'project_Descriotion_page.dart';
//
// class UpcomingProjectsPage extends StatefulWidget {
//   final bool hideAppBar;
//   const UpcomingProjectsPage({super.key, this.hideAppBar = false});
//
//   @override
//   State<UpcomingProjectsPage> createState() => _UpcomingProjectsPageState();
// }
//
// class _UpcomingProjectsPageState extends State<UpcomingProjectsPage> {
//   Set<int> _loadingProjectIds = {};
//   late Future<List<UpcomingProject>> futureUpcomingProjects;
//   final ScrollController _scrollController = ScrollController();
//   bool _showBackToTopButton = false;
//
//   List<UpcomingProject> _allProjects = [];
//   List<UpcomingProject> _filteredProjects = [];
//   final TextEditingController _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     futureUpcomingProjects = fetchUpcomingProjects();
//     _searchController.addListener(_onSearchChanged);
//
//     _scrollController.addListener(() {
//       if (_scrollController.offset >= 300) {
//         if (!_showBackToTopButton) setState(() => _showBackToTopButton = true);
//       } else {
//         if (_showBackToTopButton) setState(() => _showBackToTopButton = false);
//       }
//     });
//   }
//
//   void _onSearchChanged() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredProjects = _allProjects.where((project) {
//         return project.projectName.toLowerCase().contains(query);
//       }).toList();
//     });
//   }
//
//   void _scrollToTop() {
//     _scrollController.animateTo(
//       0,
//       duration: const Duration(milliseconds: 500),
//       curve: Curves.easeInOut,
//     );
//   }
//
//   Future<List<UpcomingProject>> fetchUpcomingProjects() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token') ?? '';
//
//     final url = Uri.parse("https://growupagro.tech/api/all-projects");
//     final response = await http.get(url, headers: {
//       'Authorization': 'Bearer $token',
//       'Content-Type': 'application/json',
//     });
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final projectsMap = data['projects'] as Map<String, dynamic>?;
//
//       if (projectsMap == null) return [];
//
//       final List<UpcomingProject> allProjects = [];
//
//       projectsMap.forEach((category, list) {
//         if (list is List) {
//           for (var item in list) {
//             try {
//               final project = UpcomingProject.fromJson(Map<String, dynamic>.from(item));
//               project.category = category; // store category
//               allProjects.add(project);
//             } catch (e) {
//               debugPrint('Project parse error: $e');
//             }
//           }
//         }
//       });
//
//       return allProjects;
//     } else {
//       throw Exception('Failed to fetch projects');
//     }
//   }
//
//
//
//
//
//
//
//   String formatDate(String? rawDate) {
//     if (rawDate == null || rawDate.isEmpty) return 'N/A';
//     try {
//       final date = DateTime.parse(rawDate); // parse "2025-09-24"
//       return DateFormat('dd MMM yyyy').format(date); // → "24 Sep 2025"
//     } catch (_) {
//       return rawDate; // fallback
//     }
//   }
//
//   String formatAmount(dynamic amount) {
//     if (amount == null || amount.toString().isEmpty) return '0 Tk';
//     final formatter = NumberFormat('#,##0');
//     return '${formatter.format(int.tryParse(amount.toString()) ?? 0)} Tk';
//   }
//
//   String formatAmount1(double? value) {
//     if (value == null) return '0 Tk';
//     final formatter = NumberFormat('#,##0.00');
//     return '${formatter.format(value)} Tk';
//   }
//
//   Widget _buildProjectCard({
//     required UpcomingProject project,
//     required BuildContext context,
//   }) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 5,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column( // ⬅️ CHANGE 1: Use a Column to stack the content Row and the Button
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 1. Content Row (Image + Details)
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Left: Image
//                 Expanded(
//                   flex: 1, // adjust ratio between image and table (e.g. 4:6)
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Container(
//                       color: Colors.white, // background if aspect ratio doesn’t match
//                       child: project.imageUrl != null && project.imageUrl!.isNotEmpty
//                           ? Image.network(
//                         project.imageUrl!,
//                         fit: BoxFit.contain, // ✅ keeps full image visible
//                         errorBuilder: (_, __, ___) =>
//                             Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.contain),
//                       )
//                           : Image.asset('assets/images/placeholder1.jpg', fit: BoxFit.contain),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 // Right: Table Details
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         project.projectName,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                           color: Colors.green,
//                         ),
//                       ),
//                       Table(
//                         columnWidths: const {
//                           0: FlexColumnWidth(4),
//                           1: FlexColumnWidth(4),
//                         },
//                         defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//                         children: [
//                           _buildTableRow(
//                             'Business Type',
//                             project.businessType_name ?? 'N/A',
//                           ),
//                           _buildTableRow(
//                             'Investment Time',
//                             '${project.remaining_opportunity_days ?? 0} days',
//                           ),
//                           _buildTableRow(
//                             'Project Duration',
//                             "${project.projectDurationViewer ?? 'N/A'}",
//                           ),
//                           _buildTableRow(
//                             'Start Date',
//                             formatDate(project.project_start_date),
//                           ),
//                           _buildTableRow(
//                             'Mature Date',
//                             formatDate(project.project_end_date),
//                           ),
//                           _buildTableRow(
//                             'Investment Goal',
//                             formatAmount(project.investmentGoal),
//                           ),
//                           _buildTableRow(
//                             'Min. Investment',
//                             formatAmount1(project.min_investment_amount ?? 0),
//                           ),
//                           _buildTableRow('Raised', formatAmount(project.raised)),
//                           _buildTableRow(
//                             'In Waiting',
//                             formatAmount(project.remaining_goal),
//                           ),
//                           _buildTableRow(
//                             'ROI',
//                             project.annualRoi != null
//                                 ? 'Annually ${project.annualRoi}%'
//                                 : 'N/A',
//                           ),
//                           _buildTableRow(
//                             'Status',
//                             project.status == 1 ? 'Running' : 'Closed',
//                             valueColor: project.status == 1
//                                 ? Colors.green
//                                 : Colors.red,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 8), // ⬅️ Add spacing before the button
//
//             // 2. Full-Width Button (Moved Outside the Row)
//             SizedBox( // ⬅️ CHANGE 2: The button is a direct child of the main Column
//               width: double.infinity, // Ensures button takes full width of the card's padding
//               height: 35, // Increased height for better visibility (was 22)
//               child: ElevatedButton(
//                 onPressed: _loadingProjectIds.contains(project.id)
//                     ? null
//                     : () async {
//                   final projectId = project.id;
//                   if (projectId == null) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Project ID is missing'),
//                       ),
//                     );
//                     return;
//                   }
//
//                   setState(() {
//                     _loadingProjectIds.add(projectId);
//                   });
//
//                   try {
//                     final prefs = await SharedPreferences.getInstance();
//                     final investorCode = prefs.getString(
//                       'investor_code',
//                     );
//                     if (investorCode == null || investorCode.isEmpty) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Investor code not found.'),
//                         ),
//                       );
//                       return;
//                     }
//
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => ProjectDescriptionPage(
//                           projectId: projectId,
//                           investorCode: investorCode,
//                         ),
//                       ),
//                     );
//                   } finally {
//                     setState(() {
//                       _loadingProjectIds.remove(projectId);
//                     });
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF2E7D32),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8), // Optional: Match card border radius
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 4),
//                   minimumSize: const Size(
//                     double.infinity,
//                     35,
//                   ), // Sets minimum size to full width
//                 ),
//                 child: _loadingProjectIds.contains(project.id)
//                     ? const SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 )
//                     : const Text(
//                   'Invest Now',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 14, // Increased font size for better UX
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   TableRow _buildTableRow(
//       String label,
//       String value, {
//         Color valueColor = Colors.black,
//       }) {
//     return TableRow(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 2),
//           child: Text(
//             '$label:',
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 2),
//           child: Text(
//             value,
//             style: TextStyle(
//               fontWeight: FontWeight.normal,
//               fontSize: 8,
//               color: valueColor,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: widget.hideAppBar
//           ? null
//           : AppBar(
//         backgroundColor: const Color(0xFF2E7D32),
//         foregroundColor: Colors.white,
//         title: const Text(
//           'Upcoming Projects',
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search by project name...',
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: const BorderSide(color: Colors.grey),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: FutureBuilder<List<UpcomingProject>>(
//               future: futureUpcomingProjects,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (snapshot.hasError) {
//                   return Center(child: Text('Upcoming projects coming soon.'));
//                 } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return const Center(
//                     child: Text('No upcoming projects found.'),
//                   );
//                 }
//
//                 final projects = _filteredProjects.isEmpty
//                     ? snapshot.data!
//                     : _filteredProjects;
//
//                 return ListView.builder(
//                   controller: _scrollController,
//                   itemCount: projects.length,
//                   itemBuilder: (context, index) {
//                     final project = projects[index];
//
//                     // Show header if first project or category changed
//                     bool showHeader = index == 0 ||
//                         project.category != projects[index - 1].category;
//
//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (showHeader)
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                             child: Text(
//                               project.category ?? 'Other',
//                               style: const TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue),
//                             ),
//                           ),
//                         _buildProjectCard(context: context, project: project),
//                       ],
//                     );
//                   },
//                 );
//
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: _showBackToTopButton
//           ? FloatingActionButton(
//         onPressed: _scrollToTop,
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.arrow_upward, color: Colors.white),
//       )
//           : null,
//     );
//   }
// }
