import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shurjopay/models/config.dart';
import 'package:shurjopay/models/shurjopay_request_model.dart';
import 'package:shurjopay/shurjopay.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:shurjopay_sdk/shurjopay_sdk.dart';
import 'package:get/get.dart'; // for Get.context
import 'package:shurjopay/shurjopay.dart';

import '../models/project_details_model.dart';
import '../paymentService/payment_service.dart';

class ProjectDescriptionPage extends StatefulWidget {
  final int projectId;
  final String investorCode;

  const ProjectDescriptionPage({
    Key? key,
    required this.projectId,
    required this.investorCode,
  }) : super(key: key);

  @override
  State<ProjectDescriptionPage> createState() => _ProjectDescriptionPageState();
}

class _ProjectDescriptionPageState extends State<ProjectDescriptionPage> {
  ProjectDetailsModel? _project;
  bool _loading = true;
  bool _isInvestLoading = false;
  bool _isShurjoLoading = false;



  late ScrollController _scrollController;
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300) {
        if (!_showScrollToTopButton) {
          setState(() {
            _showScrollToTopButton = true;
          });
        }
      } else {
        if (_showScrollToTopButton) {
          setState(() {
            _showScrollToTopButton = false;
          });
        }
      }
    });
    _fetchProjectDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<int> _fetchLatestWalletBalance(String token, String investorCode) async {
    try {
      // final url = Uri.parse('https://admin-growup.onebitstore.site/api/investor/profile?investor_code=$investorCode');
      final url = Uri.parse(ApiConstants.investorProfile(investorCode));
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final balanceStr = data['data']?['investor']?['wallet']?['balance']?.toString().replaceAll(',', '') ?? '0';
        return double.tryParse(balanceStr)?.toInt() ?? 0;
      } else {
        throw Exception("Failed to fetch wallet balance");
      }
    } catch (e) {
      debugPrint("Error fetching wallet balance: $e");
      return 0; // fallback
    }
  }

  Future<void> _fetchProjectDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      return;
    }

    // final url = Uri.parse(
    //   'https://admin-growup.onebitstore.site/api/investor/project-details'
    //       '?investor_code=${widget.investorCode}&project_id=${widget.projectId}',
    // );
    final url = Uri.parse(
      ApiConstants.investorProjectDetails(
        widget.investorCode,
        widget.projectId.toString(), // ✅ convert int → String
      ),
    );


    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _project = ProjectDetailsModel.fromJson(data);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load project details')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load project details')),
      );
    }
  }

  String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    final parsedDate = DateTime.tryParse(isoDate);
    if (parsedDate == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details', style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white),),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : project == null
          ? const Center(child: Text('Project data not available'))
          : SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.imageUrl != null && project.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  project.imageUrl!,
                  // height: 350,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 100),
                ),
              ),
            const SizedBox(height: 16),
            Text(project.projectName ?? 'No Title',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Category: ${project.projectCategoryName ?? 'N/A'}"),
            Text("Project Code: ${project.projectCode ?? 'N/A'}"),
            const Divider(height: 30),
            const Text("Project Overview:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Html(data: project.overviewHtml ?? ''),
            const SizedBox(height: 10),
            _buildKeyPointsCard(project),

            const SizedBox(height: 15),
            _buildSummaryCard(project),
            const SizedBox(height: 15),
            if (project.securityInformation.isNotEmpty) _buildSecurityCard(project),
            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: const Icon(Icons.arrow_upward, color: Colors.white,),
      )
          : null,
    );
  }

  Widget _buildKeyPointsCard(ProjectDetailsModel project) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Key Points", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InfoRow(title: "Duration", value: _getKeyPoint("Duration of Investment")),
            InfoRow(title: "Projected ROI", value: _getKeyPoint("Projected ROI (Return on Investment)")),
            InfoRow(title: "Risk Factor", value: _getKeyPoint("Risk Factor")),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ProjectDetailsModel project) {
    // ---- helper: parse any reasonable date string ----
    DateTime? _parseDate(String? raw) {
      if (raw == null || raw.trim().isEmpty) return null;
      try {
        // most backends send either "yyyy-MM-dd" or "yyyy-MM-dd HH:mm:ss"
        if (raw.contains(' ')) {
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
        }
        if (raw.contains('-')) {
          return DateFormat('yyyy-MM-dd').parse(raw, true).toLocal();
        }
        if (raw.contains('/')) {
          return DateFormat('dd/MM/yyyy').parse(raw, true).toLocal();
        }
      } catch (e) {
        debugPrint('❌ date parse failed for "$raw": $e');
      }
      return null;
    }

    // ---- numeric conversions ----
    final int raised = project.rasied ?? 0;
    final int investmentGoalValue =
        double.tryParse(project.investmentGoal.toString().replaceAll(',', ''))?.toInt() ?? 0;

    final DateTime? rawStartDate = _parseDate(project.project_start_date);
    final DateTime? rawRoiStartDate = _parseDate(project.roiStartDate);
    final DateTime today = DateTime.now();

// ---- strip time part (keep only year, month, day) ----
    final DateTime? startDate = rawStartDate != null
        ? DateTime(rawStartDate.year, rawStartDate.month, rawStartDate.day)
        : null;
    final DateTime? roiStartDate = rawRoiStartDate != null
        ? DateTime(rawRoiStartDate.year, rawRoiStartDate.month, rawRoiStartDate.day)
        : null;

    final DateTime todayDate = DateTime(today.year, today.month, today.day);

// ---- active investment logic (pure date check) ----
    final bool isInvestmentActive =
        startDate != null &&
            roiStartDate != null &&
            !todayDate.isBefore(startDate) && // today >= startDate
            todayDate.isBefore(roiStartDate) && // today < roiStartDate
            raised <= investmentGoalValue;

// ---- DEBUG PRINTS ----
    final dateFormatter = DateFormat('yyyy-MM-dd');
    debugPrint('-------------------------------------------');
    debugPrint('🕒 Today: ${dateFormatter.format(todayDate)}');
    debugPrint('📅 Start Date: ${startDate != null ? dateFormatter.format(startDate) : "null"}');
    debugPrint('💰 ROI Start Date: ${roiStartDate != null ? dateFormatter.format(roiStartDate) : "null"}');
    debugPrint('📊 Raised: $raised');
    debugPrint('🎯 Goal: $investmentGoalValue');
    debugPrint('✅ isInvestmentActive: $isInvestmentActive');
    debugPrint('-------------------------------------------');

    // ---- UI ----
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            InfoRow(title: 'Project Name', value: project.projectName),
            InfoRow(title: 'Business Type', value: project.businessTypeName),
            InfoRow(
                title: 'Investment Time',
                value: '${project.investment_time.toString()} days'),
            InfoRow(
                title: 'Start Date',
                value: formatDate(project.project_start_date)),
            InfoRow(
                title: 'Mature Date',
                value: formatDate(project.project_end_date)),
            InfoRow(
                title: 'ROI Start Date',
                value: formatDate(project.roiStartDate)),
            // InfoRow(
            //     title: 'Investment Goal',
            //     value: '${project.investmentGoal} Tk'),

            InfoRow(
              title: 'Investment Goal',
              value: '${NumberFormat.decimalPattern().format(project.investmentGoal ?? 0)} Tk',
            ),

            InfoRow(
                title: 'Min Investment',
                value:
                '${NumberFormat.decimalPattern().format(project.minInvestmentAmount ?? 0)} Tk'),
            InfoRow(
                title: 'In Waiting',
                value:
                '${NumberFormat.decimalPattern().format(project.in_waiting)} Tk'),
            InfoRow(
                title: 'Raised',
                value:
                '${NumberFormat.decimalPattern().format(project.rasied)} Tk'),
            InfoRow(title: 'Projected', value: project.projected),
            InfoRow(
                title: 'ROI (%)',
                value:
                'Annually ${double.tryParse(project.annualRoi)?.toStringAsFixed(2) ?? project.annualRoi}%'),
            InfoRow(
              title: 'Project Duration',
              value: '${project.projectDurationViewer} Months',
            ),

            InfoRow(
              title: 'Project Status',
              value: project.status == 1 ? 'Running' : 'Closed',
              style: TextStyle(
                color: project.status == 1 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ---- conditional buttons ----
            if (isInvestmentActive)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInvestLoading || _isShurjoLoading
                          ? null
                          : () async {
                        setState(() => _isInvestLoading = true);
                        await _triggerInvestDialog();
                        if (mounted) setState(() => _isInvestLoading = false);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAECC00)),
                      child: _isInvestLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Invest Now',
                          style:
                          TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInvestLoading || _isShurjoLoading
                          ? null
                          : () async {
                        setState(() => _isShurjoLoading = true);
                        await _triggerShurjoInvestDialog();
                        if (mounted) setState(() => _isShurjoLoading = false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: _isShurjoLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Pay with SSLCOMMERZ',
                          style:
                          TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard(ProjectDetailsModel project) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Project Security Information",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...project.securityInformation.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(item['name'] ?? '')),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerShurjoInvestDialog() async {
    final resData = await _showInvestDialog(isShurjoPay: true); // ✅ MARKED: Added isShurjoPay

    if (resData == null) return;

    if (resData['success'] == true ||
        (resData['message']?.toString().toLowerCase().contains('success') ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Congratulations! Payment successful!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resData['message'] ?? 'Payment failed.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _triggerInvestDialog() async {
    final resData = await _showInvestDialog();

    if (resData == null) return; // dialog cancelled

    if (resData['success'] == true ||
        (resData['message']?.toString().toLowerCase().contains('success') ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Congratulation! Investment successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resData['message'] ?? 'Investment failed.'),
          backgroundColor: Colors.red,
        ),
      );
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

  Future<void> _loadPaymentStatus(String transactionId, bool _isLoading, BuildContext dialogContext, String? status) async {
    final result = await PaymentService.fetchPaymentSuccess(transactionId, status!);

    if (status == 'VALID') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result == "success" ? "Transaction successful" : "Transaction failed"),
          backgroundColor: result == "success" ? Colors.green : Colors.red,
        ),
      );
    } else if (status == 'Closed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cancel by user"),
          backgroundColor: Colors.red,
        ),
      );
    } else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed"),
          backgroundColor: Colors.red,
        ),
      );
    }

    print('Payment completed, gg TRX ID: ${result}');

    setState(() {
      _isLoading = false;
    });
    Navigator.pop(context);
  }

  Future<Map<String, dynamic>?> _showInvestDialog({bool isShurjoPay = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final investorCode = prefs.getString('investor_code');
    final investorId = prefs.getString('investor_id');
    final email = prefs.getString('investor_email') ?? 'default@email.com';
    final investorName = prefs.getString('investor_name') ?? '';
    final investorPhone = prefs.getString('investor_phone') ?? '';
    final investorAddress = prefs.getString('investor_address') ?? 'Dhaka';

    if (token == null || investorId == null || investorCode == null || _project == null) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing data or login required.")),
      );
      return null;
    }

    final walletBalance = await _fetchLatestWalletBalance(token, investorCode);
    final project = _project!;
    final outerContext = context;

    return showDialog<Map<String, dynamic>>(
      context: outerContext,
      builder: (dialogContext) {
        bool _isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            final amountController = TextEditingController(
              text: project.minInvestmentAmount?.toString() ?? '0',
            );

            void disposeController() {
              amountController.dispose();
            }

            return WillPopScope(
              onWillPop: () async {
                disposeController();
                return true;
              },
              child: AlertDialog(
                title: const Text("Invest in this Project"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Wallet Balance: ৳$walletBalance"),
                      Text("Min. Investment: ৳${project.minInvestmentAmount}"),
                      Text("In Waiting: ৳${project.in_waiting}"),
                      Text("Investment Time: ${project.investment_time} days"),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Invest Amount',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      disposeController();
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _isLoading
                        ? null
                        : () async {
                      setState(() {
                        _isLoading = true;
                      });

                      final amount = int.tryParse(amountController.text);

                      if (amount == null || amount <= 0) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(outerContext).showSnackBar(
                          const SnackBar(content: Text("Enter a valid investment amount.")),
                        );
                        setState(() {
                          _isLoading = false;
                        });
                        return;
                      }

                      if (amount < (project.minInvestmentAmount ?? 0)) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(outerContext).showSnackBar(
                          SnackBar(
                            content: Text("Invest amount must be at least ৳${project.minInvestmentAmount}"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _isLoading = false;
                        });
                        return;
                      }

                      if (project.investment_time < 1) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(outerContext).showSnackBar(
                          const SnackBar(
                            content: Text("You can't invest. Investment time is too short."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _isLoading = false;
                        });
                        return;
                      }

                      if ((project.minInvestmentAmount ?? 0) > project.in_waiting) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(outerContext).showSnackBar(
                          const SnackBar(
                            content: Text("You can't invest. In Waiting amount too low."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _isLoading = false;
                        });
                        return;
                      }

                      if (!isShurjoPay && walletBalance < amount) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(outerContext).showSnackBar(
                          const SnackBar(
                            content: Text("Insufficient wallet balance. Please recharge."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _isLoading = false;
                        });
                        return;
                      }

                      if (project.status != 1) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(outerContext).showSnackBar(
                          const SnackBar(
                            content: Text("Project is not running."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _isLoading = false;
                        });
                        return;
                      }

                      if (isShurjoPay) {
                        try {
                          if (token == null || token.isEmpty) {
                            _showSnack("Authorization token missing. Please login again.");
                            setState(() => _isLoading = false);
                            return;
                          }

                          // -----------------------------
                          // Step 1: Initiate transaction
                          // -----------------------------
                          final initiateResponse = await http.post(
                            Uri.parse('https://growupagro.online/api/transaction-initiate'),
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
                            _showSnack(initiateData['message'] ?? 'Transaction initiation failed.');
                            setState(() => _isLoading = false);
                            return;
                          }

                          final walletTransaction = initiateData['data'];
                          final transactionId = walletTransaction?['transaction_id']?.toString();
                          final transactionAmount = walletTransaction?['amount'];
                          if (transactionId == null || transactionId.isEmpty) {
                            _showSnack("Transaction ID missing from server response.");
                            setState(() => _isLoading = false);
                            return;
                          }

                          print("✅ Transaction ID: $transactionId");

                          Sslcommerz sslcommerz = Sslcommerz(
                            initializer: SSLCommerzInitialization(
                              multi_card_name: "visa,master,bkash",
                              currency: SSLCurrencyType.BDT,
                              product_category: "Digital Product",
                              sdkType: SSLCSdkType.TESTBOX,
                              store_id: "datab67593a46c4062",
                              store_passwd: "datab67593a46c4062@ssl",
                              total_amount: transactionAmount.toDouble(),
                              tran_id: transactionId,
                            ),
                          );

                          final response = await sslcommerz.payNow();

                          print("✅ Transaction status: ${response.status}");

                          if (response.status == 'VALID') {
                            print(jsonEncode(response));

                            print('Payment completed, TRX ID: ${response.tranId}');
                            print(response.tranDate);

                            setState(() => _isLoading = true);

                            Navigator.pop(dialogContext);

                            showProcessingPaymentDialog(context);

                            _loadPaymentStatus(transactionId, _isLoading, context, response.status);
                          }

                          if (response.status == 'Closed') {
                            print('Payment closed');

                            setState(() => _isLoading = true);

                            Navigator.pop(dialogContext);

                            showProcessingPaymentDialog(context);

                            _loadPaymentStatus(transactionId, _isLoading, context, response.status);
                          }

                          if (response.status == 'FAILED') {
                            print('Payment failed: ${response.toJson()}');

                            setState(() => _isLoading = true);

                            Navigator.pop(dialogContext);

                            showProcessingPaymentDialog(context);

                            _loadPaymentStatus(transactionId, _isLoading, context, response.status);
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(outerContext).showSnackBar(
                            SnackBar(content: Text('Payment failed: $e')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      } else {
                        // Wallet payment flow (unchanged)
                        try {
                          final response = await http.post(
                            Uri.parse('https://growupagro.tech/api/investor/invest-now'),
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer $token',
                            },
                            body: jsonEncode({
                              'project_id': widget.projectId,
                              'invest_amount': amount,
                              'investment_media': 1,
                              'investor_code': investorCode,
                            }),
                          );

                          final resData = jsonDecode(response.body);
                          if (!mounted) return;

                          if (resData['success'] == true) {
                            disposeController();
                            Navigator.pop(dialogContext, resData);
                            ScaffoldMessenger.of(outerContext).showSnackBar(
                              const SnackBar(
                                content: Text('Investment successful!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(outerContext).showSnackBar(
                              SnackBar(
                                content: Text(resData['message'] ?? 'Investment failed'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(outerContext).showSnackBar(
                            SnackBar(content: Text('❌ Investment failed: $e')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      }
                    },
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(isShurjoPay ? "PAY NOW" : "INVEST",
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getKeyPoint(String title) {
    final project = _project;
    if (project == null) return 'Not available';

    final match = project.keyPointsData.firstWhere(
          (point) => point['title']?.toString().trim().toLowerCase() == title.trim().toLowerCase(),
      orElse: () => {},
    );

    return match['description'] ?? 'Not available';
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

class InfoRow extends StatelessWidget {
  final String title;
  final String? value;
  final TextStyle? style;

  const InfoRow({
    super.key,
    required this.title,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text("$title:", style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 6, child: Text(value ?? "N/A", softWrap: true, style: style ?? const TextStyle())),
        ],
      ),
    );
  }
}

