import 'dart:async';
import 'package:flutter/material.dart';

class CertificationsSection extends StatefulWidget {
  const CertificationsSection({super.key});

  @override
  State<CertificationsSection> createState() => _CertificationsSectionState();
}

class _CertificationsSectionState extends State<CertificationsSection> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % 2; // total pages = 2
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: const Text(
              'Company Certifications & Affiliations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),

          // --- Auto Sliding PageView ---
          SizedBox(
            height: 140,
            width: double.infinity,
            child: PageView(
              controller: _pageController,
              children: [
                _buildCompanyCertificationCard(
                  context,
                  companyName: 'GrowUp Agrotech Limited',
                  logoIcon: Icons.grass,
                  certifications: const [
                    {'name': 'Certificate of Incorporation', 'number': 'C-195903'},
                    {'name': 'DCCI Registration', 'number': 'ECNGRO202507001532'},
                    {'name': 'BIDA Registration', 'number': 'L-202508060017189-H'},
                    {'name': 'Trade License', 'number': 'TRAD/DNCC/006823'},
                    {'name': 'D&B D-U-N-S', 'number': '77-411-5707'},
                  ],
                  color: Colors.green.shade50,
                  iconColor: Colors.green.shade800,
                ),
                _buildCompanyCertificationCard(
                  context,
                  companyName: 'Rural Organisations for Social Affairs (ROSA)',
                  logoIcon: Icons.business,
                  certifications: const [
                    {'name': 'Established in', 'number': '1992'},
                    {'name': 'Reg No of (DSS)', 'number': 'DSS NAT-152'},
                    {'name': 'MRA No', 'number': '017330010400726'},
                    {'name': 'NGO Bureau No', 'number': '1091'},
                    {'name': 'Received financial support from PKSF', 'number': ''},
                  ],
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue.shade800,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCertificationCard(
      BuildContext context, {
        required String companyName,
        required IconData logoIcon,
        required List<dynamic> certifications,
        required Color color,
        required Color iconColor,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(logoIcon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 12, thickness: 0.5),

          // Certifications list
          ...certifications.map((cert) {
            final bool isStructured = cert is Map<String, String>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: iconColor.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  if (isStructured) ...[
                    Text(
                      '${cert['name']}:',
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cert['number'] ?? '',
                        style: const TextStyle(fontSize: 10, height: 1.2, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        cert.toString(),
                        style: const TextStyle(fontSize: 10, height: 1.2),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
