import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shurjopay/models/config.dart';
import 'package:shurjopay/models/shurjopay_request_model.dart';
import 'package:shurjopay/shurjopay.dart';
import 'package:shurjopay/utilities/functions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/deposit_model.dart';

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
  final TextEditingController _shurjopayController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _methods = [
    'Selected Method',
    'Cash Payment',
    'Bank Transfer',
    "Online payment (Shurjo Pay)",
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

  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy, h:mm a').format(
          date); // Example: 16 Jul 2025
    } catch (e) {
      return rawDate;
    }
  }


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

          final deposits =
          data.map((e) => DepositHistory.fromJson(e)).toList();

          deposits.sort((a, b) =>
              (b.updatedAt ?? DateTime(0)).compareTo(
                  a.updatedAt ?? DateTime(0)));

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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

// web browser---------------------------------------------------
//   Future<void> _handleShurjoPay() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     final prefs = await SharedPreferences.getInstance();
//     final investorCode = prefs.getString('investor_code') ?? '';
//     final token = prefs.getString('auth_token');
//     final investorId = prefs.getString('investor_id') ?? '';
//     print("Investor id: $investorId");
//     final email = prefs.getString('investor_email') ?? 'default@email.com';
//     final investorName = prefs.getString('investor_name') ?? '';
//     final investorPhone = prefs.getString('investor_phone') ?? '';
//     final investorAddress = prefs.getString('investor_address') ?? 'Dhaka';
//
//     if (investorCode.isEmpty) {
//       _showSnack("Investor code missing.");
//       setState(() => _isLoading = false);
//       return;
//     }
//
//     final enteredAmount = _amountController.text.trim();
//     if (enteredAmount.isEmpty || double.tryParse(enteredAmount) == null) {
//       _showSnack("Please enter a valid deposit amount.");
//       setState(() => _isLoading = false);
//       return;
//     }
//
//     final amount = double.parse(enteredAmount);
//
//     try {
//       // Step 1: Get ShurjoPay token
//       final tokenResponse = await http.post(
//         Uri.parse('https://engine.shurjopayment.com/api/get_token'),
//         headers: {
//           'Content-Type': 'application/json'
//         },
//         body: jsonEncode({
//           // 'username': 'sp_sandbox',
//           // 'password': 'pyyk97hu&6u6',
//           'username': 'growup_agrotech',
//           'password': 'growjjxwdm6wazy4',
//
//         }),
//       );
//
//       if (tokenResponse.statusCode != 200) {
//         _showSnack("Failed to get payment token.");
//         print('Token error body: ${tokenResponse.body}');
//         setState(() => _isLoading = false);
//         return;
//       }
//
//       final tokenData = jsonDecode(tokenResponse.body);
//       final spToken = tokenData['token'];
//       final storeId = tokenData['store_id'].toString();
//       final orderId = 'growup_${DateTime.now().millisecondsSinceEpoch}';
//       print(orderId);
//       print(storeId);
//
//       // Step 2: Initiate Payment
//       final paymentResponse = await http.post(
//         Uri.parse('https://engine.shurjopayment.com/api/secret-pay'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $spToken',
//         },
//         body: jsonEncode({
//           "prefix": "GAL",
//           "token": spToken,
//           "return_url":
//               "https://growupagro.tech/api/shurjopay/payment/callback",
//           "cancel_url":
//               "https://growupagro.tech/api/shurjopay/payment/callback",
//           "store_id": storeId,
//           "amount": amount,
//           "order_id": orderId,
//           "currency": "BDT",
//           "customer_name": investorName,
//           "customer_address": investorAddress,
//           "customer_city": "Dhaka",
//           "customer_email": email,
//           "customer_phone": investorPhone,
//           "customer_post_code": "1200",
//           "client_ip": "127.0.0.1",
//           "value1": investorId,
//           // "value2": widget.projectId?.toString() ?? '',
//           "value2": 'N/A',
//           "value3": "wallet_deposit",
//           "value4": "",
//         }),
//       );
//
//       print('Payment response status: ${paymentResponse.statusCode}');
//       print('Payment response body: ${paymentResponse.body}');
//
//       if (paymentResponse.statusCode != 200) {
//         final errorJson = jsonDecode(paymentResponse.body);
//         final errorMsg = errorJson['message'] ?? 'Payment initiation failed';
//         _showSnack(errorMsg);
//         setState(() => _isLoading = false);
//         return;
//       }
//
//       final paymentData = jsonDecode(paymentResponse.body);
//       final checkoutUrl =
//           paymentData['checkout_url'] ?? paymentData['redirect_url'] ?? '';
//       print('Checkout URL: $checkoutUrl');
//
//       if (checkoutUrl.isNotEmpty && checkoutUrl.startsWith('http')) {
//         final uri = Uri.parse(checkoutUrl);
//         if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//           _showSnack("Could not open payment page.");
//         }
//       } else {
//         _showSnack("Invalid payment URL.");
//       }
//     } catch (e) {
//       _showSnack("Error during payment: $e");
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

  //package-------------------------------------------------
  // Future<void> _handleShurjoPay() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   final prefs = await SharedPreferences.getInstance();
  //   final investorCode = prefs.getString('investor_code') ?? '';
  //   final investorId = prefs.getString('investor_id') ?? '';
  //   final email = prefs.getString('investor_email') ?? 'default@email.com';
  //   final investorName = prefs.getString('investor_name') ?? '';
  //   final investorPhone = prefs.getString('investor_phone') ?? '';
  //
  //   if (investorCode.isEmpty) {
  //     _showSnack("Investor code missing.");
  //     setState(() => _isLoading = false);
  //     return;
  //   }
  //   if (investorName.isEmpty) {
  //     _showSnack("Investor name missing.");
  //     setState(() => _isLoading = false);
  //     return;
  //   }
  //
  //   if (investorPhone.isEmpty) {
  //     _showSnack("Investor Phone missing.");
  //     setState(() => _isLoading = false);
  //     return;
  //   }
  //
  //   final enteredAmount = _amountController.text.trim();
  //   if (enteredAmount.isEmpty || double.tryParse(enteredAmount) == null) {
  //     _showSnack("Please enter a valid deposit amount.");
  //     setState(() => _isLoading = false);
  //     return;
  //   }
  //
  //   final amount = double.parse(enteredAmount);
  //
  //   try {
  //     final shurjoPay = ShurjoPay();
  //
  //     final request = ShurjopayRequestModel(
  //       configs: ShurjopayConfigs(
  //         // userName: 'growup_agrotech',
  //         // password: 'growjjxwdm6wazy4',
  //         userName: 'sp_sandbox',
  //         password: 'pyyk97hu&6u6',
  //         prefix: 'sp',
  //         clientIP: '127.0.0.1',
  //       ),
  //       currency: "BDT",
  //       amount: amount.toDouble(),
  //       orderID: "growup_${DateTime.now().millisecondsSinceEpoch}",
  //       customerName: investorName,
  //       customerPhoneNumber: investorPhone,
  //       customerEmail: email,
  //       customerAddress: "Dhaka, Bangladesh",
  //       customerCity: "Dhaka",
  //       customerPostcode: "1200",
  //       returnURL: "https://growupagro.tech/api/shurjopay/payment/callback",
  //       cancelURL: "https://growupagro.tech/api/shurjopay/payment/callback",
  //     );
  //
  //
  //     final response = await shurjoPay.makePayment(
  //       context: context,
  //       shurjopayRequestModel: request,
  //     );
  //
  //     if (response.status == true) {
  //       // You can also verify payment
  //       final verify = await shurjoPay.verifyPayment(
  //         orderID: response.shurjopayOrderID!,
  //       );
  //
  //       if (verify.spCode == "1000") {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: const Text("Payment Successful"),
  //             backgroundColor: Colors.green,
  //             duration: const Duration(seconds: 3),
  //           ),
  //         );
  //
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: const Text("Payment verification failed"),
  //             backgroundColor: Colors.red,
  //             duration: const Duration(seconds: 3),
  //           ),
  //         );
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: const Text("Payment initiation failed"),
  //           backgroundColor: Colors.red,
  //           duration: const Duration(seconds: 3),
  //         ),
  //       );
  //
  //     }
  //   } catch (e) {
  //     _showSnack("Error: $e");
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  // web browser + api-------------------------
  Future<void> _handleShurjoPay() async {
    setState(() {
      _isLoading = true;
    });

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
      // -----------------------------
      // Step 1: Initiate transaction
      // -----------------------------
      final initiateResponse = await http.post(
        Uri.parse('https://growupagro.tech/api/transaction-initiate'),
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
        print('Transaction initiation failed: ${initiateResponse.body}');
        _showSnack("Failed to initiate transaction.");
        setState(() => _isLoading = false);
        return;
      }

      print('Transaction initiate status: ${initiateResponse.statusCode}');
      print('Transaction initiate response: ${initiateResponse.body}');


      final initiateData = jsonDecode(initiateResponse.body);

      if (initiateData['success'] != true) {
        _showSnack(initiateData['message'] ?? 'Transaction initiation failed.');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Safely extract transaction ID
      final walletTransaction = initiateData['data']?['wallet_transaction'];
      final transactionId = walletTransaction?['id']?.toString();

      if (transactionId == null || transactionId.isEmpty) {
        _showSnack("Transaction ID missing from server response.");
        print("transactionId is null or empty");
        setState(() => _isLoading = false);
        return;
      }

      print("Transaction ID from backend: $transactionId");

      // -----------------------------
      // Step 2: Get ShurjoPay token
      // -----------------------------
      final tokenResponse = await http.post(
        Uri.parse('https://engine.shurjopayment.com/api/get_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'growup_agrotech',
          'password': 'growjjxwdm6wazy4',
        }),
      );

      if (tokenResponse.statusCode != 200) {
        _showSnack("Failed to get payment token.");
        print('Token error: ${tokenResponse.body}');
        setState(() => _isLoading = false);
        return;
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final spToken = tokenData['token'];
      final storeId = tokenData['store_id'].toString();
      final orderId = 'growup_${DateTime
          .now()
          .millisecondsSinceEpoch}';

      // -----------------------------
      // Step 3: Initiate ShurjoPay payment
      // -----------------------------
      final paymentResponse = await http.post(
        Uri.parse('https://engine.shurjopayment.com/api/secret-pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $spToken',
        },
        body: jsonEncode({
          "prefix": "GAL",
          "token": spToken,
          "return_url": "https://growupagro.tech/api/shurjopay/payment/callback",
          "cancel_url": "https://growupagro.tech/api/shurjopay/payment/callback",
          "store_id": storeId,
          "amount": amount,
          "order_id": orderId,
          "currency": "BDT",
          "customer_name": investorName,
          "customer_address": investorAddress,
          "customer_city": "Dhaka",
          "customer_email": email,
          "customer_phone": investorPhone,
          "customer_post_code": "1200",
          "client_ip": "127.0.0.1",
          "value1": investorId,
          "value2": "N/A",
          "value3": "wallet_deposit",
          "value4": transactionId, // ✅ Safe and verified
        }),
      );

      print('Payment response status: ${paymentResponse.statusCode}');
      print('Payment response body: ${paymentResponse.body}');

      if (paymentResponse.statusCode != 200) {
        final errorJson = jsonDecode(paymentResponse.body);
        final errorMsg = errorJson['message'] ?? 'Payment initiation failed';
        _showSnack(errorMsg);
        setState(() => _isLoading = false);
        return;
      }

      final paymentData = jsonDecode(paymentResponse.body);
      final checkoutUrl =
          paymentData['checkout_url'] ?? paymentData['redirect_url'] ?? '';

      if (checkoutUrl.isNotEmpty && checkoutUrl.startsWith('http')) {
        final uri = Uri.parse(checkoutUrl);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          _showSnack("Could not open payment page.");
        }
      } else {
        _showSnack("Invalid payment URL.");
      }
    } catch (e) {
      _showSnack("Error during payment: $e");
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      ..fields['payment_method'] =
      _selectedMethod == 'Bank Transfer' ? 'bank' : method;

    if (method == 'bank transfer') {
      request.fields['bank_name'] = _bankNameController.text;
      request.files.add(await http.MultipartFile.fromPath(
        'bank_payment_slip',
        _selectedImage!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
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
    // Normalize the selected method for conditional checks
    final method = _selectedMethod.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown for Deposit Method
          DropdownButtonFormField<String>(
            value: _selectedMethod,
            decoration: const InputDecoration(
              labelText: 'Deposit Method',
              border: OutlineInputBorder(),
            ),
            items: _methods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) => setState(() => _selectedMethod = val!),
          ),
          const SizedBox(height: 12),
          // Amount Field
          if (method != 'cashpayment')
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          if (method != 'cashpayment')
            const SizedBox(height: 12),



          // Mobile Banking Fields
          // if (['bkash', 'nagad', 'rocket'].contains(method)) ...[
          //   // ... (Your existing mobile banking fields) ...
          //   TextField(
          //     controller: _transactionIdController,
          //     decoration: const InputDecoration(
          //       labelText: 'Transaction ID',
          //       border: OutlineInputBorder(),
          //     ),
          //   ),
          //   const SizedBox(height: 8),
          //   TextField(
          //     controller: _mobileNumberController,
          //     decoration: const InputDecoration(
          //       labelText: 'Mobile Number',
          //       border: OutlineInputBorder(),
          //     ),
          //   ),
          // ],
          // Cash Payment Logic (UPDATED)
          if (method == 'cashpayment') ...[
            _buildCashPaymentInstructions(), // <-- Your new widget
            const SizedBox(height: 12),
          ],
          if (method == 'onlinepayment(shurjopay)') ...[
            _buildShurjopayInstructions(), // <-- Your new widget
            const SizedBox(height: 12),
          ],

          // Bank Transfer Fields (New Bank Details Widget Included)
          if (method == 'banktransfer') ...[

            // --- NEW: Multiple Bank Account Details ---
            // const SizedBox(height: 10),
            // _buildBankDetailsList(),
            // const SizedBox(height: 12),
            // ----------------------------------------

            // User's Bank Information (for your record)
            TextField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Your Bank Name (where you sent the money from)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Deposit Slip/Document Upload
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 100)
                : const Center(
                child: Text("Upload Deposit Document (Pdf or Image)")),
            Center(
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo, size: 40),
                label: const Text(""),
              ),
            ),
            bankTransferText(),
            _buildBankDetailsList(),
            const SizedBox(height: 12),
            // const SizedBox(height: 10),

            // --- NEW: Multiple Bank Account Details ---
            //  bankTransferText(),
            // _buildBankDetailsList(),
          ],

          // Shurjo Pay Field
          // if (method == 'onlinepayment(shurjopay)') ...[
          //   TextField(
          //     controller: _shurjopayController,
          //     decoration: const InputDecoration(
          //       labelText: 'Shurjo Pay',
          //       border: OutlineInputBorder(),
          //     ),
          //   ),
          //   const SizedBox(height: 10),
          // ],

          // Submit/Pay Button Logic
          const SizedBox(height: 10),
          if (method != 'cashpayment')
            _isSubmitting ||
                (method == 'onlinepayment(shurjopay)' && _isLoading)
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              child: method == 'onlinepayment(shurjopay)'
                  ? ElevatedButton(
                onPressed: _handleShurjoPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Pay with ShurjoPay',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : ElevatedButton(
                onPressed: _submitDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Deposit',
                  style: TextStyle(color: Colors.white),
                ),

              ),

            ),
          const SizedBox(height: 12),
          // _buildBankDetailsList(),
          // const SizedBox(height: 12),

          // Deposit History Section
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by amount, status and method Deposit History',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDepositHistoryTable(),
          const SizedBox(height: 16),
          // Pagination logic...
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 20),
              Text(
                'Page ${_currentPage + 1} of ${(_filteredDepositHistory.length /
                    _itemsPerPage).ceil()}',
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed:
                (_currentPage + 1) * _itemsPerPage <
                    _filteredDepositHistory.length
                    ? () => setState(() => _currentPage++)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // 3. New Widget to Display Bank Details
  // New Widget to Display Bank Details (Modified to include Copy Button)
  Widget _buildBankDetailsList() {
    // Function to handle copying the text to the clipboard
    void _copyToClipboard(String text) {
      Clipboard.setData(ClipboardData(text: text)).then((_) {
        // Show a temporary message (Snackbar) to confirm the copy
        // You need access to a ScaffoldMessenger for this,
        // which is usually available from a context in a StatelessWidget/StatefulWidget.
        // Assuming 'context' is available here or passed:
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
                              Icons.copy, size: 20, color: Colors.grey),
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

            // const SizedBox(height: 8),
            // const Text(
            //   '⚠️ এই পদ্ধতিতে ব্যাংকের NPSB, BFTEN,  RTGS, Fund Transfer, অথবা সরাসরি গ্র-আপের একাউন্ট এ ব্যাংক ডিপোজিট এর মাধ্যমে আপনার ওয়ালেট রিচার্জ করতে পারবেন। (ডিপোজিটের পর স্লিপটি সাবমিট করুন)',
            //   style: TextStyle(fontSize: 12, color: Colors.orange),
            // ),
          ],
        ),
      ),
    );
  }

  Widget bankTransferText() {
    return const Center(
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
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
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
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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


  Widget _buildShurjopayInstructions() {
    return const Card(
      elevation: 2,
      color: Color(0xFFE8F5E9), // Light green background for visibility
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'সুরক্ষিত অনলাইন পেমেন্ট এর মাধ্যমে ওয়ালেট রিচার্জ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32), // green tone for heading
              ),
            ),
            SizedBox(height: 8),
            Text(
              'আমাদের সুরক্ষিত পেমেন্ট গেটওয়ে (ShurjoPay)-এর মাধ্যমে যেকোনো মোবাইল ওয়ালেট (MFS) যেমন: বিকাশ, নগদ, রকেট, ব্যাংক কার্ড (ডেবিট, ক্রেডিট, প্রিপেইড) ব্যবহার করে সহজেই আপনার ওয়ালেট রিচার্জ করতে পারবেন। '
                  'এছাড়াও, নির্দিষ্ট ব্যাংকের ক্রেডিট কার্ড ব্যবহারকারীরা সহজ মাসিক কিস্তি (EMI) সুবিধা ব্যবহার করে ওয়ালেট রিচার্জ করতে পারবেন।',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5, // for better line spacing
              ),
            ),
          ],
        )

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
        Center(
          child: const Text(
            'Deposit History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                  const Color(0xFF388E3C)),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columnSpacing: 12,
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
                final DepositHistory item = currentItems[index];

                final invoiceNo = item.invoiceNo?.toString() ?? 'N/A';
                final hasInvoice = item.invoiceNo != null;

                final createdAt = item.createdAt != null
                    ? DateFormat('dd MMM yyyy, h:mm a').format(item.createdAt!)
                    : 'N/A';

                return DataRow(
                  cells: [
                    DataCell(Text('${_currentPage * _itemsPerPage + index +
                        1}')),
                    DataCell(Text(createdAt)),
                    DataCell(Text(item.amount)),
                    DataCell(Text(item.paymentMethod)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(item.note ?? 'N/A')),
                    DataCell(
                      item.status == "approved" && item.invoiceNo != null
                          ? (downloadingInvoices.contains(item.invoiceNo)
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : IconButton(
                        icon: const Icon(Icons.download, color: Colors.green, size: 20),
                        tooltip: 'Open Invoice in Browser',
                        onPressed: () => _openInvoiceInBrowser(item.invoiceNo ?? " "),
                      ))
                          : const Icon(
                        Icons.block,
                        color: Colors.red,
                        size: 24,
                      ),
                    )


                  ],
                );
              }),

            ),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // centerTitle: true,
        // backgroundColor: const Color(0xFF2E7D32),
        // foregroundColor: Colors.white,
        title: const Text(
          "Deposit Funds",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildDepositForm(),
          ),
        ),
      ),
    );
  }

  Future<void> _openInvoiceInBrowser(String? invoiceNo) async {
    // Exit if invoiceNo is null or empty
    if (invoiceNo == null || invoiceNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid invoice number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open invoice in browser.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening invoice: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Hide loading indicator
      if (mounted) {
        setState(() => downloadingInvoices.remove(invoiceNo));
      }
    }
  }



}

