import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/investment_detail_page.dart';
import 'package:growup_agro/views/roi_details_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/investment_history_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/pagination_footer.dart';
import '../widgets/status_test.dart';

class InvestmentHistoryPage extends StatefulWidget {
  const InvestmentHistoryPage({super.key});

  @override
  State<InvestmentHistoryPage> createState() => _InvestmentHistoryPageState();
}

class _InvestmentHistoryPageState extends State<InvestmentHistoryPage> {
  late Future<List<InvestmentHistoryItem>> futureHistory;

  List<InvestmentHistoryItem> fullHistory = [];
  List<InvestmentHistoryItem> filteredHistory = [];
  int currentPage = 1;
  final int rowsPerPage = 10;
  String? investorCode;

  final TextEditingController _searchController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '৳');

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    futureHistory = fetchInvestmentHistory();
    _initialize();
    _searchController.addListener(() {
      _filterHistory(_searchController.text);
    });
  }

  Future<void> _initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    investorCode = prefs.getString('investor_code');
    setState(() {});
    futureHistory = fetchInvestmentHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterHistory(String query) {
    final filtered = fullHistory.where((item) {
      final title = item.projectTitle?.toLowerCase() ?? '';
      final category = item.projectCategory?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase()) ||
          category.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredHistory = filtered;
      currentPage = 1;
    });
  }

  List<InvestmentHistoryItem> get currentPageItems {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage) > filteredHistory.length
        ? filteredHistory.length
        : (startIndex + rowsPerPage);
    return filteredHistory.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    if (currentPage * rowsPerPage < filteredHistory.length) {
      setState(() {
        currentPage++;
      });
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  String formatDate(String? rawDate) {
    if (rawDate == null) return 'N/A';
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return rawDate;
    }
  }

  Future<List<InvestmentHistoryItem>> fetchInvestmentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    if (token.isEmpty || investorCode.isEmpty) {
      throw Exception("Missing token or investor code. Please log in again.");
    }

    final url = Uri.parse(ApiConstants.investmentHistory(investorCode));
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'];
      return data.map((e) => InvestmentHistoryItem.fromJson(e)).toList();
    } else {
      throw Exception('Investment history not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: !_isSearching
            ? const Text(
          'Investment History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        )
            : TextField(
          controller: _searchController,
          autofocus: true,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search project or category...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<InvestmentHistoryItem>>(
        future: futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No investment history found."));
          }

          if (fullHistory.isEmpty) {
            fullHistory = snapshot.data!;
            filteredHistory = fullHistory;
          }

          final currentItems = currentPageItems;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: currentItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemBuilder: (context, index) {
                    final item = currentItems[index];
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: (item.projectImage != null && item.projectImage!.isNotEmpty)
                                          ? Image.network(
                                        '${ApiConstants.imgBaseUrl}${item.projectImage}',
                                        width: 90,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 60),
                                      )
                                          : const Icon(Icons.broken_image, size: 60),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 90,
                                      child: LinearProgressIndicator(
                                        value: ((item.projectProgress ?? 0) / 100).clamp(0.0, 1.0),
                                        color: (item.projectProgress ?? 0) >= 100
                                            ? Colors.green
                                            : Colors.blue,
                                        backgroundColor: Colors.grey[300],
                                        minHeight: 5,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '${(item.projectProgress ?? 0).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Remaining Days: ${item.days_remaining ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    StatusChip(status: item.status),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.projectTitle ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Project ID: ${item.project_id}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Investment:',
                                            style: const TextStyle(fontSize: 12),
                                          ),

                                          Text(
                                            '${currencyFormatter.format(item.totalInvestment ?? 0)}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Return Of Investment:',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black87,
                                            ),
                                          ),

                                          Text(
                                            '${currencyFormatter.format(item.roiDetails ?? 0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Capital Return:',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black87,
                                            ),
                                          ),

                                          Text(
                                            '${currencyFormatter.format(item.capitalReturnDetails ?? 0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'All Investments (${item.investmentCount})',
                                      backgroundColor: Colors.green[100]!,
                                      fontSize: 10,
                                      height: 20,
                                      textColor: Colors.green,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProjectInvestmentDetailPage(
                                              projectId: item.project_id,
                                              projectTitle: item.projectTitle ?? 'N/A',
                                              projectCategory: item.projectCategory ?? 'N/A',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (investorCode != null)
                                    Expanded(
                                      child: CustomButton(
                                        text: '60/5 Days ROI',
                                        fontSize: 9,
                                        height: 20,
                                        backgroundColor: Colors.purple[100]!,
                                        textColor: Colors.purple,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => RoiDetailsPage(
                                                investorCode: investorCode!,
                                                projectId: item.project_id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              PaginationFooter(
                currentPage: currentPage,
                totalItems: filteredHistory.length,
                rowsPerPage: rowsPerPage,
                onPrevious: _previousPage,
                onNext: _nextPage,
              ),
            ],
          );
        },
      ),
    );
  }
}