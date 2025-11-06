import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/total_income_dialog_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/widgets/custom_button.dart';
import 'package:growup_agro/widgets/pagination_footer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TotalIncomeDialog extends StatefulWidget {
  const TotalIncomeDialog({super.key});

  @override
  State<TotalIncomeDialog> createState() => _TotalIncomeDialogState();
}

class _TotalIncomeDialogState extends State<TotalIncomeDialog> {
  List<totalRoiDetail> fullList = [];
  List<totalRoiDetail> filteredList = [];
  bool isLoading = false;
  int currentPage = 1;
  final int rowsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  final currencyFormatter =
  NumberFormat.currency(locale: 'en_US', symbol: '৳');

  @override
  void initState() {
    super.initState();
    fetchTotalIncome();
    _searchController.addListener(() {
      _filterList(_searchController.text);
    });
  }

  Future<void> fetchTotalIncome() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final investorCode = prefs.getString('investor_code') ?? '';

      final response = await http.get(
        Uri.parse(
            'https://growupagro.tech/api/investor/pop-up/total-income?investor_code=$investorCode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<totalRoiDetail> loadedList =
        (jsonData['data']['roi_details'] as List)
            .map((e) => totalRoiDetail.fromJson(e))
            .toList();

        setState(() {
          fullList = loadedList;
          filteredList = loadedList;
        });
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
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
    final result = fullList
        .where((item) => item.projectName.toLowerCase().contains(lower))
        .toList();
    setState(() {
      filteredList = result;
      currentPage = 1;
    });
  }

  List<totalRoiDetail> get currentPageItems {
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Income',
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

                  // Data List
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(
                      child: Text(
                        'No income data found',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: currentPageItems.length,
                      itemBuilder: (context, index) {
                        final item = currentPageItems[index];
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
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.projectName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Total ROI: ${currencyFormatter.format(item.totalRoi)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
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
