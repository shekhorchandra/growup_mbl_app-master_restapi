import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/withdraw_model.dart';


class WithdrawPage extends StatefulWidget {
  const WithdrawPage({Key? key}) : super(key: key);

  @override
  _WithdrawPageState createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _bankAccountNameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _routingNumberController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedMethod = "Selected Method";
  final List<String> _methods = [
    "Selected Method",
    'Bkash',
    'Nagad',
    'Rocket',
    'Bank Transfer'
  ];

  List<Withdraw> _withdrawHistory = [];
  List<Withdraw> _filteredWithdrawHistory = [];
  Set<String> downloadingInvoices = {};

  bool _isLoading = false;
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  double _walletBalance = 0.0;

  bool _isSubmitting = false;

  bool get _isBankTransfer => _selectedMethod == 'Bank Transfer';


  @override
  void initState() {
    super.initState();
    _fetchWalletBalanceFromAPI();
    _fetchWithdrawHistory();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String isoDate) {
    try {
      final parsedDate = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy, h:mm a').format(parsedDate); // e.g., 16 Jul 2025, 2:30 PM
    } catch (e) {
      return isoDate.split('T').first; // fallback
    }
  }


  Future<void> _handleRefresh() async {
    await _fetchWalletBalanceFromAPI();
    await _fetchWithdrawHistory();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredWithdrawHistory = List.from(_withdrawHistory);
      } else {
        _filteredWithdrawHistory = _withdrawHistory.where((w) {
          return w.amount.toLowerCase().contains(query) ||
              w.status.toLowerCase().contains(query) ||
              w.sendMoneyMobileMedia.toLowerCase().contains(query);
        }).toList();
      }
      _currentPage = 0;
    });
  }

  bool _hasPendingRequest() {
    return _withdrawHistory.any((withdraw) =>
    withdraw.status.toLowerCase() == 'pending');
  }

  List<Withdraw> get _paginatedWithdrawHistory {
    // Simply return the full filtered withdraw history
    return _filteredWithdrawHistory;
  }



  Future<void> _fetchWalletBalanceFromAPI() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    final url = Uri.parse(ApiConstants.investorProfile(investorCode));

    // final url = Uri.parse(
    //     'https://growupagro.tech/api/investor/profile?investor_code=$investorCode');

    try {
      final response = await http.get(
          url,
          headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final balanceString = data['data']['investor']['wallet']['balance'];
        setState(() {
          _walletBalance = double.tryParse(balanceString.toString()) ?? 0.0;
        });
      } else {
        _showSnack('Failed to load wallet balance', isError: true);
      }
    } catch (e) {
      _showSnack('Error fetching wallet balance: $e', isError: true);
    }
  }

  Future<void> _fetchBankingAndMobileInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    // final url = Uri.parse(
    //     'https://growupagro.tech/api/investor/profile?investor_code=$investorCode'
    // );

    final url = Uri.parse(ApiConstants.investorProfile(investorCode));

    try {
      final response = await http.get(
          url,

          headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data']['banking_information'] != null) {
          final bankInfo = data['data']['banking_information'];

          setState(() {
            if (_selectedMethod == 'Bank Transfer') {
              _bankAccountNameController.text = bankInfo['bank_account_name'] ?? '';
              _bankNameController.text = bankInfo['bank_name'] ?? '';
              _accountNumberController.text = bankInfo['account_number'] ?? '';
              _branchNameController.text = bankInfo['branch_name'] ?? '';
              _routingNumberController.text = bankInfo['routing_no'] ?? '';
            } else if (_selectedMethod == 'Bkash') {
              _mobileNumberController.text = bankInfo['bkash_number'] ?? '';
            } else if (_selectedMethod == 'Nagad') {
              _mobileNumberController.text = bankInfo['nagad_number'] ?? '';
            } else if (_selectedMethod == 'Rocket') {
              _mobileNumberController.text = bankInfo['rocket_number'] ?? '';
            }
          });
        }
      } else {
        debugPrint('Failed to fetch banking/mobile information');
      }
    } catch (e) {
      debugPrint('Error fetching banking/mobile info: $e');
    }
  }


  Future<void> _fetchWithdrawHistory() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    // final uri = Uri.parse(
    //     'https://admin-growup.onebitstore.site/api/widraw-history?investor_code=$investorCode');

    final url = ApiConstants.withdrawHistory(investorCode);

    try {
      final response = await http.get(
          Uri.parse(url),
          headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          List<dynamic> data = jsonResponse['data'];
          setState(() {
            _withdrawHistory = data.map((e) => Withdraw.fromJson(e)).toList();
            _filteredWithdrawHistory = List.from(_withdrawHistory);
            _currentPage = 0;
          });
        } else {
          _showSnack('No withdrawal history found.', isError: true);
        }
      } else {
        _showSnack('Failed to load withdrawal history.', isError: true);
      }
    } catch (e) {
      _showSnack('Error loading withdrawal history: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitWithdraw() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    if (investorCode.isEmpty) {
      _showSnack('Investor code missing. Please login again.', isError: true);
      return;
    }

    if (_hasPendingRequest()) {
      _showSnack('You already have a pending withdraw request.', isError: true);
      return;
    }

    final requestedAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (requestedAmount <= 0 || requestedAmount > _walletBalance) {
      _showSnack('Invalid or excessive amount.', isError: true);
      return;
    }

    if (_isBankTransfer) {
      if (_bankAccountNameController.text.isEmpty ||
          _bankNameController.text.isEmpty ||
          _accountNumberController.text.isEmpty ||
          _branchNameController.text.isEmpty ||
          _routingNumberController.text.isEmpty) {
        _showSnack('Please update your banking information from your profile.', isError: true);
        return;
      }
    } else {
      final mobileNumber = _mobileNumberController.text.trim();

      if (_selectedMethod == "Selected Method") {
        _showSnack('Please select a withdrawal method.', isError: true);
        return;
      }

      if (mobileNumber.isEmpty) {
        _showSnack('Please update your valid mobile number from your profile.', isError: true);
        return;
      }

      // Validate mobile number (BD format: 01XXXXXXXXX)
      final mobileRegex = RegExp(r'^01[3-9]\d{8}$');
      if (!mobileRegex.hasMatch(mobileNumber)) {
        _showSnack('Please update your valid mobile number from your profile. Must be 11 digits and start with 013-019.',
            isError: true);
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    // final uri =
    // Uri.parse('https://admin-growup.onebitstore.site/api/investor/withdraw');
    final url = ApiConstants.submitWithdraw();

    Map<String, dynamic> body = {
      'investor_code': investorCode,
      'amount': requestedAmount,
    };

    if (_isBankTransfer) {
      body.addAll({
        'method': 'bank',
        'bank_account_name': _bankAccountNameController.text,
        'bank_name': _bankNameController.text,
        'account_number': _accountNumberController.text,
        'branch_name': _branchNameController.text,
        'routing_number': _routingNumberController.text,
      });
    } else {
      final mobileNumberKey = '${_selectedMethod.toLowerCase()}_number';
      body.addAll({
        'method': _selectedMethod.toLowerCase(),
        mobileNumberKey: _mobileNumberController.text,
      });
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final jsonResponse = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          jsonResponse['success'] == true) {
        _showSnack(jsonResponse['message'] ?? 'Withdraw successful');
        _clearForm();
        await _fetchWithdrawHistory();
        await _fetchWalletBalanceFromAPI();
      } else {
        _showSnack(jsonResponse['message'] ?? 'Withdraw failed', isError: true);
      }
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    _amountController.clear();
    _mobileNumberController.clear();
    _bankAccountNameController.clear();
    _bankNameController.clear();
    _accountNumberController.clear();
    _branchNameController.clear();
    _routingNumberController.clear();
    setState(() {
      _selectedMethod = "Selected Method";
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  Widget _buildWithdrawForm({required bool includePagination}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Wallet Balance: $_walletBalance",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          enabled: !_isSubmitting,
          style: TextStyle(fontSize: 14), // smaller font reduces height
          decoration: InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(),
            isDense: true, // makes the field more compact
            contentPadding: EdgeInsets.symmetric(
              vertical: 8,  // vertical padding to reduce height
              horizontal: 12,
            ),
          ),
        ),

        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedMethod,
          decoration: InputDecoration(
            labelText: 'Withdraw Method',
            border: OutlineInputBorder(),
            isDense: true, // compact vertical spacing
            contentPadding: EdgeInsets.symmetric(
              vertical: 8,  // reduce vertical height
              horizontal: 12,
            ),
          ),
          items: _methods
              .map(
                (method) => DropdownMenuItem(
              value: method,
              child: Text(
                method,
                style: TextStyle(fontSize: 14), // optional smaller text
              ),
            ),
          )
              .toList(),
          onChanged: _isSubmitting
              ? null
              : (val) {
            setState(() {
              _selectedMethod = val!;
            });

            // Auto-fill from API if a method is chosen
            if (_selectedMethod != "Selected Method") {
              _fetchBankingAndMobileInfo();
            } else {
              // Clear all fields when no method selected
              _mobileNumberController.clear();
              _bankAccountNameController.clear();
              _bankNameController.clear();
              _accountNumberController.clear();
              _branchNameController.clear();
              _routingNumberController.clear();
            }
          },
        ),


        const SizedBox(height: 12),
        if (_isBankTransfer) ...[
          TextField(
            controller: _bankAccountNameController,
            readOnly: true, // user can't edit
            enabled: !_isSubmitting,
            style: TextStyle(fontSize: 14), // smaller text reduces height
            decoration: InputDecoration(
              labelText: 'Account Name',
              border: OutlineInputBorder(),
              isDense: true, // makes the field more compact
              contentPadding: EdgeInsets.symmetric(
                vertical: 8,  // reduce vertical padding
                horizontal: 12,
              ),
            ),
          ),

          const SizedBox(height: 8),
          TextField(
            controller: _bankNameController,
            readOnly: true, // user can't edit
            enabled: !_isSubmitting,
            style: TextStyle(fontSize: 14), // smaller font reduces height
            decoration: InputDecoration(
              labelText: 'Bank Name',
              border: OutlineInputBorder(),
              isDense: true, // makes the field more compact
              contentPadding: EdgeInsets.symmetric(
                vertical: 8, // reduce vertical padding
                horizontal: 12,
              ),
            ),
          ),

          const SizedBox(height: 8),
          TextField(
            controller: _accountNumberController,
            readOnly: true, // user can't edit
            enabled: !_isSubmitting,
            style: TextStyle(fontSize: 14), // smaller font reduces height
            decoration: InputDecoration(
              labelText: 'Account Number',
              border: OutlineInputBorder(),
              isDense: true, // makes the field more compact
              contentPadding: EdgeInsets.symmetric(
                vertical: 8, // reduce vertical padding
                horizontal: 12,
              ),
            ),
          ),

          const SizedBox(height: 8),
          TextField(
            controller: _branchNameController,
            readOnly: true, // user can't edit
            enabled: !_isSubmitting,
            style: TextStyle(fontSize: 14), // smaller font reduces height
            decoration: InputDecoration(
              labelText: 'Branch Name',
              border: OutlineInputBorder(),
              isDense: true, // makes the field more compact
              contentPadding: EdgeInsets.symmetric(
                vertical: 8, // reduce vertical padding
                horizontal: 12,
              ),
            ),
          ),

          const SizedBox(height: 8),
          TextField(
            controller: _routingNumberController,
            readOnly: true, // user can't edit
            enabled: !_isSubmitting,
            style: TextStyle(fontSize: 14), // smaller font reduces height
            decoration: InputDecoration(
              labelText: 'Routing Number',
              border: OutlineInputBorder(),
              isDense: true, // makes the field more compact
              contentPadding: EdgeInsets.symmetric(
                vertical: 8, // reduce vertical padding
                horizontal: 12,
              ),
            ),
          ),

        ] else if (_selectedMethod != "Selected Method") ...[
          TextField(
            controller: _mobileNumberController,
            readOnly: true, // user can't edit
            enabled: !_isSubmitting,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 14), // smaller font reduces height
            decoration: InputDecoration(
              labelText: 'Mobile Number for $_selectedMethod',
              border: OutlineInputBorder(),
              isDense: true, // compact vertical spacing
              contentPadding: EdgeInsets.symmetric(
                vertical: 8, // reduce vertical padding
                horizontal: 12,
              ),
            ),
          ),

        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitWithdraw,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isSubmitting
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : const Text('Submit Withdraw Request',
                style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Withdraw History (Amount, Status, Method)',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          enabled: !_isSubmitting,
        ),
        const SizedBox(height: 16),
        _buildWithdrawHistoryTable(),
        const SizedBox(height: 16),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     ElevatedButton(
        //         onPressed: _currentPage > 0
        //             ? () => setState(() => _currentPage--)
        //             : null,
        //         child: const Text('Previous')),
        //     const SizedBox(width: 20),
        //     Text(
        //         'Page ${_currentPage + 1} of ${(_filteredWithdrawHistory.length / _itemsPerPage).ceil()}'),
        //     const SizedBox(width: 20),
        //     ElevatedButton(
        //         onPressed: (_currentPage + 1) * _itemsPerPage <
        //             _filteredWithdrawHistory.length
        //             ? () => setState(() => _currentPage++)
        //             : null,
        //         child: const Text('Next')),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildWithdrawHistoryTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredWithdrawHistory.isEmpty) {
      return const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Center(child: Text('No withdrawal history found.')));
    }
    final currentItems = _paginatedWithdrawHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: const Text('Withdrawal History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Card(
            //margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 60,
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFF388E3C),
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                columns: const [
                  DataColumn(label: Text('SL')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Method')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Note')),
                  DataColumn(label: Text('Action')),
                ],
                rows: List.generate(currentItems.length, (index) {
                  final item = currentItems[index];
                  final invoiceNo = item.invoiceNo;
                  final hasInvoice = invoiceNo != 0;

                  return DataRow(cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(_formatDate(item.createdAt))),
                    DataCell(Text(item.amount.toString())),
                    DataCell(Text(item.sendMoneyMobileMedia.toString())),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.status.toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    )),
                    DataCell(Text(item.note ?? 'N/A')),
                    DataCell(
                      hasInvoice && item.status.toLowerCase() == "approved"
                          ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 👁️ View Button
                          ElevatedButton(
                            onPressed: () => _openInvoiceInBrowser(invoiceNo.toString()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[200], // View button color
                              foregroundColor: Colors.black,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              minimumSize: const Size(0, 0),
                            ),
                            child: const Text(
                              'View',
                              style: TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4), // spacing between buttons
/*
                          // 💾 Download Button or Loading Spinner
                          (downloadingInvoices.contains(invoiceNo.toString()))
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : ElevatedButton(
                            onPressed: () => _openInvoiceInBrowser(invoiceNo.toString()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[200], // Download button color
                              foregroundColor: Colors.black,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              minimumSize: const Size(0, 0),
                            ),
                            child: const Text(
                              'Download',
                              style: TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ),
                          */
                        ],
                      )
                          : const Icon(
                        Icons.block, // blocked / no access
                        color: Colors.red,
                        size: 24,
                      ),
                    )

                  ]);
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openInvoiceInBrowser(String? invoiceNo) async {
    if (invoiceNo == null || invoiceNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid invoice number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loader
    setState(() => downloadingInvoices.add(invoiceNo));

    final url = 'https://growupagro.tech/api/invoice/pdf/$invoiceNo';

    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // opens in browser
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open invoice in browser.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Hide loader
      setState(() => downloadingInvoices.remove(invoiceNo));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Funds',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),

      // Scrollable withdraw form + history
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildWithdrawForm(
              includePagination: false, // Remove pagination from inside scroll
            ),
          ),
        ),
      ),

      // Fixed pagination at the bottom
      bottomNavigationBar: Transform.translate(
        offset: const Offset(0, -40), // slightly lift up
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),  // proper padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 26, // smaller button height
                child: ElevatedButton(
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7), // 7px border radius
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Previous', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 24),
              Text(
                'Page ${_currentPage + 1} of ${(_filteredWithdrawHistory.length / _itemsPerPage).ceil()}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 24),
              SizedBox(
                height: 26, // smaller button height
                child: ElevatedButton(
                  onPressed: (_currentPage + 1) * _itemsPerPage < _filteredWithdrawHistory.length
                      ? () => setState(() => _currentPage++)
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7), // 7px border radius
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Next', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }


}
