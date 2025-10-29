import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';



class ProjectInvestmentDetailPage extends StatefulWidget {
  final int projectId;
  final String projectTitle;
  final String projectCategory;

  const ProjectInvestmentDetailPage({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.projectCategory,
  });

  @override
  State<ProjectInvestmentDetailPage> createState() =>
      _ProjectInvestmentDetailPageState();
}

class _ProjectInvestmentDetailPageState extends State<ProjectInvestmentDetailPage> {
  List<dynamic> allInvestments = [];
  List<dynamic> filteredInvestments = [];
  Set<String> downloadingInvoices = {};


  final TextEditingController _searchController = TextEditingController();

  int currentPage = 1;
  final int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchInvestments();
    _searchController.addListener(() {
      _filterInvestments(_searchController.text);
    });
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy, h:mm a').format(date); // Customize as needed
    } catch (e) {
      return rawDate;
    }
  }


  void _filterInvestments(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredInvestments = allInvestments.where((item) {
        final invoice = item['invoice_no']?.toString() ?? '';
        final amount = item['amount']?.toString() ?? '';
        return invoice.contains(lowerQuery) || amount.contains(lowerQuery);
      }).toList();
      currentPage = 1; // Reset to first page on search
    });
  }

  List<dynamic> get currentPageItems {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage) > filteredInvestments.length
        ? filteredInvestments.length
        : startIndex + rowsPerPage;
    return filteredInvestments.sublist(startIndex, endIndex);
  }

  Future<void> _fetchInvestments() async {
    final prefs = await SharedPreferences.getInstance();
    final investorCode = prefs.getString('investor_code') ?? '';
    final token = prefs.getString('auth_token') ?? '';

    // final url = Uri.parse(
    //     'https://admin-growup.onebitstore.site/api/peoject/investment/detail?investor_code=$investorCode&project_id=${widget
    //         .projectId}');

    final url = Uri.parse(
      ApiConstants.projectInvestmentDetail(
        investorCode,
        widget.projectId.toString(),
      ),
    );


    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        setState(() {
          allInvestments = data;
          filteredInvestments = data;
        });
      } else {
        throw Exception('Failed to load project investments');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  void _nextPage() {
    final totalPages = (filteredInvestments.length / rowsPerPage).ceil();
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (filteredInvestments.length / rowsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: Text('Investments Details', style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by amount or invoice',
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
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: constraints.maxWidth),
                        child: SingleChildScrollView(
                          child: Card(
                            child: DataTable(
                              columnSpacing: 24,
                              dataRowHeight: 72,
                              // ✅ This is valid and avoids conflict
                              headingRowColor: MaterialStateProperty.all(
                                  Colors.green.shade700),
                              headingTextStyle: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                              columns: const [
                                DataColumn(label: Text('SL')),
                                DataColumn(label: Text('Project')),
                                DataColumn(label: Text('Investment')),
                                DataColumn(label: Text('Invoice No')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: List.generate(currentPageItems.length, (index) {
                                final item = currentPageItems[index];
                                final serial = ((currentPage - 1) * rowsPerPage) +
                                    index + 1;
                                                
                                return DataRow(
                                  cells: [
                                    DataCell(Text('$serial')),
                                                
                                    // Project (Title, Category, ID)
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          widget.projectTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14, // optional, adjust as needed
                                          ),
                                        ),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Category: ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: widget.projectCategory,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Text('Project ID: ${widget.projectId}',
                                            style: const TextStyle(fontSize: 12)),
                                      ],
                                    )),
                                                
                                    // Investment (Amount, Updated Date)
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('৳${item['amount']}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Investment Date:\n',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              TextSpan(
                                                text: formatDate(item['investment_date']),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),




                                      ],
                                    )),
                                                
                                    // Invoice No
                                    DataCell(
                                        Text(item['invoice_no'].toString())),
                                                
                                    // Actions (View, Download)
                                    DataCell(
                                      item['invoice_no'] != null && item['invoice_no'] != 0
                                          ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // 👁️ View Button
                                          ElevatedButton(
                                            onPressed: () => _downloadInvoice(context, item['invoice_no'].toString()),
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

                                          const SizedBox(height: 4),
/*
                                          // 💾 Download Button or Loading Spinner
                                          (downloadingInvoices.contains(item['invoice_no'].toString()))
                                              ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                              : ElevatedButton(
                                            onPressed: () => _downloadInvoice(context, item['invoice_no'].toString()),
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
                                          */
                                        ],
                                      )
                                          : const Text('N/A'),
                                    ),





                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Pagination Controls
                const SizedBox(height: 45),
// Pagination at bottom center
                Transform.translate(
                  offset: const Offset(0, -52), // move upward slightly
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30), // proper horizontal padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 26, // smaller button height
                          child: ElevatedButton(
                            onPressed: currentPage > 1 ? _previousPage : null,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5), // rounded corners
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Previous', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        Text(
                          'Page $currentPage of $totalPages',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          height: 26, // smaller button height
                          child: ElevatedButton(
                            onPressed: currentPage < totalPages ? _nextPage : null,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5), // rounded corners
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
      ),
    );
  }


  Future<void> _downloadInvoice(BuildContext context, String? invoiceNo) async {
    // 🟡 Handle null or empty invoice number
    if (invoiceNo == null || invoiceNo.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No invoice found for this record. Please contact support if this issue persists.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show loader
    setState(() {
      downloadingInvoices.add(invoiceNo);
    });

    final url = ApiConstants.invoicePdf(invoiceNo); // e.g., https://growupagro.tech/dashboard/invoice/pdf/{invoiceNo}
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // opens in default browser
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open invoice.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Hide loader
      setState(() {
        downloadingInvoices.remove(invoiceNo);
      });
    }
  }



}





