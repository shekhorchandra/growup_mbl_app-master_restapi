import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:growup_agro/views/web_view_page.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/project_certificate_model.dart';

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

  // Track download progress
  Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    _certificatesFuture = _loadTokenAndFetch();
  }

  Future<List<ProjectCertificate>> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token') ?? '';

    final list = await fetchCertificates();
    setState(() {
      _allCertificates = list;
      _filteredCertificates = list;
    });
    return list;
  }

  Future<List<ProjectCertificate>> fetchCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final investorCode = prefs.getString('investor_code') ?? '';

    if (investorCode.isEmpty || token.isEmpty) {
      throw Exception('Missing token or investor code.');
    }

    final url = Uri.parse(
      "https://growupagro.tech/api/investor/project-certificates?investor_code=$investorCode",
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
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
        final code = cert.code.toString().toLowerCase();
        final roi = cert.roi.toString().toLowerCase();
        final search = query.toLowerCase();
        return name.contains(search) ||
            code.contains(search) ||
            roi.contains(search);
      }).toList();
    });
  }


  Future<void> openCertificateInBrowser(
      String viewUrl,
      BuildContext context,
      ) async {
    if (viewUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('View URL not available')),
        );
      }
      return;
    }

    final Uri uri = Uri.parse(viewUrl);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link in browser')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open link in browser')),
        );
      }
    }
  }


  Future<void> downloadCertificateWithFallback(
    BuildContext context,
    String downloadUrl,
    String viewUrl,
    String fileName,
  ) async {
    setState(() => _isDownloading[downloadUrl] = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          followRedirects: true,
          validateStatus: (status) => true, // handle all status codes
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName.pdf';

      final response = await dio.getUri<List<int>>(
        Uri.parse(downloadUrl),
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final percent = (received / total * 100)
                .clamp(0, 100)
                .toStringAsFixed(0);
            debugPrint('Downloading $fileName: $percent%');
          }
        },
      );

      // Check content type before saving
      final contentType = response.headers.value('content-type') ?? '';
      if (!contentType.contains('application/pdf')) {
        final bodyText = utf8.decode(response.data ?? []);
        if (bodyText.contains('Unauthenticated') ||
            bodyText.contains('<html')) {
          throw Exception('Unauthenticated or invalid response from server');
        } else {
          throw Exception('Invalid response: expected PDF, got $contentType');
        }
      }

      if (response.statusCode != 200 ||
          response.data == null ||
          response.data!.isEmpty) {
        throw Exception(
          'Server error: ${response.statusCode}. Unable to download file.',
        );
      }

      // Save file locally
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(response.data!, flush: true);

      final savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: tempPath,
          fileName: '$fileName.pdf',
        ),
      );

      if (savedPath != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded successfully: $savedPath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        await OpenFilex.open(savedPath);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Save cancelled.')));
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');

      // Fallback: open viewUrl in WebView
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Direct download failed. Opening preview page.'),
            backgroundColor: Colors.orange,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PreviewPage(url: viewUrl)),
        );
      }
    } finally {
      setState(() => _isDownloading[downloadUrl] = false);
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
          // Search bar
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green),
                ),
              ),
            ),
          ),

          // Certificates list
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // View button
                                ElevatedButton.icon(
                                  onPressed: () => openCertificateInBrowser(item.viewUrl, context),
                                  icon: const Icon(Icons.remove_red_eye),
                                  label: const Text('View'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey[200],
                                    foregroundColor: Colors.black,
                                  ),
                                ),


                                const SizedBox(width: 12),

                                // Download button with fallback
                                ElevatedButton.icon(
                                  onPressed:
                                      _isDownloading[item.downloadUrl] == true
                                      ? null
                                      : () async {
                                          await downloadCertificateWithFallback(
                                            context,
                                            item.downloadUrl,
                                            item.viewUrl,
                                            item.name,
                                          );
                                        },
                                  icon: _isDownloading[item.downloadUrl] == true
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.download),
                                  label: Text(
                                    _isDownloading[item.downloadUrl] == true
                                        ? 'Downloading...'
                                        : 'Download',
                                  ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
