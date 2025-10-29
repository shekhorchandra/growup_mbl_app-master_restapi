import 'dart:convert';
import 'dart:io' show Directory, File;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/invoice_roi_model.dart';

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

  int currentPage = 1;
  final int rowsPerPage = 10;
  Map<String, bool> _isDownloading = {};


  @override
  void initState() {
    super.initState();
    futureRois = fetchRois();
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
    final filtered = fullList.where((item) {
      final projectName = item.projectName.toLowerCase();
      final projectCategory = item.projectCategory.toLowerCase();
      final projectCode = item.projectCode.toLowerCase();
      final invoiceNo = item.invoiceNo.toLowerCase();
      return projectName.contains(query.toLowerCase()) ||
          projectCategory.contains(query.toLowerCase()) ||
          projectCode.contains(query.toLowerCase()) ||
          invoiceNo.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredList = filtered;
      currentPage = 1;
    });
  }

  List<RoiInvoice> get currentPageItems {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex =
    (startIndex + rowsPerPage) > filteredList.length ? filteredList.length : (startIndex + rowsPerPage);
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

  Future<List<RoiInvoice>> fetchRois() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';
    // final url =
    //     "https://growupagro.tech/api/rois?investor_code=$investorCode";

    if (token.isEmpty || investorCode.isEmpty) return [];

    final url = Uri.parse(ApiConstants.roiListinvoice(investorCode)); // ✅ use constant and Uri.parse

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
        if (data['status'] == true && data['data'] != null) {
          final list = (data['data'] as List)
              .map((e) => RoiInvoice.fromJson(e))
              .toList();

          // Assign fullList and filteredList here
          setState(() {
            fullList = list;
            filteredList = list;
          });

          return list;
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching ROI invoices: $e");
      return [];
    }
  }


  Future<void> downloadInvoicePdf(BuildContext context, String invoiceNo) async {
    try {
      setState(() => _isDownloading[invoiceNo] = true); // start loading

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token missing.')),
        );
        setState(() => _isDownloading[invoiceNo] = false);
        return;
      }

      // final url = "https://growupagro.tech/api/roi-invoice-download/$invoiceNo";

      final url = ApiConstants.roiInvoiceDownload(invoiceNo);


      final Directory dir = await getApplicationDocumentsDirectory();
      final String filePath = '${dir.path}/Invoice-$invoiceNo.pdf';

      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/pdf",
          },
          responseType: ResponseType.bytes,
        ),
      );

      final file = File(filePath);
      await file.writeAsBytes(response.data);

      await OpenFilex.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice downloaded to $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: something went wrong'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isDownloading[invoiceNo] = false); // stop loading
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ROI Invoices',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: FutureBuilder<List<RoiInvoice>>(
        future: futureRois,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (fullList.isEmpty) {
            return const Center(child: Text("No ROI invoices found."));
          }


          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by project or invoice...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Table
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Card(
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                          DataColumn(label: Text('ROI')),
                          DataColumn(label: Text('Invoice No')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: currentPageItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final slNumber = ((currentPage - 1) * rowsPerPage) + index + 1;

                          return DataRow(
                            cells: [
                              DataCell(Text('$slNumber')),
                              // Project stacked info
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(item.projectName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                  // Text.rich(
                                  //   TextSpan(
                                  //     children: [
                                  //       const TextSpan(
                                  //         text: 'Project ID:',
                                  //         style: TextStyle(
                                  //           fontSize: 12,
                                  //           fontWeight: FontWeight.bold,
                                  //           color: Colors.grey,
                                  //         ),
                                  //       ),
                                  //       TextSpan(
                                  //         text: item.projectCode,
                                  //         style: const TextStyle(
                                  //           fontSize: 12,
                                  //           color: Colors.grey,
                                  //         ),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),

                                ],
                              )),
                              DataCell(Text('৳${double.parse(item.totalRoi).toStringAsFixed(2)}')),


                              DataCell(Text(item.invoiceNo)),
                              DataCell(
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 👁️ View Button
                                    ElevatedButton(
                                      onPressed: () => downloadInvoicePdf(
                                        context,
                                        item.invoiceNo.toString(),
                                      ),
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

                                    // 💾 Download Button or loading spinner
                                    (_isDownloading[item.invoiceNo] == true)
                                        ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : ElevatedButton(
                                      onPressed: () async {
                                        await downloadInvoicePdf(context, item.invoiceNo);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[200], // Download button color
                                        foregroundColor: Colors.black,
                                        elevation: 2,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        minimumSize: const Size(0, 0),
                                      ),
                                      child: const Text(
                                        'Download',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    */
                                  ],
                                ),
                              )


// Action column empty
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 45),
              Transform.translate(
                offset: const Offset(0, -52), // move upward slightly
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30), // proper padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // space between buttons and text
                    children: [
                      SizedBox(
                        height: 26, // smaller button height
                        child: ElevatedButton(
                          onPressed: currentPage > 1 ? _previousPage : null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5), // 5px border radius
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
                        height: 26, // smaller button height
                        child: ElevatedButton(
                          onPressed: currentPage * rowsPerPage < filteredList.length ? _nextPage : null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5), // 5px border radius
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
