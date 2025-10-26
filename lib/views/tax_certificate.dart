import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
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

      // ✅ GET API with query parameter
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

  Future<void> downloadCertificate(BuildContext context, String url, String fileName) async {
    try {
      setState(() => _isDownloading[url] = true);

      final Directory dir = await getApplicationDocumentsDirectory();
      final String filePath = '${dir.path}/$fileName.pdf';

      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final file = File(filePath);
      await file.writeAsBytes(response.data);
      await OpenFile.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded successfully: $fileName.pdf'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isDownloading[url] = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

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
        foregroundColor: Colors.white,
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
              // 🔍 Search Bar
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterCertificates,
                  decoration: InputDecoration(
                    hintText: 'Search by fiscal year or project name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              // 📋 Certificate List
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

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fiscal Year: ${fiscal['start']} - ${fiscal['end']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...projects.map((proj) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Project: ${proj['name']}', style: const TextStyle(fontSize: 16)),
                                  Text('Investment: ${proj['total_investment']} BDT'),
                                  Text('ROI: ${proj['roi_amount']} BDT'),
                                  Text('Invoice: ${proj['invoice_no']}'),
                                ],
                              ),
                            )),
                            const Divider(height: 20, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _launchURL(previewUrl),
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('View'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isDownloading[downloadUrl] == true
                                      ? null
                                      : () async {
                                    await downloadCertificate(context, downloadUrl, fiscal['start']);
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
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
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
