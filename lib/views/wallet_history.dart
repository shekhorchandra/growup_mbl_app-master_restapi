import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/wallet_history_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletHistoryPage extends StatefulWidget {
  const WalletHistoryPage({super.key});

  @override
  State<WalletHistoryPage> createState() => _WalletHistoryPageState();
}

class _WalletHistoryPageState extends State<WalletHistoryPage> {
  List<WalletHistoryModel> fullHistory = [];
  List<WalletHistoryModel> filteredHistory = [];
  Set<String> downloadingInvoices = {};

  int _selectedIndex = 0;
  final List<Widget> _pages = [
    // MenuPage(),       // index 0
    // GrowupPage(),     // index 1
    // PropertyPage(),   // index 2
    // TradingPage(),    // index 3
    // WebTabPage(),     // index 4 <-- this shows your WebView
  ];
  int currentPage = 1;
  final int rowsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchWalletHistory();
    _searchController.addListener(() {
      _filterHistory(_searchController.text);
    });
  }

  Future<void> _fetchWalletHistory() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final investorCode = prefs.getString('investor_code') ?? '';

      if (token.isEmpty || investorCode.isEmpty) {
        throw Exception("Missing token or investor code");
      }

      // final response = await http.get(
      //   Uri.parse(
      //       'https://admin-growup.onebitstore.site/api/wallet-history?investor_code=$investorCode'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //   },
      // );
      final response = await http.get(
        Uri.parse(ApiConstants.walletHistory(investorCode)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'];
        final historyList = data
            .map((e) => WalletHistoryModel.fromJson(e))
            .toList();

        setState(() {
          fullHistory = historyList;
          filteredHistory = fullHistory;
          currentPage = 1;
        });
      } else {
        throw Exception(
          'Error ${response.statusCode}: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Wallet Transaction History not found",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red, // 🔴 red background
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterHistory(String query) {
    final filtered = fullHistory.where((item) {
      final trxId = item.trxId.toLowerCase();
      final type = item.type.toLowerCase();
      return trxId.contains(query.toLowerCase()) ||
          type.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredHistory = filtered;
      currentPage = 1;
    });
  }

  List<WalletHistoryModel> get currentPageItems {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage > filteredHistory.length)
        ? filteredHistory.length
        : (startIndex + rowsPerPage);
    return filteredHistory.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    if (currentPage * rowsPerPage < filteredHistory.length) {
      setState(() {
        currentPage++;
      });
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  String _formatDateTime(String rawDateTime) {
    try {
      final dateTime = DateTime.parse(rawDateTime);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _openInvoiceInBrowser(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open invoice link')),
      );
    }
  }

  Future<void> _downloadInvoice(
      BuildContext context,
      String url,
      String invoiceNo,
      ) async {
    try {
      double progress = 0.0;
      final dio = Dio();

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$invoiceNo.pdf';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Starting download for $invoiceNo...')),
      );

      // 🔽 Download with progress callback
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress = (received / total) * 100;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 500),
                content: Text('Downloading $invoiceNo... ${progress.toStringAsFixed(0)}%'),
              ),
            );
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Download complete: $invoiceNo.pdf')),
      );

      // 📂 Automatically open the downloaded file
      await OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Download failed: $e')),
      );
    }
  }




  ///  Custom Status Chip
  Widget _getStatusChip(String? status) {
    if (status == null) return const Text('N/A');

    final lowerStatus = status.toLowerCase();
    // late Color backgroundColor;
    late Color textColor;

    switch (lowerStatus) {
      case 'approved':
        // backgroundColor = Colors.green;
        textColor = Colors.green;
        break;
      case 'rejected':
        // backgroundColor = Colors.red;
        textColor = Colors.red;
        break;
      case 'pending':
        // backgroundColor = Colors.orange;
        textColor = Colors.orange;
        break;
      case 'completed':
        // backgroundColor = Colors.lightGreen;
        textColor = Colors.greenAccent;
        break;
      case 'failed':
        // backgroundColor = Colors.redAccent;
        textColor = Colors.redAccent;
        break;
      default:
        // backgroundColor = Colors.grey;
        textColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wallet Transaction History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),

      body: RefreshIndicator(
        onRefresh: _fetchWalletHistory,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    IndexedStack(index: _selectedIndex, children: _pages),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by Transaction ID or Type',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Card(
                            child: DataTable(
                              columnSpacing: 14,
                              dataRowHeight: 120,
                              headingRowColor: MaterialStateProperty.all(
                                const Color(0xFF388E3C),
                              ),
                              headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              columns: const [
                                DataColumn(label: Text('SL')),
                                DataColumn(label: Text('Transaction Info')),

                                // DataColumn(label: Text('Date')),
                                // DataColumn(label: Text('Amount')),
                                // DataColumn(label: Text('Status')),
                                //DataColumn(label: Text('Actioned By')),
                                DataColumn(
                                  label: Text('Actions'),
                                ), // download button
                              ],
                              rows: List.generate(currentPageItems.length, (
                                index,
                              ) {
                                final item = currentPageItems[index];
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        '${(currentPage - 1) * rowsPerPage + index + 1}',
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: '${item.type}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Text.rich(
                                              //   TextSpan(
                                              //     children: [
                                              //       TextSpan(
                                              //         text: '${item.date}',
                                              //         style: const TextStyle(
                                              //           fontSize: 12,
                                              //           color: Colors.black54,
                                              //         ),
                                              //       ),
                                              //     ],
                                              //   ),
                                              // ),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          '৳${item.amount.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: (item.context),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text.rich(
                                                  TextSpan(
                                                    text: '${item.date}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              _getStatusChip(item.status),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // DataCell(
                                    //     Column(
                                    //       crossAxisAlignment:
                                    //       CrossAxisAlignment.start,
                                    //       mainAxisAlignment:
                                    //       MainAxisAlignment.center,
                                    //       children: [
                                    //         Text.rich(
                                    //           TextSpan(
                                    //             children: [
                                    //               TextSpan(
                                    //                 text: '${item.date}',
                                    //                 style: const TextStyle(
                                    //                   fontSize: 12,
                                    //                 ),
                                    //               ),
                                    //             ],
                                    //           ),
                                    //         ),
                                    //
                                    //       ],
                                    //     )),

                                    // DataCell(
                                    //     Column(
                                    //   crossAxisAlignment:
                                    //   CrossAxisAlignment.start,
                                    //   mainAxisAlignment:
                                    //   MainAxisAlignment.center,
                                    //   children: [
                                    //     Text.rich(
                                    //       TextSpan(
                                    //         children: [
                                    //           TextSpan(
                                    //             text: '৳${item.amount.toStringAsFixed(2)}',
                                    //             style: const TextStyle(
                                    //               fontSize: 12,
                                    //               fontWeight: FontWeight.bold,
                                    //               color: Colors.black,
                                    //             ),
                                    //           ),
                                    //         ],
                                    //       ),
                                    //     ),
                                    //
                                    //   ],
                                    // )),
                                    // DataCell(_getStatusChip(item.status)),
                                    // const DataCell(Text('N/A')),
                                    // DataCell(Text(item.note ?? 'N/A')),
                                    DataCell(
                                      item.status == "Approved"
                                          ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // 👁️ View Button
                                          ElevatedButton(
                                            onPressed: () => _openInvoiceInBrowser(
                                              context,
                                              item.invoice_view_url.toString(), // ✅ correct param
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
                                              style: TextStyle(fontSize: 10),
                                            ),
                                          ),

                                          const SizedBox(height: 2),

                                          // 💾 Download Button
                                          ElevatedButton(
                                            onPressed: () {
                                              if (item.invoice_download_url == null ||
                                                  item.invoice_download_url!.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Download URL not available')),
                                                );
                                                return;
                                              }

                                              _downloadInvoice(
                                                context,
                                                item.invoice_download_url!,
                                                item.invoiceNo.toString(),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber[200],
                                              foregroundColor: Colors.black,
                                              elevation: 2,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              minimumSize: const Size(0, 0),
                                            ),
                                            child: const Text(
                                              'Download',
                                              style: TextStyle(fontSize: 10),
                                            ),
                                          ),
                                        ],
                                      )
                                          : const Icon(Icons.block, color: Colors.red, size: 24),
                                    ),






                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60), // less vertical space
                    Transform.translate(
                      offset: const Offset(0, -48), // adjust upward
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 26, // smaller button height
                            child: ElevatedButton(
                              onPressed: currentPage > 1 ? _previousPage : null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5), // 7px border radius
                                ),
                              ),
                              child: const Text('Previous', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 24), // more space between buttons
                          Text(
                            'Page $currentPage of ${(filteredHistory.length / rowsPerPage).ceil()}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            height: 26, // smaller button height
                            child: ElevatedButton(
                              onPressed: currentPage * rowsPerPage < filteredHistory.length
                                  ? _nextPage
                                  : null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5), // 7px border radius
                                ),
                              ),
                              child: const Text('Next', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),


                  ],
                ),
        ),
      ),
    );
  }
}
