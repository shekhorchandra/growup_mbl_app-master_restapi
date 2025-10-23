import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/project_certificate_model.dart';
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

  void _checkCertificates() async {
    final certificates = await fetchCertificates();
    for (var cert in certificates) {
      print('Preview URL: ${cert.previewUrl}');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadToken();
    _checkCertificates(); // Call it here to debug URLs
  }


  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token') ?? '';
    });
  }

  Future<List<ProjectCertificate>> fetchCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final investorCode = prefs.getString('investor_code') ?? '';
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
        final certificates = (jsonResponse['data'] as List)
            .map((e) => ProjectCertificate.fromJson(e))
            .toList();

        // --- DEBUGGING: check URLs ---
        for (var cert in certificates) {
          print('Preview URL: ${cert.previewUrl}');
          print('View URL: ${cert.viewUrl}');
          print('Download URL: ${cert.downloadUrl}');
        }

        return certificates;
      } else {
        throw Exception('Failed to load certificates');
      }
    } else {
      throw Exception('Failed to load certificates');
    }
  }


  void _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch $url';
    }
  }

  Future<Uint8List> _fetchImageBytes(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  }

  // Widget _buildPreviewImage(String url) {
  //   return FutureBuilder<Uint8List>(
  //     future: _fetchImageBytes(url),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const SizedBox(
  //             height: 200,
  //             child: Center(child: CircularProgressIndicator()));
  //       } else if (snapshot.hasError || snapshot.data == null) {
  //         return const SizedBox(
  //             height: 200,
  //             child: Center(child: Icon(Icons.broken_image, size: 50)));
  //       }
  //       return ClipRRect(
  //         borderRadius: BorderRadius.circular(8),
  //         child: Image.memory(
  //           snapshot.data!,
  //           height: 200,
  //           width: double.infinity,
  //           fit: BoxFit.cover,
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Certificates'),
      ),
      body: FutureBuilder<List<ProjectCertificate>>(
        future: fetchCertificates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No certificates found'));
          }

          final data = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview image
                      // if (item.previewUrl.isNotEmpty)
                      //   _buildPreviewImage(item.previewUrl),
                      const SizedBox(height: 12),
                      Text(
                        item.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("Code: ${item.code}"),
                      Text("ROI: ${item.roi}%"),
                      Text("Ends: ${item.endDate}"),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // ElevatedButton.icon(
                          //   onPressed: () {
                          //     _launchURL(item.viewUrl);
                          //   },
                          //   icon: const Icon(Icons.remove_red_eye),
                          //   label: const Text('View'),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.grey[700],
                          //   ),
                          // ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              _launchURL(item.downloadUrl);
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // button background
                              foregroundColor: Colors.white, // icon & text color
                            ),
                          )

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
    );
  }
}


