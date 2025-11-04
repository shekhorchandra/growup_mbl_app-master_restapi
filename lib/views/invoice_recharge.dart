import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/recharge_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/widgets/info_row.dart';
import 'package:growup_agro/widgets/invoice_action_buttons.dart';
import 'package:growup_agro/widgets/pagination_footer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/status_test.dart';

class InvoiceRechargePage extends StatefulWidget {
  const InvoiceRechargePage({super.key});

  @override
  State<InvoiceRechargePage> createState() => _InvoiceRechargePageState();
}

class _InvoiceRechargePageState extends State<InvoiceRechargePage> {
  late Future<List<Recharge>> futureRecharges;

  List<Recharge> fullList = [];
  List<Recharge> filteredList = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  int currentPage = 1;
  final int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    futureRecharges = fetchRecharges();
    _searchController.addListener(() => _filterList(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------- Fetch Data ----------------------
  Future<List<Recharge>> fetchRecharges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    final url = Uri.parse(ApiConstants.recharges(investorCode));
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == "success") {
        final List<dynamic> list = data['recharges'] ?? [];
        fullList = list.map((e) => Recharge.fromJson(e)).toList();
        filteredList = fullList;
        return fullList;
      } else {
        return [];
      }
    } else {
      throw Exception("Failed to load recharges");
    }
  }

  // ---------------------- Search ----------------------
  void _filterList(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      filteredList = fullList.where((item) {
        final date = (item.date ?? '').toLowerCase();
        final amount = (item.amount ?? '').toLowerCase();
        final method = (item.method ?? '').toLowerCase();
        final status = (item.status ?? '').toLowerCase();
        final note = (item.note ?? '').toLowerCase();
        return date.contains(q) ||
            amount.contains(q) ||
            method.contains(q) ||
            status.contains(q) ||
            note.contains(q);
      }).toList();
      currentPage = 1;
    });
  }

  // ---------------------- Pagination ----------------------
  List<Recharge> get currentPageItems {
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
          hintText: 'Search by date, amount, method, or status...',
          hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      )
          : const Text(
        'Recharge Invoices',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search,
              color: Colors.white),
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
      body: FutureBuilder<List<Recharge>>(
        future: futureRecharges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No recharges found."));
          }

          return Column(
            children: [
              // 🔹 Recharge List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: currentPageItems.length,
                  itemBuilder: (context, index) {
                    final item = currentPageItems[index];
                    final status = item.status ?? 'N/A';
                    final statusColor = _getStatusColor(status);

                    return Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Recharge Date: ${item.date ?? '-'}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green),
                                ),
                                StatusChip(status: status)
                              ],
                            ),
                            const SizedBox(height: 8),
                            InfoRow(
                                title: "Amount",
                                value: "${item.amount ?? '-'} Tk",
                                fontSize: 12,
                                style: TextStyle(fontSize: 12),
                                showDivider: false),
                            const SizedBox(height: 4),

                            InfoRow(
                                title: "Method",
                                value: item.method ?? '-',
                                fontSize: 12,
                                style: TextStyle(fontSize: 12),
                                showDivider: false),
                            const SizedBox(height: 4),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Note:", style: TextStyle(fontSize: 12, color: Colors.black),),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100, // light background
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.note ?? '-',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 🔹 Action Buttons (View & Download)
                            InvoiceActionButtons(
                              invoiceNo: item.invoiceNo,
                              downloadUrl:
                              ApiConstants.rechargeInvoicePdf(item.invoiceNo ?? ''),
                              viewUrl:
                              ApiConstants.rechargeInvoicePdf(item.invoiceNo ?? ''),
                              status: status,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🔹 Pagination Footer
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

  // ---------------------- Helpers ----------------------
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
