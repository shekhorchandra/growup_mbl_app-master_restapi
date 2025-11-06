import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/investment_history_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/widgets/custom_button.dart';
import 'package:growup_agro/widgets/pagination_footer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TotalInvestmentHistoryPage extends StatefulWidget {
  const TotalInvestmentHistoryPage({super.key});

  @override
  State<TotalInvestmentHistoryPage> createState() =>
      _TotalInvestmentHistoryPageState();
}

class _TotalInvestmentHistoryPageState
    extends State<TotalInvestmentHistoryPage> {
  List<InvestmentHistoryItem> fullHistory = [];
  List<InvestmentHistoryItem> filteredHistory = [];
  int currentPage = 1;
  final int rowsPerPage = 10;
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final currencyFormatter =
  NumberFormat.currency(locale: 'en_US', symbol: '৳');

  @override
  void initState() {
    super.initState();
    _fetchInvestmentHistory();
    _searchController.addListener(() {
      _filterHistory(_searchController.text);
    });
  }

  Future<void> _fetchInvestmentHistory() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final investorCode = prefs.getString('investor_code') ?? '';

      final url = Uri.parse(ApiConstants.investmentHistory(investorCode));
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final historyList = data
            .map<InvestmentHistoryItem>(
                (e) => InvestmentHistoryItem.fromJson(e))
            .toList();

        setState(() {
          fullHistory = historyList;
          filteredHistory = fullHistory;
        });
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterHistory(String query) {
    final lower = query.toLowerCase();
    final result = fullHistory.where((item) {
      return (item.projectTitle?.toLowerCase() ?? '').contains(lower) ||
          (item.projectCategory?.toLowerCase() ?? '').contains(lower);
    }).toList();

    setState(() {
      filteredHistory = result;
      currentPage = 1;
    });
  }

  List<InvestmentHistoryItem> get currentPageItems {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;
    return filteredHistory.sublist(
      start,
      end > filteredHistory.length ? filteredHistory.length : end,
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  void _nextPage() {
    if (currentPage * rowsPerPage < filteredHistory.length) {
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Investment History',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
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
                        borderRadius: BorderRadius.circular(8), // 🔹 8dp
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
                          prefixIcon:
                          Icon(Icons.search, color: Colors.grey, size: 20),
                          hintText: 'Search by Project or Category',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  // Investment List
                  Expanded(
                    child: filteredHistory.isEmpty
                        ? const Center(
                      child: Text(
                        'No investments found',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: currentPageItems.length,
                      itemBuilder: (context, index) {
                        final item = currentPageItems[index];
                        final sl =
                            ((currentPage - 1) * rowsPerPage) +
                                index +
                                1;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8), // 🔹 Card corner radius
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
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "SL: $sl",
                                      style: const TextStyle(
                                          fontWeight:
                                          FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.black54),
                                    ),
                                    Text(
                                      _formatDate(item
                                          .firstInvestmentDate),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.projectTitle ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Category: ${item.projectCategory ?? 'N/A'}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Investment: ৳${(item.totalInvestment ?? 0).toStringAsFixed(2)}",
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
                    totalItems: filteredHistory.length,
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
