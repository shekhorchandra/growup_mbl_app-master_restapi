import 'dart:io';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/invoice_capital_return_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

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
  final currencyFormatter =
  NumberFormat.currency(locale: 'en_US', symbol: '৳');

  Map<String, bool> _isDownloading = {}; // track downloading status

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
    final filtered = fullList.where((item) {
      final name = item.projectName.toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredList = filtered;
      currentPage = 1;
    });
  }

  List<CapitalReturn> get currentPageItems {
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

  Future<List<CapitalReturn>> fetchCapitalReturns() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';
    // final String url =
    //     "https://growupagro.tech/api/capital-returns?investor_code=$investorCode";

    final String url = ApiConstants.capitalReturns(investorCode); // use constant

    try {
      final response = await Dio().get(
        url,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> list = response.data['data'];
        for (var item in list) {
          final invoiceNo = item['invoice_no'] ?? '';
          if (invoiceNo.isNotEmpty) _isDownloading[invoiceNo] = false;
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

  Future<void> downloadInvoicePdf(BuildContext context, String invoiceNo) async {
    setState(() {
      _isDownloading[invoiceNo] = true;
    });

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) {
        throw Exception('Missing token. Please log in again.');
      }

      // Build download URL
      final url = ApiConstants.capitalReturnInvoiceDownload(invoiceNo);

      // Debug the URL
      debugPrint('Download URL: $url');

      // Use external storage directory
      Directory dir = (await getExternalStorageDirectory())!;
      final savePath = '${dir.path}/Invoice-$invoiceNo.pdf';


      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      await dio.download(
        url,
        savePath,
        // onReceiveProgress: (received, total) {
        //   if (total != -1) {
        //     debugPrint('Progress: ${(received / total * 100).toStringAsFixed(0)}%');
        //   }
        // },
        options: Options(
          responseType: ResponseType.bytes, // Critical: treat as binary
          followRedirects: true,
        ),
      );



      // Optionally open the file after download
      await OpenFile.open(savePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice downloaded to $savePath')),
      );
    } catch (e) {
      debugPrint("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      setState(() {
        _isDownloading[invoiceNo] = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capital Returns Invoices', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                          final slNumber = ((currentPage - 1) * rowsPerPage) + currentPageItems.indexOf(item) + 1;

                          return DataRow(cells: [
                            DataCell(Text('$slNumber')),
                            // DataCell(Text(item.projectName)),
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
                                //         text: 'Project ID: ',
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
                            DataCell(Text(currencyFormatter.format(double.tryParse(item.capitalReturn) ?? 0))),
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
                                      backgroundColor: Colors.blueGrey[200],
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

                                  // 💾 Download Button
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
                                      backgroundColor: Colors.blue[200],
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

                                ],
                              ),
                            )


                          ]);
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
