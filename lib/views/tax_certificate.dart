import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/invoice_action_buttons.dart'; // 👈 Your global button widget

class TaxCertificatePage extends StatefulWidget {
  const TaxCertificatePage({super.key});

  @override
  State<TaxCertificatePage> createState() => _TaxCertificatePageState();
}

class _TaxCertificatePageState extends State<TaxCertificatePage>
    with TickerProviderStateMixin {
  late Future<List<dynamic>> certificatesFuture;
  List<dynamic> _allCertificates = [];
  List<dynamic> _filteredCertificates = [];

  final Map<int, bool> _isExpanded = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _investorCode = '';

  @override
  void initState() {
    super.initState();
    _loadInvestorCode();
  }

  Future<void> _loadInvestorCode() async {
    final prefs = await SharedPreferences.getInstance();
    final investorCode = prefs.getString('investor_code') ?? '';
    setState(() {
      _investorCode = investorCode;
      certificatesFuture = fetchCertificates();
    });
  }

  Future<List<dynamic>> fetchCertificates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (_investorCode.isEmpty || token.isEmpty) {
        throw Exception('Missing token or investor code. Please log in again.');
      }

      final url = Uri.parse(
          'https://growupagro.tech/api/tax-certificates?investor_code=$_investorCode');

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
          final fiscalText =
          '${fiscal['start']} - ${fiscal['end']}'.toLowerCase();
          final projectNames =
          projects.map((p) => (p['name'] ?? '').toLowerCase()).join(' ');
          return fiscalText.contains(query.toLowerCase()) ||
              projectNames.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleExpand(int index) {
    setState(() {
      _isExpanded[index] = !(_isExpanded[index] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          cursorColor: Colors.white,
          onChanged: _filterCertificates,
          decoration: const InputDecoration(
            hintText: 'Search by fiscal year or project...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        )
            : const Text(
          'Tax Certificates',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
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

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _filteredCertificates.length,
            itemBuilder: (context, index) {
              final cert = _filteredCertificates[index];
              final fiscal = cert['fiscal_year'];
              final projects = cert['projects'] as List;
              final expanded = _isExpanded[index] ?? false;

              // Generate dynamic URLs
              final viewUrl =
                  'https://growupagro.tech/api/investor/tax-certificates/${fiscal['start']}?investor_code=$_investorCode';
              final downloadUrl =
                  'https://growupagro.tech/api/investor/tax-certificates/${fiscal['start']}/download?investor_code=$_investorCode';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Fiscal Year",
                              style: TextStyle(color: Colors.black54),
                            ),
                            Text(
                              '${fiscal['start']} - ${fiscal['end']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.green,
                          ),
                          onPressed: () => _toggleExpand(index),
                        ),
                      ],
                    ),

                    // Expandable section
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.linear,
                      alignment: Alignment.topCenter,
                      child: expanded
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(thickness: 1),
                          ...projects.map(
                                (proj) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6.0),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Project: ${proj['name']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Investment'),
                                      Text(
                                          '${proj['total_investment']} BDT'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('ROI'),
                                      Text('${proj['roi_amount']} BDT'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InvoiceActionButtons(
                            viewUrl: viewUrl,
                            downloadUrl: downloadUrl,
                            invoiceNo: fiscal['start'].toString(),
                            status: 'approved',
                          ),
                        ],
                      )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
