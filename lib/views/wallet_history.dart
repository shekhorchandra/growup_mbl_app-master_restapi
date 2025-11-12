import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/wallet_history_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/widgets/pagination_footer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/invoice_action_buttons.dart';
import '../widgets/status_test.dart';

class WalletHistoryPage extends StatefulWidget {
  const WalletHistoryPage({super.key});

  @override
  State<WalletHistoryPage> createState() => _WalletHistoryPageState();
}

class _WalletHistoryPageState extends State<WalletHistoryPage> {
  List<WalletHistoryModel> fullHistory = [];
  List<WalletHistoryModel> filteredHistory = [];
  bool isLoading = false;
  bool _isSearching = false;
  int currentPage = 1;
  final int rowsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWalletHistory();
    _searchController.addListener(() {
      _filterHistory(_searchController.text);
    });
  }

  Future<void> _fetchWalletHistory() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final investorCode = prefs.getString('investor_code') ?? '';

      if (token.isEmpty || investorCode.isEmpty) {
        throw Exception("Missing token or investor code");
      }

      final response = await http.get(
        Uri.parse(ApiConstants.walletHistory(investorCode)),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'];
        final historyList =
        data.map((e) => WalletHistoryModel.fromJson(e)).toList();

        setState(() {
          fullHistory = historyList;
          filteredHistory = fullHistory;
          currentPage = 1;
        });
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wallet Transaction History not found",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterHistory(String query) {
    final filtered = fullHistory.where((item) {
      final trxId = item.trxId.toLowerCase();
      final type = item.type.toLowerCase();
      return trxId.contains(query.toLowerCase()) ||
          type.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredHistory = filtered;
      currentPage = 1;
    });
  }

  List<WalletHistoryModel> get currentPageItems {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage > filteredHistory.length)
        ? filteredHistory.length
        : (startIndex + rowsPerPage);
    return filteredHistory.sublist(startIndex, endIndex);
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      title: _isSearching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        cursorColor: Colors.white,
        decoration: const InputDecoration(
          hintText: 'Search by Transaction ID or Type',
          hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      )
          : const Text(
        'Wallet Transaction History',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchWalletHistory,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: currentPageItems.length,
                itemBuilder: (context, index) {
                  final item = currentPageItems[index];
                  return Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Type & Amount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.type,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '৳${item.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),
                          // Status (below amount)
                          Align(
                            alignment: Alignment.centerRight,
                            child: StatusChip(status: item.status),

                          ),

                          const SizedBox(height: 12),
                          // Description
                          Text(
                            item.context!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),

                          // Date
                          Text(
                            item.date,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),

                          const SizedBox(height: 10),
                          // Action Buttons
                          InvoiceActionButtons(
                            viewUrl: item.invoice_view_url,
                            downloadUrl: item.invoice_download_url,
                            invoiceNo: item.invoiceNo.toString(),
                            status: item.status,
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
        ),
      ),
    );
  }
}
