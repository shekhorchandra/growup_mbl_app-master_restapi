import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';



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



  Future<void> downloadCertificate(
      BuildContext context, String url, String fileName) async {
    setState(() => _isDownloading[url] = true);

    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        followRedirects: true,
        validateStatus: (status) => status != null && status >= 200 && status < 400,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ));

      // Temporary file path
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName.pdf';

      // Download PDF
      final uri = Uri.parse(url);
      final response = await dio.getUri<List<int>>(
        uri,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Optional: show progress in UI
            final percent = (received / total * 100).toStringAsFixed(0);
            debugPrint('Downloading $fileName: $percent%');
          }
        },
      );

      if (response.data == null || response.data!.isEmpty) {
        throw Exception('Empty response while downloading PDF.');
      }

      // Write to temp file
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(response.data!, flush: true);

      // Ask user where to save
      final savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: tempPath,
          fileName: '$fileName.pdf',
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
          SnackBar(
            content: Text('Downloaded successfully: $savedPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Open file automatically
      await OpenFilex.open(savedPath);
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isDownloading[url] = false);
    }
  }


  // Future<void> viewCertificate(BuildContext context, String url) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('auth_token') ?? '';
  //
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => Scaffold(
  //         appBar: AppBar(title: const Text('Certificate Preview')),
  //         body: WebView(
  //           initialUrl: url,
  //           javascriptMode: JavascriptMode.unrestricted,
  //           initialHeaders: {
  //             'Authorization': 'Bearer $token',
  //             'Accept': 'application/pdf',
  //           },
  //         ),
  //       ),
  //     ),
  //   );
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
                    var expanded = _isExpanded[index] ?? false;

                    return GestureDetector(
                      onTap: () => _toggleExpand(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 1),

                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Always visible part (with toggle)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Fiscal Year",
                                      ),
                                      Text(
                                        '${fiscal['start']} - ${fiscal['end']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ]),

                                IconButton(
                                  icon: Icon(
                                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _toggleExpand(index);
                                      expanded = !expanded;
                                    });
                                  },
                                ),
                              ],
                            ),

                            // Expandable part
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  ...projects.map(
                                        (proj) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Project: ${proj['name']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const Divider(height: 4, thickness: 1),

                                          SizedBox(height: 4),
                                          Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Investment'),
                                                Text('${proj['total_investment']} BDT'),
                                              ]
                                          ),
                                          Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('ROI'),
                                                Text('${proj['roi_amount']} BDT'),
                                              ]
                                          ),
                                          // Text('Invoice: ${proj['invoice_no']}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 20, thickness: 1),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // ElevatedButton.icon(
                                      //   onPressed: () => viewCertificate(context, previewUrl),
                                      //   icon: const Icon(Icons.visibility),
                                      //   label: const Text('   View    '),
                                      //   style: ElevatedButton.styleFrom(
                                      //     backgroundColor: Colors.green,
                                      //     foregroundColor: Colors.white,
                                      //   ),
                                      // ),
                                      ElevatedButton.icon(
                                        onPressed: _isDownloading[downloadUrl] == true
                                            ? null
                                            : () async {
                                          await downloadCertificate(
                                              context, downloadUrl, fiscal['start']);
                                        },
                                        icon: _isDownloading[downloadUrl] == true
                                            ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white),
                                        )
                                            : const Icon(Icons.download),
                                        label: Text(_isDownloading[downloadUrl] == true
                                            ? 'Downloading...'
                                            : 'Download'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
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

