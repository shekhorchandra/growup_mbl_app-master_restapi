import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/project_certificate_model.dart';
import 'package:growup_agro/views/web_view_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectCertificatesPage extends StatefulWidget {
  const ProjectCertificatesPage({super.key});

  @override
  State<ProjectCertificatesPage> createState() =>
      _ProjectCertificatesPageState();
}

class _ProjectCertificatesPageState extends State<ProjectCertificatesPage> {
  late String token;
  late Future<List<ProjectCertificate>> _certificatesFuture;

  List<ProjectCertificate> _allCertificates = [];
  List<ProjectCertificate> _filteredCertificates = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token') ?? '';
    _certificatesFuture = fetchCertificates();
    _certificatesFuture.then((list) {
      setState(() {
        _allCertificates = list;
        _filteredCertificates = list;
      });
    });
  }

  Future<List<ProjectCertificate>> fetchCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final investorCode = prefs.getString('investor_code') ?? '';

    if (investorCode.isEmpty || token.isEmpty) {
      throw Exception('Missing token or investor code.');
    }

    final url = Uri.parse(
        "https://growupagro.tech/api/investor/project-certificates?investor_code=$investorCode");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == true) {
        return (jsonResponse['data'] as List)
            .map((e) => ProjectCertificate.fromJson(e))
            .toList();
      } else {
        throw Exception('No certificates found.');
      }
    } else {
      throw Exception('Failed to load certificates.');
    }
  }

  void _filterCertificates(String query) {
    setState(() {
      _filteredCertificates = _allCertificates.where((cert) {
        final name = cert.name.toLowerCase();
        final code = cert.code.toLowerCase();
        final roi = cert.roi.toString().toLowerCase();
        final search = query.toLowerCase();
        return name.contains(search) ||
            code.contains(search) ||
            roi.contains(search);
      }).toList();
    });
  }

  Future<void> launchInBrowser(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Project Certificates',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCertificates,
              decoration: InputDecoration(
                hintText: 'Search by project name, code, or ROI',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green),
                ),
              ),
            ),
          ),

          // 📜 Certificates List
          Expanded(
            child: FutureBuilder<List<ProjectCertificate>>(
              future: _certificatesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (_filteredCertificates.isEmpty) {
                  return const Center(child: Text('No matching certificates'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _filteredCertificates.length,
                  itemBuilder: (context, index) {
                    final item = _filteredCertificates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("Code: ${item.code}"),
                            Text("ROI: ${item.roi}%"),
                            Text("Ends: ${item.endDate}"),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (item.previewUrl.isNotEmpty) {
                                      try {
                                        // Try opening in WebView
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PreviewPage(url: item.previewUrl),
                                          ),
                                        );
                                      } catch (e) {
                                        print('WebView failed, opening in browser: $e');
                                        launchInBrowser(context, item.previewUrl); // fallback
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Preview URL not available')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.remove_red_eye),
                                  label: const Text('View', style: TextStyle(fontSize: 10)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey[200],
                                    foregroundColor: Colors.black,
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    minimumSize: const Size(0, 0),
                                  ),
                                ),





                                // const Spacer(),
                                // ElevatedButton.icon(
                                //   onPressed: () {
                                //     _launchURL(item.downloadUrl);
                                //   },
                                //   icon: const Icon(Icons.download),
                                //   label: const Text('Download'),
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: Colors.blue,
                                //     foregroundColor: Colors.white,
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
