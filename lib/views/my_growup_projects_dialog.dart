import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/my_growup_projects_dialog_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/widgets/custom_button.dart';
import 'package:growup_agro/widgets/pagination_footer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyGrowupProjectsDialog extends StatefulWidget {
  const MyGrowupProjectsDialog({super.key});

  @override
  State<MyGrowupProjectsDialog> createState() => _MyGrowupProjectsDialogState();
}

class _MyGrowupProjectsDialogState extends State<MyGrowupProjectsDialog> {
  bool isLoading = false;
  List<Project> fullList = [];
  List<Project> filteredList = [];
  int currentPage = 1;
  final int rowsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  final currencyFormatter =
  NumberFormat.currency(locale: 'en_US', symbol: '৳');

  @override
  void initState() {
    super.initState();
    fetchProjects();
    _searchController.addListener(() {
      _filterList(_searchController.text);
    });
  }

  Future<void> fetchProjects() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final investorCode = prefs.getString('investor_code') ?? '';

      final url = Uri.parse(ApiConstants.investorPopUpProjects(investorCode));

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<Project> loaded =
        (jsonData['data']['projects'] as List).map((e) => Project.fromJson(e)).toList();

        setState(() {
          fullList = loaded;
          filteredList = loaded;
        });
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterList(String query) {
    final lower = query.toLowerCase();
    final result =
    fullList.where((item) => item.projectName.toLowerCase().contains(lower)).toList();
    setState(() {
      filteredList = result;
      currentPage = 1;
    });
  }

  List<Project> get currentPageItems {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  void _nextPage() {
    if (currentPage * rowsPerPage < filteredList.length) {
      setState(() => currentPage++);
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.95,
      height: MediaQuery.of(context).size.height * 0.8,
      child: SafeArea(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
                  : Column(
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My GrowUp Projects',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        CustomButton(
                          text: "Close",
                          onPressed: () => Navigator.pop(context),
                          backgroundColor: Colors.red,
                          height: 32,
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        cursorColor: Colors.green,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search,
                              color: Colors.grey, size: 20),
                          hintText: 'Search by Project Name',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  // Projects List
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(
                      child: Text(
                        'No projects found',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: currentPageItems.length,
                      itemBuilder: (context, index) {
                        final project = currentPageItems[index];
                        final sl = ((currentPage - 1) *
                            rowsPerPage) +
                            index +
                            1;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text(
                                      "SL: $sl",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      "৳${project.totalInvestment}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  project.projectName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Pagination Footer
                  PaginationFooter(
                    currentPage: currentPage,
                    totalItems: filteredList.length,
                    rowsPerPage: rowsPerPage,
                    onPrevious: _previousPage,
                    onNext: _nextPage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
