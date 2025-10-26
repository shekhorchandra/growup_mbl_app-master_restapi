import 'dart:async';
import 'package:flutter/material.dart';

class CompanyCertificationsCarousel extends StatefulWidget {
  const CompanyCertificationsCarousel({super.key});

  @override
  State<CompanyCertificationsCarousel> createState() =>
      _CompanyCertificationsCarouselState();
}

class _CompanyCertificationsCarouselState
    extends State<CompanyCertificationsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.96);
  int _currentPage = 0;
  late Timer _timer;

  final List<Map<String, dynamic>> _companies = [
    {
      'companyName': 'GrowUp Agrotech Limited',
      'logoIcon': Icons.grass,
      'certifications': [
        {'name': 'Certificate of Incorporation', 'number': 'C-195903'},
        {'name': 'DCCI Registration', 'number': 'ECNGRO202507001532'},
        {'name': 'BIDA Registration', 'number': 'L-202508060017189-H'},
        {'name': 'Trade License', 'number': 'TRAD/DNCC/006823'},
        {'name': 'D&B D-U-N-S', 'number': '77-411-5707'},
      ],
      'color': Colors.green,
    },
    {
      'companyName': 'Rural Organisations for Social Affairs (ROSA)',
      'logoIcon': Icons.business,
      'certifications': [
        {'name': 'Established in', 'number': '1992'},
        {'name': 'Reg No of (DSS)', 'number': 'DSS NAT-152'},
        {'name': 'MRA No', 'number': '017330010400726'},
        {'name': 'NGO Bureau No', 'number': '1091'},
        {'name': 'Received support from PKSF', 'number': ''},
      ],
      'color': Colors.blue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage =
            (_currentPage + 1) % _companies.length; // Loop back to first
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
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'COMPANY CERTIFICATIONS & AFFILIATIONS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
        ),
        SizedBox(
          width: screenWidth,
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _companies.length,
            itemBuilder: (context, index) {
              final company = _companies[index];
              return _buildCompanyCertificationCard(
                context,
                companyName: company['companyName'],
                logoIcon: company['logoIcon'],
                certifications: company['certifications'],
                color: company['color'].shade50,
                iconColor: company['color'].shade800,
              );
            },
          ),
        ),
        // const SizedBox(height: 10),
        // // --- Page indicator dots ---
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: List.generate(
        //     _companies.length,
        //         (index) => AnimatedContainer(
        //       duration: const Duration(milliseconds: 300),
        //       margin: const EdgeInsets.symmetric(horizontal: 4),
        //       height: 8,
        //       width: _currentPage == index ? 24 : 8,
        //       decoration: BoxDecoration(
        //         color: _currentPage == index
        //             ? _companies[index]['color']
        //             : Colors.grey.shade400,
        //         borderRadius: BorderRadius.circular(8),
        //       ),
        //     ),
        //   ),
        // ),
        // const SizedBox(height: 10),
      ],
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        width: screenWidth,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              children: [
                Icon(logoIcon, size: 22, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    companyName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 8, thickness: 0.6, color: Colors.grey.shade400),


            // --- Certifications ---
            ...certifications.map((cert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: iconColor.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${cert['name']}: ${cert['number']}",
                        style: const TextStyle(fontSize: 12, height: 1.3),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
