import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/invoice_roi_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/widgets/info_row.dart';
import 'package:growup_agro/widgets/invoice_action_buttons.dart';
import 'package:growup_agro/widgets/pagination_footer.dart';
import 'package:growup_agro/widgets/status_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceRoiPage extends StatefulWidget {
  const InvoiceRoiPage({super.key});

  @override
  State<InvoiceRoiPage> createState() => _InvoiceRoiPageState();
}

class _InvoiceRoiPageState extends State<InvoiceRoiPage> {
  late Future<List<RoiInvoice>> futureRois;
  List<RoiInvoice> fullList = [];
  List<RoiInvoice> filteredList = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  int currentPage = 1;
  final int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    futureRois = fetchRois();
    _searchController.addListener(() => _filterList(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------- Fetch Data ----------------------
  Future<List<RoiInvoice>> fetchRois() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    final url = Uri.parse(ApiConstants.roiListinvoice(investorCode));
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true && data['data'] != null) {
        final List<dynamic> list = data['data'];
        fullList = list.map((e) => RoiInvoice.fromJson(e)).toList();
        filteredList = fullList;
        return fullList;
      }
    }
    return [];
  }

  // ---------------------- Search ----------------------
  void _filterList(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      filteredList = fullList.where((item) {
        return item.projectName.toLowerCase().contains(q) ||
            item.projectCategory.toLowerCase().contains(q) ||
            item.projectCode.toLowerCase().contains(q) ||
            item.invoiceNo.toLowerCase().contains(q);
      }).toList();
      currentPage = 1;
    });
  }

  // ---------------------- Pagination ----------------------
  List<RoiInvoice> get currentPageItems {
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
          hintText: 'Search by project name, category, or invoice no...',
          hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      )
          : const Text(
        'ROI Invoices',
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
      body: FutureBuilder<List<RoiInvoice>>(
        future: futureRois,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No ROI invoices found."));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: currentPageItems.length,
                  itemBuilder: (context, index) {
                    final item = currentPageItems[index];
                    final amount = double.tryParse(item.totalRoi) ?? 0.0;

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
                            // Header row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.projectName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            InfoRow(
                                title: "Category",
                                value: item.projectCategory,
                                fontSize: 12,
                                style: TextStyle(fontSize: 12),
                                showDivider: false),
                            const SizedBox(height: 4),

                            InfoRow(
                                title: "Project ID",
                                value: item.projectCode,
                                fontSize: 12,
                                style: TextStyle(fontSize: 12),
                                showDivider: false),
                            const SizedBox(height: 4),

                            InfoRow(
                                title: "Invoice No",
                                value: item.invoiceNo,
                                fontSize: 12,
                                style: TextStyle(fontSize: 12),
                                showDivider: false),
                            const SizedBox(height: 4),

                            InfoRow(
                                title: "ROI Amount",
                                value: "৳ ${amount.toStringAsFixed(2)}",
                                fontSize: 12,
                                style: TextStyle(fontSize: 12),
                                showDivider: false),
                            const SizedBox(height: 14),

                            // 🔹 Action Buttons
                            InvoiceActionButtons(
                              invoiceNo: item.invoiceNo,
                              downloadUrl:
                              ApiConstants.roiInvoiceDownload(item.invoiceNo),
                              viewUrl:
                              ApiConstants.roiInvoiceDownload(item.invoiceNo),
                              status: "approved",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Pagination footer
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
