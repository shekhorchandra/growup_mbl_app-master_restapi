import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:growup_agro/views/pdf_viewer_page.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TaxCertificatePage extends StatefulWidget {
  const TaxCertificatePage({super.key});

  @override
  State<TaxCertificatePage> createState() => _TaxCertificatePageState();
}

class _TaxCertificatePageState extends State<TaxCertificatePage> {
  late Future<List<dynamic>> certificatesFuture;
  List<dynamic> _allCertificates = [];
  List<dynamic> _filteredCertificates = [];

  final Map<String, bool> _isDownloading = {};
  final Map<int, bool> _isExpanded = {}; // Track expanded state by index
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    certificatesFuture = fetchCertificates();
  }

  Future<List<dynamic>> fetchCertificates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final investorCode = prefs.getString('investor_code') ?? '';

      if (investorCode.isEmpty || token.isEmpty) {
        throw Exception('Missing token or investor code. Please log in again.');
      }

      final url = Uri.parse('https://growupagro.tech/api/tax-certificates?investor_code=$investorCode');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == true && decoded['data'] != null) {
          _allCertificates = decoded['data'];
          _filteredCertificates = List.from(_allCertificates);
          return _filteredCertificates;
        } else {
          throw Exception('No certificates found.');
        }
      } else {
        throw Exception('Failed to fetch data (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      rethrow;
    }
  }


  void _filterCertificates(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCertificates = List.from(_allCertificates);
      } else {
        _filteredCertificates = _allCertificates.where((cert) {
          final fiscal = cert['fiscal_year'];
          final projects = cert['projects'] as List;
          final fiscalText = '${fiscal['start']} - ${fiscal['end']}'.toLowerCase();
          final projectNames = projects.map((p) => (p['name'] ?? '').toLowerCase()).join(' ');
          return fiscalText.contains(query.toLowerCase()) || projectNames.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleExpand(int index) {
    setState(() {
      _isExpanded[index] = !(_isExpanded[index] ?? false);
    });
  }


  Future<void> downloadPdf(
      BuildContext context, String downloadUrl, String fiscalYearStart) async {
    setState(() {
      _isDownloading[downloadUrl] = true;
    });

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) {
        throw Exception('Missing token. Please log in again.');
      }

      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      // Get app-specific external storage directory
      Directory dir = (await getExternalStorageDirectory())!;

      // Create GrowUp folder inside app-specific storage
      final growUpDir = Directory('${dir.path}/GrowUp/All_Tax_Certificates');
      if (!await growUpDir.exists()) {
        await growUpDir.create(recursive: true);
      }

      // Set file path
      final savePath = '${growUpDir.path}/tax-certificate-$fiscalYearStart.pdf';

      // Download file
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('Progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded to: $savePath'),
          backgroundColor: Colors.green, // Green color
          duration: Duration(seconds: 10), // Show for 10 seconds
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      setState(() {
        _isDownloading[downloadUrl] = false;
      });
    }
  }





  // Future<void> viewPdf(BuildContext context, String previewUrl, String fiscalYearStart) async {
  //   try {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Loading PDF...')),
  //     );
  //
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('auth_token') ?? '';
  //     if (token.isEmpty) throw Exception('Missing token');
  //
  //     final dio = Dio();
  //     dio.options.headers['Authorization'] = 'Bearer $token';
  //
  //     final dir = await getTemporaryDirectory();
  //     final filePath = '${dir.path}/temp-view-$fiscalYearStart.pdf';
  //
  //     // Fetch bytes and save
  //     final response = await dio.get<List<int>>(
  //       previewUrl,
  //       options: Options(responseType: ResponseType.bytes),
  //     );
  //
  //     final file = File(filePath);
  //     await file.writeAsBytes(response.data!);
  //
  //     print('PDF saved to: $filePath, size: ${file.lengthSync()} bytes');
  //
  //     // Open PDF
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => PdfViewerPage(filePath: filePath),
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to load PDF: $e')),
  //     );
  //   }
  // }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tax Certificates',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: certificatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No certificates found.'));
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterCertificates,
                  decoration: InputDecoration(
                    hintText: 'Search by fiscal year or project name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              // Certificate List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _filteredCertificates.length,
                  itemBuilder: (context, index) {
                    final cert = _filteredCertificates[index];
                    final fiscal = cert['fiscal_year'];
                    final projects = cert['projects'] as List;
                    final previewUrl = cert['preview_url'];
                    final downloadUrl = cert['download_url'];
                    final expanded = _isExpanded[index] ?? false;

                    return GestureDetector(
                      onTap: () => _toggleExpand(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Always visible part
                            Text(
                              'Fiscal Year: ${fiscal['start']} to ${fiscal['end']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),

                            // Expandable part
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 10),
                                  ...projects.map((proj) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text('Project: ${proj['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                        Text('Investment: ${proj['total_investment']} BDT'),
                                        Text('ROI: ${proj['roi_amount']} BDT'),
                                        // Text('Invoice: ${proj['invoice_no']}'),
                                      ],
                                    ),
                                  )),
                                  const Divider(height: 20, thickness: 1),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // ElevatedButton.icon(
                                      //   onPressed: () => viewPdf(context, previewUrl, fiscal['start']),
                                      //   icon: const Icon(Icons.visibility),
                                      //   label: const Text('View'),
                                      //   style: ElevatedButton.styleFrom(
                                      //     backgroundColor: Colors.green,
                                      //     foregroundColor: Colors.white,
                                      //   ),
                                      // ),




                                      ElevatedButton.icon(
                                        onPressed: _isDownloading[downloadUrl] == true
                                            ? null
                                            : () async {
                                          await downloadPdf(context, downloadUrl, fiscal['start']);
                                        },
                                        icon: _isDownloading[downloadUrl] == true
                                            ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                            : const Icon(Icons.download),
                                        label: Text(_isDownloading[downloadUrl] == true ? 'Downloading...' : 'Download'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),

                                ],
                              ),
                              crossFadeState: expanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

