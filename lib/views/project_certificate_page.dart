import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:growup_agro/models/project_certificate_model.dart';
import 'package:growup_agro/views/pdf_view_page.dart';
import 'package:growup_agro/widgets/info_row.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/invoice_utils.dart';
import '../views/web_view_page.dart';
import '../widgets/invoice_action_buttons.dart';
import '../widgets/custom_button.dart';

class ProjectCertificatesPage extends StatefulWidget {
  const ProjectCertificatesPage({super.key});

  @override
  State<ProjectCertificatesPage> createState() => _ProjectCertificatesPageState();
}

class _ProjectCertificatesPageState extends State<ProjectCertificatesPage> {
  late Future<List<ProjectCertificate>> _certificatesFuture;
  List<ProjectCertificate> _allCertificates = [];
  List<ProjectCertificate> _filteredCertificates = [];
  Map<String, bool> _isDownloading = {};

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _certificatesFuture = fetchCertificates();
  }

  Future<List<ProjectCertificate>> fetchCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
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
        final list = (jsonResponse['data'] as List)
            .map((e) => ProjectCertificate.fromJson(e))
            .toList();
        setState(() {
          _allCertificates = list;
          _filteredCertificates = list;
        });
        return list;
      } else {
        throw Exception('No certificates found.');
      }
    } else {
      throw Exception('Failed to load certificates.');
    }
  }

  void _filterCertificates(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCertificates = _allCertificates;
      } else {
        final lower = query.toLowerCase();
        _filteredCertificates = _allCertificates.where((cert) {
          return cert.name.toLowerCase().contains(lower) ||
              cert.code.toLowerCase().contains(lower) ||
              cert.roi.toString().toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  Future<void> openCertificateInApp(BuildContext context, String? viewUrl) async {
    if (viewUrl == null || viewUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('View URL not available')),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFViewPage(
            url: viewUrl,
            title: 'Certificate Preview',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _filterCertificates,
          decoration: const InputDecoration(
            hintText: 'Search by project name, code, or ROI...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        )
            : const Text(
          'Project Certificates',
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filterCertificates('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ProjectCertificate>>(
        future: _certificatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (_filteredCertificates.isEmpty) {
            return const Center(child: Text('No matching certificates.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _filteredCertificates.length,
            itemBuilder: (context, index) {
              final item = _filteredCertificates[index];

              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // ensures text aligns nicely
                          children: [
                            // 🟢 Left side: item name (can wrap into 2 lines)
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 2, // allow up to 2 lines
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // ⚫ Right side: code text (fixed)
                            Text(
                              "Code: ${item.code}",
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        // Project Info Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Ends: ${item.endDate}",
                                style: const TextStyle(color: Colors.black87)),
                            Text("ROI: ${item.roi}%",
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        //Your Custom Button (full width)
                        InvoiceActionButtons(
                          invoiceNo: item.code,
                          downloadUrl:
                          item.downloadUrl,
                          viewUrl:
                          item.downloadUrl,
                          status: "approved",
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


