import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/widgets/status_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/withdraw_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/invoice_action_buttons.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({Key? key}) : super(key: key);

  @override
  _WithdrawPageState createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _bankAccountNameController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _routingNumberController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedMethod = "Selected Method";
  final List<String> _methods = [
    "Selected Method",
    'Bkash',
    'Nagad',
    'Rocket',
    'Bank Transfer',
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
      return DateFormat(
        'dd MMM yyyy, h:mm a',
      ).format(parsedDate); // e.g., 16 Jul 2025, 2:30 PM
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
    return _withdrawHistory.any(
      (withdraw) => withdraw.status.toLowerCase() == 'pending',
    );
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
        },
      );

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
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true &&
            data['data']['banking_information'] != null) {
          final bankInfo = data['data']['banking_information'];

          setState(() {
            if (_selectedMethod == 'Bank Transfer') {
              _bankAccountNameController.text =
                  bankInfo['bank_account_name'] ?? '';
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
        },
      );

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
        _showSnack(
          'Please update your banking information from your profile.',
          isError: true,
        );
        return;
      }
    } else {
      final mobileNumber = _mobileNumberController.text.trim();

      if (_selectedMethod == "Selected Method") {
        _showSnack('Please select a withdrawal method.', isError: true);
        return;
      }

      if (mobileNumber.isEmpty) {
        _showSnack(
          'Please update your valid mobile number from your profile.',
          isError: true,
        );
        return;
      }

      // Validate mobile number (BD format: 01XXXXXXXXX)
      final mobileRegex = RegExp(r'^01[3-9]\d{8}$');
      if (!mobileRegex.hasMatch(mobileNumber)) {
        _showSnack(
          'Please update your valid mobile number from your profile. Must be 11 digits and start with 013-019.',
          isError: true,
        );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildWithdrawForm({required bool includePagination}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,    // subtle shadow
                offset: Offset(0, 3),     // bottom shadow only
                blurRadius: 6,            // soft blur
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Wallet Balance: $_walletBalance",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  enabled: !_isSubmitting,
                  style: TextStyle(fontSize: 14),
                  // smaller font reduces height
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    isDense: true, // makes the field more compact
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8, // vertical padding to reduce height
                      horizontal: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: InputDecoration(
                    labelText: 'Withdraw Method',
                    border: OutlineInputBorder(),
                    isDense: true, // compact vertical spacing
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8, // reduce vertical height
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

                const SizedBox(height: 16),
                if (_isBankTransfer) ...[
                  TextField(
                    controller: _bankAccountNameController,
                    readOnly: true,
                    // user can't edit
                    enabled: !_isSubmitting,
                    style: TextStyle(fontSize: 14),
                    // smaller text reduces height
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(),
                      isDense: true, // makes the field more compact
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8, // reduce vertical padding
                        horizontal: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _bankNameController,
                    readOnly: true,
                    // user can't edit
                    enabled: !_isSubmitting,
                    style: TextStyle(fontSize: 14),
                    // smaller font reduces height
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

                  const SizedBox(height: 16),
                  TextField(
                    controller: _accountNumberController,
                    readOnly: true,
                    // user can't edit
                    enabled: !_isSubmitting,
                    style: TextStyle(fontSize: 14),
                    // smaller font reduces height
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

                  const SizedBox(height: 16),
                  TextField(
                    controller: _branchNameController,
                    readOnly: true,
                    // user can't edit
                    enabled: !_isSubmitting,
                    style: TextStyle(fontSize: 14),
                    // smaller font reduces height
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
                    readOnly: true,
                    // user can't edit
                    enabled: !_isSubmitting,
                    style: TextStyle(fontSize: 14),
                    // smaller font reduces height
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
                    readOnly: true,
                    // user can't edit
                    enabled: !_isSubmitting,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 14),
                    // smaller font reduces height
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Submit Withdraw Request',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Withdrawal History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 1,),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
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
        child: Center(child: Text('No withdrawal history found.')),
      );
    }
    final currentItems = _paginatedWithdrawHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredWithdrawHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: Text('No withdrawal history found.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentItems.length,
            itemBuilder: (context, index) {
              final item = currentItems[index];
              final invoiceNo = item.invoiceNo;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Top row: amount + status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "৳ ${item.amount}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          StatusChip(status: item.status.toString().toUpperCase())
                        ],
                      ),

                      const SizedBox(height: 6),

                      // 🔹 Date & Method
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatDate(item.createdAt),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Method: ${item.sendMoneyMobileMedia}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // 🔹 Note section
                      if (item.note != null && item.note!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.note_alt_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Note: ${item.note}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 8),

                      item.invoiceNo == null
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            child: const Icon(
                              Icons.block,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                        ],
                      )
                          : InvoiceActionButtons(
                        invoiceNo: item.invoiceNo!,
                        downloadUrl:
                        'https://growupagro.tech/api/invoice/pdf/${item.invoiceNo!}',
                        viewUrl:
                        'https://growupagro.tech/api/invoice/pdf/${item.invoiceNo!}',
                        status: item.status,
                      ),

                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Withdraw Funds',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),

      // Scrollable withdraw form + history
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildWithdrawForm(
            includePagination: false, // Remove pagination from inside scroll
          ),
        ),
      ),

      // Fixed pagination at the bottom
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26, // subtle shadow color
              offset: Offset(0, -2),  // shadow from the top
              blurRadius: 6,          // soft blur
              spreadRadius: 0,
            ),
          ],
        ),
        child: Transform.translate(
          offset: const Offset(0, 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 26,
                  child: CustomButton(
                    text: 'Previous',
                    fontSize: 14,
                    height: 26,
                    borderRadius: 5,
                    backgroundColor: Color(0xFF8BC34A),
                    textColor: Colors.white,
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                ),
                Text(
                  'Page ${_currentPage + 1} of ${(_filteredWithdrawHistory.length / _itemsPerPage).ceil()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: 26,
                  child: CustomButton(
                    text: 'Next',
                    fontSize: 14,
                    height: 26,
                    borderRadius: 5,
                    backgroundColor: Color(0xFF8BC34A),
                    textColor: Colors.white,
                    onPressed: (_currentPage + 1) * _itemsPerPage <
                        _filteredWithdrawHistory.length
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
