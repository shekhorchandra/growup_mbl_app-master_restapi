import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/recharge_model.dart';

class InvoiceRechargePage extends StatefulWidget {
  const InvoiceRechargePage({super.key});

  @override
  State<InvoiceRechargePage> createState() => _InvoiceRechargePageState();
}

class _InvoiceRechargePageState extends State<InvoiceRechargePage> {
  late Future<List<Recharge>> futureRecharges;

  List<Recharge> fullList = [];
  List<Recharge> filteredList = [];
  int currentPage = 1;
  final int rowsPerPage = 10;

  final Map<String, bool> _isViewing = {};
  final Map<String, bool> _isDownloading = {};
  final Map<String, double?> _downloadProgress = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureRecharges = fetchRecharges();
    _searchController.addListener(() {
      _filterList(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterList(String query) {
    final q = query.toLowerCase().trim();
    final filtered = fullList.where((item) {
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

    setState(() {
      filteredList = filtered;
      currentPage = 1;
    });
  }

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

  Future<List<Recharge>> fetchRecharges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    final url = Uri.parse(ApiConstants.recharges(investorCode));

    try {
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
          return list.map((e) => Recharge.fromJson(e)).toList();
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching recharges: $e");
      return [];
    }
  }

  Future<void> viewInvoicePdf(BuildContext context, String invoiceNo) async {
    setState(() => _isViewing[invoiceNo] = true);
    try {
      final url = ApiConstants.rechargeInvoicePdf(invoiceNo);
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open invoice in browser.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error opening invoice: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open invoice.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isViewing[invoiceNo] = false);
    }
  }

  bool _looksLikePdf(Uint8List bytes) {
    if (bytes.length < 4) return false;
    final header = String.fromCharCodes(bytes.sublist(0, 4));
    return header == '%PDF';
  }

  Future<void> downloadInvoicePdf(
      BuildContext context, String invoiceNo) async {
    setState(() {
      _isDownloading[invoiceNo] = true;
      _downloadProgress[invoiceNo] = null;
    });

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.bytes,
      ),
    );

    try {
      final url = ApiConstants.rechargeInvoicePdf(invoiceNo);
      final uri = Uri.parse(url);

      final response = await dio.getUri<List<int>>(
        uri,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() => _downloadProgress[invoiceNo] =
                (received / total).clamp(0, 1));
          }
        },
      );

      final bytes = Uint8List.fromList(response.data ?? []);
      if (bytes.isEmpty || !_looksLikePdf(bytes)) {
        throw Exception('Invalid PDF format.');
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/invoice_$invoiceNo.pdf';
      await File(tempPath).writeAsBytes(bytes, flush: true);

      final savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: tempPath,
          fileName: 'invoice_$invoiceNo.pdf',
        ),
      );

      if (savedPath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: $savedPath')),
        );
        await OpenFilex.open(savedPath);
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
    } finally {
      setState(() {
        _isDownloading[invoiceNo] = false;
        _downloadProgress.remove(invoiceNo);
      });
    }
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

  Widget _downloadButton(BuildContext context, Recharge item) {
    final downloading = _isDownloading[item.invoiceNo] == true;
    final progress = _downloadProgress[item.invoiceNo];
    final hasInvoice =
    !(item.invoiceDownloadUrl == null && item.invoiceNo == "N/A");

    if (!hasInvoice) {
      return ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No invoice available"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(100, 28),
        ),
        child: const Text('No Invoice'),
      );
    }

    return InkWell(
      onTap: downloading
          ? null
          : () => downloadInvoicePdf(context, item.invoiceNo.toString()),
      child: Container(
        height: 28,
        width: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFFFA24C),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: () {
            if (!downloading) {
              return const Text(
                "Download",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            }
            if (progress == null) {
              return const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            } else {
              final pct = (progress * 100).toStringAsFixed(0);
              return Text(
                "$pct%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
          }(),
        ),
      ),
    );
  }

  Widget _viewButton(BuildContext context, Recharge item) {
    final busy = _isViewing[item.invoiceNo] == true;
    final hasInvoice =
    !(item.invoiceDownloadUrl == null && item.invoiceNo == "N/A");

    if (!hasInvoice) return const SizedBox.shrink(); // Hides View button

    return InkWell(
      onTap: busy
          ? null
          : () => viewInvoicePdf(context, item.invoiceNo.toString()),
      child: Container(
        height: 28,
        width: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: busy
              ? const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text(
            "View",
            style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recharge History Invoices',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: FutureBuilder<List<Recharge>>(
        future: futureRecharges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No recharge found."));
          }

          if (fullList.isEmpty) {
            fullList = snapshot.data!;
            filteredList = fullList;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                    'Search by date or amount or method or status...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Card(
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: DataTable(
                        columnSpacing: 28,
                        dataRowHeight: 72,
                        headingRowHeight: 60,
                        headingRowColor:
                        MaterialStateProperty.all(const Color(0xFF388E3C)),
                        headingTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(label: Text('SL')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Method')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: currentPageItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final slNumber =
                              ((currentPage - 1) * rowsPerPage) + index + 1;

                          return DataRow(cells: [
                            DataCell(Text('$slNumber')),
                            DataCell(Text(item.date ?? '-')),
                            DataCell(Text(item.amount ?? '-')),
                            DataCell(Text(item.method ?? '-')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(item.status ?? ''),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (item.status ?? '').toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(item.note ?? '-')),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _viewButton(context, item),
                                  const SizedBox(height: 6),
                                  _downloadButton(context, item),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 45),
              Transform.translate(
                offset: const Offset(0, -52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage > 1 ? _previousPage : null,
                        child: const Text('Previous'),
                      ),
                      Text(
                        'Page $currentPage of ${(filteredList.length / rowsPerPage).ceil()}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      ElevatedButton(
                        onPressed: currentPage * rowsPerPage <
                            filteredList.length
                            ? _nextPage
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
