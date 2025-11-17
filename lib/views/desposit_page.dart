import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shurjopay/models/config.dart';
import 'package:shurjopay/models/payment_verification_model.dart';
import 'package:shurjopay/models/shurjopay_request_model.dart';
import 'package:shurjopay/models/shurjopay_response_model.dart';
import 'package:shurjopay/shurjopay.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/deposit_model.dart';
import '../paymentService/payment_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/info_row.dart';
import '../widgets/invoice_action_buttons.dart';
import '../widgets/status_test.dart';

class DepositPage extends StatefulWidget {
  final int? projectId;

  const DepositPage({Key? key, this.projectId}) : super(key: key);

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  String _selectedMethod = 'Selected Method';
  File? _selectedImage;
  String _investorCode = '';
  bool _isSubmitting = false;
  bool _isLoading = false;

  List<dynamic> _depositHistory = [];
  List<dynamic> _filteredDepositHistory = [];
  Set<String> downloadingInvoices = {};

  int _currentPage = 0;
  final int _itemsPerPage = 10;

  final TextEditingController _amountController = TextEditingController(
    text: '100',
  );
  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _methods = [
    'Selected Method',
    'Cash Payment',
    'Bank Transfer',
    "Online payment (ShurjoPay)",
  ];

  final Map<String, Map<String, String>> _bankAccounts = {
    'bank_a': {
      'name': 'BRAC Bank PLC.',
      'account_name': 'GROW UP TRADING',
      'number': '2062538240001',
      'branch': 'BOGURA BRANCH',
      'route': '060100379',
    },
    'bank_b': {
      'name': 'The City Bank PLC',
      'account_name': 'GROWUP AGROTECH LIMITED',
      'number': '1454253017001',
      'branch': 'HEAD OFFICE BRANCH, GULSHAN',
      'route': '225272684',
    },
    'bank_c': {
      'name': 'The City Bank PLC.',
      'account_name': 'Rural Organization For Social Affairs (ROSA)',
      'number': '1404041760001',
      'branch': 'Gulshan  Branch',
      'route': '225261729',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadInvestorCode();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // String _formatDate(String rawDate) {
  //   try {
  //     final date = DateTime.parse(rawDate);
  //     return DateFormat(
  //       'dd MMM yyyy, h:mm a',
  //     ).format(date); // Example: 16 Jul 2025
  //   } catch (e) {
  //     return rawDate;
  //   }
  // }

  Future<void> _handleRefresh() async {
    await _loadInvestorCode();
  }

  Future<void> _loadInvestorCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('investor_code') ?? '';
    setState(() => _investorCode = code);
    _fetchDepositHistory();
  }

  Future<void> _fetchDepositHistory() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final url = ApiConstants.depositHistory(_investorCode);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success']) {
          final List<dynamic> data = decoded['data'];

          final deposits = data.map((e) => DepositHistory.fromJson(e)).toList();

          deposits.sort(
            (a, b) => (b.updatedAt ?? DateTime(0)).compareTo(
              a.updatedAt ?? DateTime(0),
            ),
          );

          setState(() {
            _depositHistory = deposits;
            _filteredDepositHistory = List.from(_depositHistory);
            _currentPage = 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching deposit history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredDepositHistory = query.isEmpty
          ? List.from(_depositHistory)
          : _depositHistory.where((d) {
              return (d.amount.toString().toLowerCase().contains(query)) ||
                  (d.paymentMethod.toString().toLowerCase().contains(query)) ||
                  (d.status.toString().toLowerCase().contains(query));
            }).toList();
      _currentPage = 0;
    });
  }

  List<dynamic> get _paginatedDepositHistory {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(
      0,
      _filteredDepositHistory.length,
    );
    return _filteredDepositHistory.sublist(start, end);
  }

  // Color _getStatusColor(String status) {
  //   switch (status.toLowerCase()) {
  //     case 'pending':
  //       return Colors.orange;
  //     case 'approved':
  //       return Colors.green;
  //     case 'rejected':
  //       return Colors.red;
  //     default:
  //       return Colors.grey;
  //   }
  // }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void shurjoPay({
    required transactionAmount,
    required String transactionId,
    required String investorName,
    required String investorPhone,
    required String investorEmail,
    required String investorAddress,
    required bool isLoading, required String investorId,
    int? walletTransactionId,
  }) async {
    final shurjoPay = ShurjoPay();

    ShurjopayConfigs shurjopayConfigs = ShurjopayConfigs(


      // prefix: "SP",
      // userName: "sp_sandbox",
      // password: "pyyk97hu&6u6",
      userName: 'growup_agrotech',
      password: 'growjjxwdm6wazy4',
      prefix: "GAL",
      clientIP: "127.0.0.1",
    );

    ShurjopayResponseModel shurjopayResponseModel = ShurjopayResponseModel();
    ShurjopayVerificationModel shurjopayVerificationModel = ShurjopayVerificationModel();

    ShurjopayRequestModel shurjopayRequestModel =
    ShurjopayRequestModel(
      configs: shurjopayConfigs,
      currency: "BDT",
      amount: transactionAmount,
      orderID: transactionId,
      discountAmount: 0,
      discountPercentage: 0,
      customerName: investorName,
      customerPhoneNumber: investorPhone,
      customerAddress: investorAddress,
      customerEmail: investorEmail,
      customerCity: "Dhaka",
      customerPostcode: "0000",
      value1: investorId,
      value2: "N/A",
      value3: "wallet_deposit",
      value4: walletTransactionId.toString(),
      // Live: https://www.engine.shurjopayment.com/return_url
      returnURL:
      "https://www.engine.shurjopayment.com/return_url",

      // returnURL:
      // "https://www.sandbox.shurjopayment.com/return_url",
      // Live: https://www.engine.shurjopayment.com/cancel_url

      cancelURL:
      "https://www.engine.shurjopayment.com/cancel_url",

      // cancelURL:
      // "https://www.sandbox.shurjopayment.com/cancel_url",
    );
    shurjopayResponseModel = await shurjoPay.makePayment(
      context: context,
      shurjopayRequestModel: shurjopayRequestModel,
    );
    if (shurjopayResponseModel.status == true) {
      try {
        shurjopayVerificationModel =
        await shurjoPay.verifyPayment(
          orderID: shurjopayResponseModel.shurjopayOrderID!,
        );
        print(shurjopayVerificationModel.spCode);
        print(shurjopayVerificationModel.spMessage);
        if (shurjopayVerificationModel.spCode == "1000") {
          print("Payment Varified");

          showProcessingPaymentDialog(context);
          _loadPaymentStatus(
            shurjopayVerificationModel.orderId!,
            isLoading,
            context,
            "ShurjoPay",
          );

        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Something went wrong"), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleSslCommerzPay() async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final investorId = prefs.getString('investor_id') ?? '';
    final email = prefs.getString('investor_email') ?? 'default@email.com';
    final investorName = prefs.getString('investor_name') ?? '';
    final investorPhone = prefs.getString('investor_phone') ?? '';
    final investorAddress = prefs.getString('investor_address') ?? 'Dhaka';

    final enteredAmount = _amountController.text.trim();
    if (enteredAmount.isEmpty || double.tryParse(enteredAmount) == null) {
      _showSnack("Please enter a valid deposit amount.");
      setState(() => _isLoading = false);
      return;
    }

    final amount = double.parse(enteredAmount);

    try {
      if (token == null || token.isEmpty) {
        _showSnack("Authorization token missing. Please login again.");
        setState(() => _isLoading = false);
        return;
      }

      showProcessingPaymentDialog(context);

      // 🔹 Step 1: Initiate transaction
      final initiateResponse = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/transaction-initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "amount": amount,
          "type": "deposit",
          "note": "ok",
        }),
      );

      if (initiateResponse.statusCode != 200 &&
          initiateResponse.statusCode != 201) {
        _showSnack("Failed to initiate transaction.");
        setState(() => _isLoading = false);
        return;
      }

      final initiateData = jsonDecode(initiateResponse.body);
      if (initiateData['success'] != true) {
        _showSnack(
          initiateData['message'] ?? 'Transaction initiation failed.',
        );
        setState(() => _isLoading = false);
        Navigator.pop(context);
        return;
      }

      final walletTransaction = initiateData['data'];
      final transactionId = walletTransaction?['transaction_id']?.toString();
      final walletTransactionId = walletTransaction?['wallet_transaction_id'];
      final transactionAmount = walletTransaction?['amount'];

      if (transactionId == null || transactionId.isEmpty) {
        _showSnack("Transaction ID missing from server response.");
        setState(() => _isLoading = false);
        Navigator.pop(context);
        return;
      }

      Navigator.pop(context);

      shurjoPay(
        walletTransactionId : walletTransactionId,
        investorId: investorId,
        transactionId: transactionId,
        transactionAmount: transactionAmount
            .toDouble(),
        investorName: investorName,
        investorPhone: investorPhone,
        investorEmail: email,
        investorAddress: investorAddress,
        isLoading: _isLoading,
      );

      // Initialize SSLCommerz
      /*Sslcommerz sslcommerz = Sslcommerz(
        initializer: SSLCommerzInitialization(
          multi_card_name: "visa,master,bkash",
          currency: SSLCurrencyType.BDT,
          product_category: "Digital Product",
          sdkType: SSLCSdkType.TESTBOX, // Change to LIVE later
          store_id: "datab67593a46c4062",
          store_passwd: "datab67593a46c4062@ssl",
          total_amount: transactionAmount.toDouble(),
          tran_id: transactionId,
        ),
      );

      final response = await sslcommerz.payNow();

      showProcessingPaymentDialog(context);
      _loadPaymentStatus(transactionId, _isLoading, context, response.status);*/
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPaymentStatus(
      String transactionId,
      bool _isLoading,
      BuildContext dialogContext,
      String? status,
      ) async {
    final result = await PaymentService.fetchPaymentSuccess(
      transactionId,
      status!,
    );

    if (status == 'VALID' || status == 'ShurjoPay') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == "success"
                ? "Transaction successful"
                : "Transaction failed",
          ),
          backgroundColor: result == "success" ? Colors.green : Colors.red,
        ),
      );
    } else if (status == 'Closed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cancel by user"), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed"), backgroundColor: Colors.red),
      );
    }

    print('Payment completed, gg TRX ID: ${result}');

    setState(() {
      _isLoading = false;
    });
    Navigator.pop(context);
  }

  Future<void> _submitDeposit() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final method = _selectedMethod.toLowerCase();

    if (_selectedMethod == 'Selected Method') {
      _showSnack("Please select a deposit method.");
      return;
    }

    if (amount < 100) {
      _showSnack("Minimum deposit amount is 100.");
      return;
    }

    if (_investorCode.isEmpty) {
      _showSnack("Investor code missing.");
      return;
    }

    if (method == 'bank transfer') {
      if (_bankNameController.text.isEmpty || _selectedImage == null) {
        _showSnack("Please provide bank name and slip image.");
        return;
      }
    }

    if (['bkash', 'nagad', 'rocket'].contains(method)) {
      final mobileNumber = _mobileNumberController.text.trim();
      final transactionId = _transactionIdController.text.trim();

      if (transactionId.isEmpty || mobileNumber.isEmpty) {
        _showSnack("Transaction ID and Mobile number are required.");
        return;
      }

      final mobileRegex = RegExp(r'^01[3-9]\d{8}$'); // Valid BD mobile format
      if (!mobileRegex.hasMatch(mobileNumber)) {
        _showSnack("Please enter a valid Bangladeshi mobile number.");
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final uri = Uri.parse(ApiConstants.depositRequest());

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['investor_code'] = _investorCode
      ..fields['amount'] = amount.toString()
      ..fields['payment_method'] = _selectedMethod == 'Bank Transfer'
          ? 'bank'
          : method;

    if (method == 'bank transfer') {
      request.fields['bank_name'] = _bankNameController.text;
      request.files.add(
        await http.MultipartFile.fromPath(
          'bank_payment_slip',
          _selectedImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    } else {
      request.fields['mobile_transaction_id'] = _transactionIdController.text;
      request.fields['mobile_number'] = _mobileNumberController.text;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonMap = json.decode(responseBody);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          jsonMap['success'] == true) {
        final newData = jsonMap['data'];
        newData['updated_at'] ??= DateTime.now().toIso8601String();

        // Convert Map to DepositHistory before inserting
        final deposit = DepositHistory.fromJson(newData);

        setState(() {
          _transactionIdController.clear();
          _mobileNumberController.clear();
          _bankNameController.clear();
          _amountController.text = '100';
          _selectedImage = null;
          _depositHistory.insert(0, deposit); // <-- fixed here
          _filteredDepositHistory = List.from(_depositHistory);
          _currentPage = 0;
        });

        _showSnack("Deposit request submitted successfully", isError: false);
      } else {
        _showSnack(jsonMap['message'] ?? 'Deposit submission failed.');
      }
    } catch (e) {
      debugPrint("Exception during deposit submission: $e");
      _showSnack("Something went wrong. Please try again.");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDepositForm() {
    final method = _selectedMethod.toLowerCase().replaceAll(RegExp(r'\s+'), '');

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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 8,),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Deposit Method',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                items: _methods
                    .map(
                      (m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      m,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                )
                    .toList(),
                onChanged: (val) => setState(() => _selectedMethod = val!),
              ),

              const SizedBox(height: 24),

              // Amount field (skip for cash)
              if (method != 'cashpayment') ...[
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: const TextStyle(color: Colors.black87),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],

              // Bank Transfer Fields
              if (method == 'banktransfer') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _bankNameController,
                  decoration: InputDecoration(
                    labelText: 'Your Bank Name (where you sent the money from)',
                    labelStyle: const TextStyle(color: Colors.black87),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),

                ),
                const SizedBox(height: 12),

                _selectedImage != null
                    ? Image.file(_selectedImage!, height: 100)
                    : const Center(
                  child: Text("Upload Deposit Document (PDF or Image)"),
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_a_photo, size: 32, color: Colors.grey,),
                    label: const Text(""),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (method != 'cashpayment')
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (method == 'banktransfer') {
                        _submitDeposit();
                      } else if (method == 'onlinepayment(shurjopay)') {
                        _handleSslCommerzPay();
                      } else {
                        _submitDeposit();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      method == 'onlinepayment(shurjopay)' ? 'Pay with ShurjoPay' : 'Deposit',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

              if (method == 'banktransfer') ...[
                bankTransferText(),
                const SizedBox(height: 12),
                _buildBankDetailsList(),
                const SizedBox(height: 12),
              ],

              if (method == 'cashpayment') ...[
                _buildCashPaymentInstructions(),
                const SizedBox(height: 12),
              ],

              if (method == 'onlinepayment(shurjopay)') ...[
                const SizedBox(height: 12),
                _buildSSLInstructions(),
              ],
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deposit History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              Divider(height: 1,),

              const SizedBox(height: 16),

              // Deposit History Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Withdraw History (Amount, Status, Method)',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildDepositHistoryTable(),
              const SizedBox(height: 45),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankDetailsList() {
    void _copyToClipboard(String text) {
      Clipboard.setData(ClipboardData(text: text)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied Account Number: $text'),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      });
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our Bank Account Details:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Please transfer your deposit amount to **ANY** of the following accounts:',
              style: TextStyle(fontSize: 14),
            ),
            const Divider(),

            // List of Bank Accounts
            ..._bankAccounts.values.map((account) {
              final accountNumber = account['number']!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('A/C Name: ${account['account_name']!}'),
                    // Row for Account Number and Copy Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'A/C Number: $accountNumber',
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _copyToClipboard(accountNumber),
                          tooltip: 'Copy Account Number',
                        ),
                      ],
                    ),
                    Text('Branch: ${account['branch']!}'),
                    Text('Routing No: ${account['route']!}'),
                    // Include Routing Number

                    // Divider for separation
                    if (account != _bankAccounts.values.last)
                      const Divider(height: 16),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget bankTransferText() {
    return const Center(
      child: Card(
        color: Color(0xFFE8F5E9),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'ব্যাংক ট্রান্সফার ও ডিপোজিটের মাধ্যমে ওয়ালেট রিচার্জ\n'
            'আপনার ব্যাংকের ইন্টারনেট ব্যাংকিং (iBanking), মোবাইল অ্যাপ ব্যাবহার করে '
            'যেকোনো একটি (NPSB, BEFTN বা RTGS) পদ্ধতি ব্যবহার করে করে আপনার ব্যাংক অ্যাকাউন্ট '
            'থেকে সরাসরি আমাদের কোম্পানি / প্রতিষ্ঠানের নিন্মোক্ত যেকোনো ব্যাংক অ্যাকাউন্টে টাকা ট্রান্সফার করতে পারবেন। '
            'এছাড়াও, সরাসরি আমাদের তালিকাভুক্ত যেকোনো ব্যাংকের শাখায় গিয়ে ক্যাশ ডিপোজিট করেও '
            'আপনার ওয়ালেট রিচার্জ করার সুযোগ রয়েছে।\n\n'
            'টাকা ট্রান্সফার বা ডিপোজিট করার পর, যাচাইকরণের জন্য অনুগ্রহ করে রশিদের ছবি আপলোড করুন।',
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashPaymentInstructions() {
    return Card(
      elevation: 2,
      color: const Color(0xFFE8F5E9), // Light green background for visibility
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'ক্যাশ পেমেন্ট এর মাধ্যমে ওয়ালেট রিচার্জ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32), // Dark green text
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: const Text(
                'এই পদ্ধতিতে আপনি সরাসরি অফিস গিয়ে কাউন্টারে টাকা জমা দিয়ে আপনার ওয়ালেট রিচার্জ করতে পারবেন।',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri mapUrl = Uri.parse(
                  'https://maps.app.goo.gl/r6zt5tHFVKxVviE19',
                );
                if (await canLaunchUrl(mapUrl)) {
                  await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch Google Maps';
                }
              },
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text(
                'Find us on Google Maps',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF948BF3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSSLInstructions() {
    return const Card(
      elevation: 2,
      color: Color(0xFFE8F5E9), // Light green background for visibility
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'সুরক্ষিত অনলাইন পেমেন্ট এর মাধ্যমে ওয়ালেট রিচার্জ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32), // green tone for heading
              ),
            ),
            SizedBox(height: 8),
            Text(
              'আমাদের সুরক্ষিত পেমেন্ট গেটওয়ে (ShurjoPay)-এর মাধ্যমে যেকোনো মোবাইল ওয়ালেট (MFS) যেমন: বিকাশ, নগদ, রকেট, ব্যাংক কার্ড (ডেবিট, ক্রেডিট, প্রিপেইড) ব্যবহার করে সহজেই আপনার ওয়ালেট রিচার্জ করতে পারবেন। '
              'এছাড়াও, নির্দিষ্ট ব্যাংকের ক্রেডিট কার্ড ব্যবহারকারীরা সহজ মাসিক কিস্তি (EMI) সুবিধা ব্যবহার করে ওয়ালেট রিচার্জ করতে পারবেন।',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.5, // for better line spacing
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositHistoryTable() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredDepositHistory.isEmpty)
      return const Center(child: Text('No deposit history found.'));

    final currentItems = _paginatedDepositHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Scrollable list instead of table
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentItems.length,
          itemBuilder: (context, index) {
            final DepositHistory item = currentItems[index];

            final sl = _currentPage * _itemsPerPage + index + 1;
            final createdAt = item.createdAt != null
                ? DateFormat('dd MMM yyyy, h:mm a').format(item.createdAt!)
                : 'N/A';

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
                    // 🔹 Top Row: SL + Date + Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SL: $sl",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        StatusChip(status: item.status.toUpperCase()),
                      ],
                    ),

                    const SizedBox(height: 6),

                    //Details Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            createdAt,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InfoRow(
                      title: 'Amount',
                      value: item.amount,
                    ),

                    InfoRow(
                      title: 'Method',
                      value: item.paymentMethod,
                    ),

                    SizedBox(height: 8,),
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
                            "Note: ${item.note?.isNotEmpty == true ? item.note! : 'N/A'}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    item.invoiceNo == null
                        ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
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
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InvoiceActionButtons(
                              invoiceNo: item.invoiceNo!,
                              downloadUrl:
                                  'https://growupagro.tech/api/invoice/pdf/${item.invoiceNo!}',
                              viewUrl:
                                  'https://growupagro.tech/api/invoice/pdf/${item.invoiceNo!}',
                              status: item.status,
                            ),
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
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Deposit Funds",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Main scrollable content
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildDepositForm(),
          ),
        ),

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
                    'Page ${_currentPage + 1} of ${(_filteredDepositHistory.length / _itemsPerPage).ceil()}',
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
                          _filteredDepositHistory.length
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),

      ),
    );
  }

  void showProcessingPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 12),
                  Text(
                    "Processing Payment...",
                    style: TextStyle(color: Colors.black, fontSize: 14),
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
