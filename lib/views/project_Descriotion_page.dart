import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shurjopay/models/config.dart';
import 'package:shurjopay/models/payment_verification_model.dart';
import 'package:shurjopay/models/shurjopay_request_model.dart';
import 'package:shurjopay/models/shurjopay_response_model.dart';
import 'package:shurjopay/shurjopay.dart';
import '../models/project_details_model.dart';
import '../paymentService/payment_service.dart';
import '../widgets/custom_button.dart'; // your CustomButton file
import '../widgets/collapsible_html_text.dart';
import '../widgets/info_row.dart'; // your CollapsibleHtmlText file

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
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() => _showScrollToTopButton = _scrollController.offset > 300);
      });
    _fetchProjectDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<int> _fetchLatestWalletBalance(
    String token,
    String investorCode,
  ) async {
    try {
      final url = Uri.parse(ApiConstants.investorProfile(investorCode));
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final balanceStr =
            data['data']?['investor']?['wallet']?['balance']
                ?.toString()
                .replaceAll(',', '') ??
            '0';
        return double.tryParse(balanceStr)?.toInt() ?? 0;
      }
      throw Exception("Failed to fetch wallet balance");
    } catch (e) {
      debugPrint("⚠ Wallet balance error: $e");
      return 0;
    }
  }

  Future<void> _fetchProjectDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final url = Uri.parse(
      ApiConstants.investorProjectDetails(
        widget.investorCode,
        widget.projectId.toString(),
      ),
    );

    try {
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          _project = ProjectDetailsModel.fromJson(data);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to load project details'),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load project details')));
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    final parsed = DateTime.tryParse(date);
    return parsed == null ? 'N/A' : DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Project Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : project == null
          ? const Center(child: Text('Project data not available'))
          : RefreshIndicator(
              onRefresh: _fetchProjectDetails,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Adaptive Image
                    if (project.imageUrl != null &&
                        project.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          project.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 180,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 80),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // ✅ Header
                    Text(
                      project.projectName ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Category: ${project.projectCategoryName ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    Text(
                      "Project Code: ${project.projectCode ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    _sectionDivider("Overview"),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: _cardBoxDecoration(),
                      child: CollapsibleHtmlText(
                        htmlContent: project.overviewHtml ?? '',
                        collapsedLines: 4,
                        expandButtonColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // _sectionDivider("Key Points"),
                    // _buildKeyPointsCard(project),
                    // const SizedBox(height: 16),
                    _sectionDivider("Summary"),
                    _buildSummaryCard(project),
                    const SizedBox(height: 16),

                    if (project.securityInformation.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionDivider("Security Information"),
                          _buildSecurityCard(project),
                        ],
                      ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  // ---- UI helpers ----
  BoxDecoration _cardBoxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  Widget _sectionDivider(String title) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
      SizedBox(height: 5, child: const Divider(thickness: .5)),
      const SizedBox(height: 6),
    ],
  );

  // Widget _buildKeyPointsCard(ProjectDetailsModel project) {
  //   return Container(
  //     decoration: _cardBoxDecoration(),
  //     padding: const EdgeInsets.all(12),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         InfoRow(
  //           title: "Duration",
  //           value: _getKeyPoint("Duration of Investment"),
  //         ),
  //         InfoRow(
  //           title: "Projected ROI",
  //           value: _getKeyPoint("Projected ROI (Return on Investment)"),
  //         ),
  //         InfoRow(title: "Risk Factor", value: _getKeyPoint("Risk Factor")),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSummaryCard(ProjectDetailsModel project) {
    final nf = NumberFormat.decimalPattern();

    return Container(
      decoration: _cardBoxDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(title: 'Project Name', value: project.projectName),
          InfoRow(title: 'Business Type', value: project.businessTypeName),
          InfoRow(
            title: 'Investment Time',
            value: '${project.investment_time} days',
          ),
          InfoRow(
            title: 'Start Date',
            value: formatDate(project.project_start_date),
          ),
          InfoRow(
            title: 'Mature Date',
            value: formatDate(project.project_end_date),
          ),
          InfoRow(
            title: 'ROI Start Date',
            value: formatDate(project.roiStartDate),
          ),
          InfoRow(
            title: 'Investment Goal',
            value: '${nf.format(project.investmentGoal ?? 0)} Tk',
          ),
          InfoRow(
            title: 'Min Investment',
            value: '${nf.format(project.minInvestmentAmount ?? 0)} Tk',
          ),
          InfoRow(
            title: 'In Waiting',
            value: '${nf.format(project.in_waiting)} Tk',
          ),
          InfoRow(title: 'Raised', value: '${nf.format(project.rasied)} Tk'),
          InfoRow(title: 'ROI (%)', value: 'Annually ${project.annualRoi}%'),
          InfoRow(
            title: 'Project Duration',
            value: '${project.projectDurationViewer} Months',
          ),
          const SizedBox(height: 10),

          //Action buttons (CustomButton)
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Invest Now',
                  icon: Icons.account_balance_wallet,
                  backgroundColor: const Color(0xFFAECC00),
                  height: 44,
                  loading: _isInvestLoading,
                  onPressed: _isInvestLoading
                      ? null
                      : () async {
                          setState(() => _isInvestLoading = true);
                          await _triggerInvestDialog();
                          setState(() => _isInvestLoading = false);
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: 'Pay with Shurjopay',
                  icon: Icons.payment,
                  backgroundColor: Colors.green,
                  height: 44,
                  loading: _isShurjoLoading,
                  onPressed: _isShurjoLoading
                      ? null
                      : () async {
                          setState(() => _isShurjoLoading = true);
                          await _triggerShurjoInvestDialog();
                          setState(() => _isShurjoLoading = false);
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(ProjectDetailsModel project) => Container(
    decoration: _cardBoxDecoration(),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: project.securityInformation
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(item['name'] ?? '')),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );

  String _getKeyPoint(String title) {
    final project = _project;
    if (project == null) return 'N/A';
    final match = project.keyPointsData.firstWhere(
      (p) => p['title']?.toString().toLowerCase() == title.toLowerCase(),
      orElse: () => {},
    );
    return match['description'] ?? 'Not available';
  }

  // ✅ Investment & Payment dialogs
  Future<void> _triggerInvestDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final investorCode = prefs.getString('investor_code');
    if (token == null || investorCode == null) return;
    final walletBalance = await _fetchLatestWalletBalance(token, investorCode);
    final project = _project!;

    final controller = TextEditingController(
      text: project.minInvestmentAmount?.toString() ?? '0',
    );
    showDialog(
      context: context,
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text(
              "Invest in this Project",
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Wallet Balance: ৳$walletBalance"),
                Text("Min. Investment: ৳${project.minInvestmentAmount}"),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Investment Amount",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final amount = int.tryParse(controller.text) ?? 0;
                        if (amount < (project.minInvestmentAmount ?? 0)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Amount must be >= minimum investment.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (walletBalance < amount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Insufficient balance."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setState(() => loading = true);
                        try {
                          final res = await http.post(
                            Uri.parse(
                              'https://growupagro.tech/api/investor/invest-now',
                            ),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({
                              'project_id': widget.projectId,
                              'invest_amount': amount,
                              'investment_media': 1,
                              'investor_code': investorCode,
                            }),
                          );
                          final data = jsonDecode(res.body);
                          if (data['success'] == true) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Investment successful!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _fetchProjectDetails();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  data['message'] ?? 'Investment failed',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Confirm"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerShurjoInvestDialog() async {
    final resData = await _showInvestDialog(
      isGetwayPay: true,
      isSSL : false,
    ); //

    if (resData == null) return;

    if (resData['success'] == true ||
        (resData['message']?.toString().toLowerCase().contains('success') ??
            false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Congratulations! Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resData['message'] ?? 'Payment failed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _showInvestDialog({
    bool isGetwayPay = false,
    bool isSSL = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final investorCode = prefs.getString('investor_code');
    final investorId = prefs.getString('investor_id');
    final email = prefs.getString('investor_email') ?? 'default@email.com';
    final investorName = prefs.getString('investor_name') ?? '';
    final investorPhone = prefs.getString('investor_phone') ?? '';
    final investorAddress = prefs.getString('investor_address') ?? 'Dhaka';

    if (token == null ||
        investorId == null ||
        investorCode == null ||
        _project == null) {
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
                title: const Text(
                  "Invest in this Project",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoRow(
                        title: "Wallet Balance",
                        value: '৳$walletBalance',
                        fontSize: 12,
                        showDivider: false,
                      ),
                      InfoRow(
                        title: "Min. Investment",
                        value: '৳${project.minInvestmentAmount}',
                        fontSize: 12,
                        showDivider: false,
                      ),
                      InfoRow(
                        title: "In Waiting",
                        value: '৳${project.in_waiting}',
                        fontSize: 12,
                        showDivider: false,
                      ),
                      InfoRow(
                        title: "Investment Time",
                        value: '${project.investment_time} days',
                        fontSize: 12,
                        showDivider: false,
                      ),

                      const SizedBox(height: 24),
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
                  // Cancel Button
                  CustomButton(
                    text: "Cancel",
                    icon: Icons.close,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    height: 40,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    onPressed: _isLoading
                        ? null
                        : () {
                            disposeController();
                            Navigator.pop(dialogContext);
                          },
                  ),

                  // PAY / INVEST Button (uses loading spinner)
                  CustomButton(
                    text: isGetwayPay ? "PAY NOW" : "INVEST",
                    icon: isGetwayPay
                        ? Icons.payment
                        : Icons.account_balance_wallet,
                    backgroundColor: isGetwayPay ? Colors.green : Colors.blue,
                    textColor: Colors.white,
                    height: 40,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    loading: _isLoading,
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);

                            final amount = int.tryParse(amountController.text);

                            // ------------------- VALIDATION CHECKS -------------------
                            if (amount == null || amount <= 0) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(outerContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Enter a valid investment amount.",
                                  ),
                                ),
                              );
                              setState(() => _isLoading = false);
                              return;
                            }

                            if (amount < (project.minInvestmentAmount ?? 0)) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(outerContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Invest amount must be at least ৳${project.minInvestmentAmount}",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() => _isLoading = false);
                              return;
                            }

                            //if (project.investment_time > 1) { // dev
                            if (project.investment_time < 1) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(outerContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You can't invest. Investment time is too short.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() => _isLoading = false);
                              return;
                            }

                            if ((project.minInvestmentAmount ?? 0) >
                                project.in_waiting) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(outerContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You can't invest. In Waiting amount too low.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() => _isLoading = false);
                              return;
                            }

                            if (!isGetwayPay && walletBalance < amount) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(outerContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Insufficient wallet balance. Please recharge.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() => _isLoading = false);
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
                              setState(() => _isLoading = false);
                              return;
                            }

                            // ------------------- PAYMENT LOGIC -------------------
                            if (isGetwayPay) {
                              try {
                                if (token == null || token.isEmpty) {
                                  _showSnack(
                                    "Authorization token missing. Please login again.",
                                  );
                                  setState(() => _isLoading = false);
                                  return;
                                }

                                // 🔹 Step 1: Initiate transaction
                                final initiateResponse = await http.post(
                                  Uri.parse(
                                    '${ApiConstants.baseUrl}/transaction-initiate',
                                  ),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer $token',
                                  },
                                  body: jsonEncode({
                                    "amount": amount,
                                    "project_id": widget.projectId,
                                  }),
                                );

                                if (initiateResponse.statusCode != 200 &&
                                    initiateResponse.statusCode != 201) {
                                  _showSnack("Failed to initiate transaction.");
                                  Navigator.pop(dialogContext);
                                  setState(() => _isLoading = false);
                                  return;
                                }

                                final initiateData = jsonDecode(
                                  initiateResponse.body,
                                );
                                if (initiateData['success'] != true) {
                                  _showSnack(
                                    initiateData['message'] ??
                                        'Transaction initiation failed.',
                                  );
                                  Navigator.pop(dialogContext);
                                  setState(() => _isLoading = false);
                                  return;
                                }

                                final walletTransaction = initiateData['data'];
                                final transactionId = walletTransaction?['transaction_id']?.toString();
                                final walletTransactionId = walletTransaction?['wallet_transaction_id'];
                                final transactionAmount = walletTransaction?['amount'];

                                if (transactionId == null ||
                                    transactionId.isEmpty) {
                                  _showSnack(
                                    "Transaction ID missing from server response.",
                                  );
                                  Navigator.pop(dialogContext);
                                  setState(() => _isLoading = false);
                                  return;
                                }

                                if (isSSL) {
                                  // Initialize SSLCommerz
                                  Sslcommerz sslcommerz = Sslcommerz(
                                    initializer: SSLCommerzInitialization(
                                      multi_card_name: "visa,master,bkash",
                                      currency: SSLCurrencyType.BDT,
                                      product_category: "Digital Product",
                                      sdkType: SSLCSdkType.TESTBOX,
                                      // Change to LIVE later
                                      store_id: "datab67593a46c4062",
                                      store_passwd: "datab67593a46c4062@ssl",
                                      total_amount: transactionAmount
                                          .toDouble(),
                                      tran_id: transactionId,
                                    ),
                                  );

                                  final response = await sslcommerz.payNow();

                                  Navigator.pop(dialogContext);
                                  showProcessingPaymentDialog(context);
                                  _loadPaymentStatus(
                                    transactionId,
                                    _isLoading,
                                    context,
                                    response.status,
                                  );
                                } else {
                                  shurjoPay(
                                    walletTransactionId : walletTransactionId,
                                    investorId: investorId,
                                    dialogContext : dialogContext,
                                    transactionId: transactionId,
                                    transactionAmount: transactionAmount
                                        .toDouble(),
                                    investorName: investorName,
                                    investorPhone: investorPhone,
                                    investorEmail: email,
                                    investorAddress: investorAddress,
                                     isLoading: _isLoading,
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(outerContext).showSnackBar(
                                  SnackBar(content: Text('Payment failed: $e')),
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            } else {
                              // ------------------- WALLET FLOW -------------------
                              try {
                                final response = await http.post(
                                  Uri.parse(
                                    'https://growupagro.tech/api/investor/invest-now',
                                  ),
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
                                  ScaffoldMessenger.of(
                                    outerContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Payment successful!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(
                                    outerContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        resData['message'] ?? 'Payment failed',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(outerContext).showSnackBar(
                                  SnackBar(content: Text('Payment failed')),
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            }
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void shurjoPay({
    required transactionAmount,
    required String transactionId,
    required String investorName,
    required String investorPhone,
    required String investorEmail,
    required String investorAddress,
    required BuildContext dialogContext,
    required bool isLoading, required String investorId,
    int? walletTransactionId,
  }) async {
    Navigator.pop(dialogContext);
    final shurjoPay = ShurjoPay();

    ShurjopayConfigs shurjopayConfigs = ShurjopayConfigs(
      // prefix: "SP",
      // userName: "sp_sandbox",
      // password: "pyyk97hu&6u6",
      // clientIP: "127.0.0.1",
      prefix: "GAL",
      userName: 'growup_agrotech',
      password: 'growjjxwdm6wazy4',
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
      value3: "project_investment",
      value4: walletTransactionId.toString(),
      // Live: https://www.engine.shurjopayment.com/return_url
      // returnURL:
      // "https://www.sandbox.shurjopayment.com/return_url",

      returnURL:
      "https://www.engine.shurjopayment.com/return_url",

      // Live: https://www.engine.shurjopayment.com/cancel_url
      // cancelURL:
      // "https://www.sandbox.shurjopayment.com/cancel_url",

      cancelURL:
      "https://www.engine.shurjopayment.com/cancel_url",
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

    if (status == 'VALID' || status == 'approved' || status == 'ShurjoPay') {
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

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
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
