import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:growup_agro/models/invoice_capital_return_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CapitalReturnPage extends StatefulWidget {
  const CapitalReturnPage({super.key});

  @override
  State<CapitalReturnPage> createState() => _CapitalReturnPageState();
}

class _CapitalReturnPageState extends State<CapitalReturnPage> {
  late Future<List<CapitalReturn>> futureCapitalReturns;

  List<CapitalReturn> fullList = [];
  List<CapitalReturn> filteredList = [];
  int currentPage = 1;
  final int rowsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '৳');

  // Button states
  final Map<String, bool> _isViewing = {};
  final Map<String, bool> _isDownloading = {};
  // null => preparing; 0..1 => progress
  final Map<String, double?> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    futureCapitalReturns = fetchCapitalReturns();
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
      final name = item.projectName.toLowerCase();
      return name.contains(q);
    }).toList();

    setState(() {
      filteredList = filtered;
      currentPage = 1;
    });
  }

  List<CapitalReturn> get currentPageItems {
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

  Future<List<CapitalReturn>> fetchCapitalReturns() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    final String url = ApiConstants.capitalReturns(investorCode);

    try {
      final response = await Dio().get(
        url,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        // initialize button states for each available invoice
        for (final e in list) {
          final invoiceNo = (e['invoice_no'] ?? '').toString();
          if (invoiceNo.isNotEmpty && invoiceNo != 'N/A') {
            _isDownloading[invoiceNo] = false;
            _isViewing[invoiceNo] = false;
          }
        }
        return list.map((e) => CapitalReturn.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching capital returns: $e");
      return [];
    }
  }

  bool _hasInvoice(CapitalReturn item) {
    final no = item.invoiceNo;
    return no.isNotEmpty && no != 'N/A';
  }

  Future<void> viewInvoicePdf(BuildContext context, String invoiceNo) async {
    setState(() => _isViewing[invoiceNo] = true); // loader for View only
    try {
      final url = ApiConstants.capitalReturnInvoiceDownload(invoiceNo);
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
      BuildContext context,
      String invoiceNo,
      ) async {
    setState(() {
      _isDownloading[invoiceNo] = true;     // loader for Download
      _downloadProgress[invoiceNo] = null;  // preparing
    });

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );

    try {
      final url = ApiConstants.capitalReturnInvoiceDownload(invoiceNo);
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
      if (bytes.isEmpty) {
        throw Exception('Empty response while downloading PDF.');
      }
      if (!_looksLikePdf(bytes)) {
        throw Exception('The server did not return a PDF (HTML or other).');
      }

      // Save to temp first
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/invoice_$invoiceNo.pdf';
      await File(tempPath).writeAsBytes(bytes, flush: true);

      // Ask user where to save
      final savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: tempPath,
          fileName: 'invoice_$invoiceNo.pdf',
        ),
      );

      if (savedPath == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save cancelled.')),
          );
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: $savedPath')),
        );
      }

      await OpenFilex.open(savedPath);
    } catch (e) {
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

  Widget _viewButton(BuildContext context, CapitalReturn item) {
    if (!_hasInvoice(item)) return const SizedBox.shrink(); // hide View

    final busy = _isViewing[item.invoiceNo] == true;
    return InkWell(
      onTap: busy ? null : () => viewInvoicePdf(context, item.invoiceNo),
      child: Container(
        height: 24,
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _downloadButton(BuildContext context, CapitalReturn item) {
    if (!_hasInvoice(item)) {
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
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(100, 24),
        ),
        child: const Text('No Invoice'),
      );
    }

    final downloading = _isDownloading[item.invoiceNo] == true;
    final progress = _downloadProgress[item.invoiceNo];

    return Column(
      children: [
        InkWell(
          onTap: downloading ? null : () => downloadInvoicePdf(context, item.invoiceNo),
          child: Container(
            height: 24,
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
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                if (progress == null) {
                  // preparing / unknown total
                  return const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                } else {
                  final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
                  return Text(
                    "$pct%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }
              }(),
            ),
          ),
        ),
        if (downloading && (progress ?? -1) >= 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 100,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(value: progress),
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
        title: const Text(
          'Capital Returns Invoices',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: FutureBuilder<List<CapitalReturn>>(
        future: futureCapitalReturns,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No capital returns found."));
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
                    hintText: 'Search by project name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.all(12),
                      elevation: 3,
                      child: DataTable(
                        columnSpacing: 28,
                        dataRowHeight: 100,
                        headingRowHeight: 60,
                        headingRowColor: MaterialStateProperty.all(const Color(0xFF388E3C)),
                        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(label: Text('SL')),
                          DataColumn(label: Text('Project')),
                          DataColumn(label: Text('Capital Return')),
                          DataColumn(label: Text('Invoice No')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: currentPageItems.map((item) {
                          final slNumber = ((currentPage - 1) * rowsPerPage) +
                              currentPageItems.indexOf(item) + 1;

                          return DataRow(cells: [
                            DataCell(Text('$slNumber')),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(item.projectName,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Category: ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        TextSpan(
                                          text: item.projectCategory,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                currencyFormatter.format(
                                  double.tryParse(item.capitalReturn) ?? 0,
                                ),
                              ),
                            ),
                            DataCell(Text(item.invoiceNo)),
                            DataCell(
                              Column(
                                mainAxisSize: MainAxisSize.min,
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 26,
                        child: ElevatedButton(
                          onPressed: currentPage > 1 ? _previousPage : null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Previous', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      Text(
                        'Page $currentPage of ${(filteredList.length / rowsPerPage).ceil()}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(
                        height: 26,
                        child: ElevatedButton(
                          onPressed: currentPage * rowsPerPage < filteredList.length ? _nextPage : null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Next', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
