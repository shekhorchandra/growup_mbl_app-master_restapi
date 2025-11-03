import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_button.dart';

class ProjectInvestmentDetailPage extends StatefulWidget {
  final int projectId;
  final String projectTitle;
  final String projectCategory;

  const ProjectInvestmentDetailPage({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.projectCategory,
  });

  @override
  State<ProjectInvestmentDetailPage> createState() =>
      _ProjectInvestmentDetailPageState();
}

class _ProjectInvestmentDetailPageState
    extends State<ProjectInvestmentDetailPage> {
  List<dynamic> allInvestments = [];
  List<dynamic> filteredInvestments = [];
  Set<String> downloadingInvoices = {};

  final TextEditingController _searchController = TextEditingController();

  int currentPage = 1;
  final int rowsPerPage = 10;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchInvestments();
    _searchController.addListener(() {
      _filterInvestments(_searchController.text);
    });
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy, h:mm a').format(date);
    } catch (e) {
      return rawDate;
    }
  }

  void _filterInvestments(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredInvestments = allInvestments.where((item) {
        final invoice = item['invoice_no']?.toString().toLowerCase() ?? '';
        final amount = item['amount']?.toString().toLowerCase() ?? '';
        return invoice.contains(lowerQuery) || amount.contains(lowerQuery);
      }).toList();
      currentPage = 1;
    });
  }

  List<dynamic> get currentPageItems {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage) > filteredInvestments.length
        ? filteredInvestments.length
        : startIndex + rowsPerPage;
    return filteredInvestments.sublist(startIndex, endIndex);
  }

  Future<void> _fetchInvestments() async {
    final prefs = await SharedPreferences.getInstance();
    final investorCode = prefs.getString('investor_code') ?? '';
    final token = prefs.getString('auth_token') ?? '';

    final url = Uri.parse(
      ApiConstants.projectInvestmentDetail(
        investorCode,
        widget.projectId.toString(),
      ),
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        setState(() {
          allInvestments = data;
          filteredInvestments = data;
        });
      } else {
        throw Exception('Failed to load project investments');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  void _nextPage() {
    final totalPages = (filteredInvestments.length / rowsPerPage).ceil();
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (filteredInvestments.length / rowsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: !_isSearching
            ? const Text(
          'Investment Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : TextField(
          controller: _searchController,
          autofocus: true,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search by amount or invoice...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            color: Colors.white,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: filteredInvestments.isEmpty
                  ? const Center(child: Text("No investments found"))
                  : ListView.builder(
                itemCount: currentPageItems.length,
                itemBuilder: (context, index) {
                  final item = currentPageItems[index];
                  final serial =
                      ((currentPage - 1) * rowsPerPage) + index + 1;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 3,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Serial and Invoice
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "SL: $serial",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Invoice: ${item['invoice_no'] ?? 'N/A'}",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Project Info
                          Text(
                            widget.projectTitle,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          Text(
                            "Category: ${widget.projectCategory}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                          Text(
                            "Project ID: ${widget.projectId}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(height: 8),

                          // Investment Info
                          Row(
                            children: [
                              Text(
                                "৳${item['amount'] ?? 0}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatDate(item['investment_date']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Action Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: downloadingInvoices.contains(
                                item['invoice_no'].toString())
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue,
                              ),
                            )
                                : CustomButton(
                              text: "View Invoice",
                              icon: Icons.picture_as_pdf,
                              backgroundColor: Colors.green[400]!,
                              textColor: Colors.white,
                              height: 28,
                              fontSize: 12,
                              borderRadius: 8,
                              onPressed: item['invoice_no'] != null
                                  ? () => _downloadInvoice(
                                context,
                                item['invoice_no']
                                    .toString(),
                              )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Pagination with top shadow
            Container(
              padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, -2),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomButton(
                    text: "Previous",
                    height: 30,
                    backgroundColor: Colors.grey[400]!,
                    textColor: Colors.white,
                    onPressed: currentPage > 1 ? _previousPage : null,
                  ),
                  Text(
                    'Page $currentPage of $totalPages',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  CustomButton(
                    text: "Next",
                    height: 30,
                    backgroundColor: Colors.grey[400]!,
                    textColor: Colors.white,
                    onPressed: currentPage < totalPages ? _nextPage : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadInvoice(BuildContext context, String? invoiceNo) async {
    if (invoiceNo == null || invoiceNo.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No invoice found for this record. Please contact support if this issue persists.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      downloadingInvoices.add(invoiceNo);
    });

    final url = ApiConstants.invoicePdf(invoiceNo);
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open invoice in browser.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error opening invoice: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open invoice.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        downloadingInvoices.remove(invoiceNo);
      });
    }
  }
}
