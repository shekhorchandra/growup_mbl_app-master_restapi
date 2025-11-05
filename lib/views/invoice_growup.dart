import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/invoice_growup_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/widgets/invoice_action_buttons.dart';
import 'package:growup_agro/widgets/pagination_footer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/info_row.dart';

class InvoiceGrowupPage extends StatefulWidget {
  const InvoiceGrowupPage({super.key});

  @override
  State<InvoiceGrowupPage> createState() => _InvoiceGrowupPageState();
}

class _InvoiceGrowupPageState extends State<InvoiceGrowupPage> {
  late Future<List<GrowupInvoice>> futureInvoices;

  List<GrowupInvoice> fullList = [];
  List<GrowupInvoice> filteredList = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  int currentPage = 1;
  final int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    futureInvoices = fetchInvoices();
    _searchController.addListener(() {
      _filterList(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------- Fetch Data ----------------------
  Future<List<GrowupInvoice>> fetchInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    final url = ApiConstants.invoices(investorCode);
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        final List<dynamic> list = data['investments'] ?? [];
        fullList = list.map((e) => GrowupInvoice.fromJson(e)).toList();
        filteredList = fullList;
        return fullList;
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load invoices');
    }
  }

  // ---------------------- Search ----------------------
  void _filterList(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      filteredList = fullList.where((item) {
        return item.project.name.toLowerCase().contains(q) ||
            item.project.category.toLowerCase().contains(q) ||
            item.project.code.toLowerCase().contains(q) ||
            (item.invoiceNo ?? '').toLowerCase().contains(q);
      }).toList();
      currentPage = 1;
    });
  }

  // ---------------------- Pagination ----------------------
  List<GrowupInvoice> get currentPageItems {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage) > filteredList.length
        ? filteredList.length
        : (startIndex + rowsPerPage);
    return filteredList.sublist(startIndex, endIndex);
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

  // ---------------------- AppBar ----------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      title: _isSearching
          ? TextField(
        controller: _searchController,
        cursorColor: Colors.white,
        decoration: const InputDecoration(
          hintText: 'Search by project or invoice no...',
          hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      )
          : const Text(
        'Investment Invoices',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
          onPressed: () {
            setState(() {
              if (_isSearching) _searchController.clear();
              _isSearching = !_isSearching;
            });
          },
        )
      ],
    );
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<GrowupInvoice>>(
        future: futureInvoices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No invoices found."));
          }

          return Column(
            children: [
              // 🔹 List of Invoices
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: currentPageItems.length,
                  itemBuilder: (context, index) {
                    final item = currentPageItems[index];

                    return Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.project.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            InfoRow(
                              title: "Category",
                              value: item.project.category,
                              style: TextStyle(fontSize: 12),
                              fontSize: 12,
                              showDivider: false,
                            ),
                            SizedBox(height: 4),
                            InfoRow(
                              title: "Project ID",
                              value: item.project.code,
                              style: TextStyle(fontSize: 12),
                              fontSize: 12,
                              showDivider: false,
                            ),
                            SizedBox(height: 4),
                            InfoRow(
                              title: "Invoice No",
                              value: item.invoiceNo,
                              style: TextStyle(fontSize: 12),
                              fontSize: 12,
                              showDivider: false,
                            ),
                            SizedBox(height: 4),
                            InfoRow(
                              title: "Amount",
                              value: item.amount,
                              style: TextStyle(fontSize: 12),
                              fontSize: 12,
                              showDivider: false,
                            ),
                            SizedBox(height: 4),
                            InfoRow(
                              title: "Created",
                              value: item.createdAt,
                              style: TextStyle(fontSize: 12),
                              fontSize: 12,
                              showDivider: false,
                            ),

                            const SizedBox(height: 16),

                            // Action Buttons (uses global functions)
                            InvoiceActionButtons(
                              invoiceNo: item.invoiceNo,
                              downloadUrl: ApiConstants.invoicePdf(item.invoiceNo),
                              viewUrl: ApiConstants.invoicePdf(item.invoiceNo),
                              status: "approved",
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
          );
        },
      ),
    );
  }
}
