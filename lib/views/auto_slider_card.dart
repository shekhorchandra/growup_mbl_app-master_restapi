// import 'package:flutter/material.dart';
//
// class CompanyCertificationsCarousel extends StatefulWidget {
//   const CompanyCertificationsCarousel({super.key});
//
//   @override
//   State<CompanyCertificationsCarousel> createState() =>
//       _CompanyCertificationsCarouselState();
// }
//
// class _CompanyCertificationsCarouselState
//     extends State<CompanyCertificationsCarousel> {
//   final PageController _pageController = PageController(viewportFraction: 0.96);
//   int _currentPage = 0;
//
//   final List<Map<String, dynamic>> _companies = [
//     {
//       'companyName': 'GrowUp Agrotech Limited',
//       'logoIcon': Icons.grass,
//       'certifications': [
//         {'name': 'Certificate of Incorporation', 'number': 'C-195903'},
//         {'name': 'DCCI Registration', 'number': 'ECNGRO202507001532'},
//         {'name': 'BIDA Registration', 'number': 'L-202508060017189-H'},
//         {'name': 'Trade License', 'number': 'TRAD/DNCC/006823'},
//         {'name': 'D&B D-U-N-S', 'number': '77-411-5707'},
//       ],
//       'color': Colors.green,
//     },
//     {
//       'companyName': 'Rural Organisations for Social Affairs (ROSA)',
//       'logoIcon': Icons.business,
//       'certifications': [
//         {'name': 'Established in', 'number': '1992'},
//         {'name': 'Reg No of (DSS)', 'number': 'DSS NAT-152'},
//         {'name': 'MRA No', 'number': '017330010400726'},
//         {'name': 'NGO Bureau No', 'number': '1091'},
//         {'name': 'Received support from PKSF', 'number': ''},
//       ],
//       'color': Colors.blue,
//     },
//   ];
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
//           child: Text(
//             'COMPANY CERTIFICATIONS & AFFILIATIONS',
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF2E7D32),
//             ),
//           ),
//         ),
//
//         // ✅ Card Carousel (Manual swipe only)
//         SizedBox(
//           width: screenWidth,
//           height: 180,
//           child: PageView.builder(
//             controller: _pageController,
//             onPageChanged: (index) => setState(() => _currentPage = index),
//             itemCount: _companies.length,
//             itemBuilder: (context, index) {
//               final company = _companies[index];
//               final MaterialColor base = company['color'] as MaterialColor;
//               return _buildCompanyCertificationCard(
//                 context,
//                 companyName: company['companyName'] as String,
//                 logoIcon: company['logoIcon'] as IconData,
//                 certifications:
//                 (company['certifications'] as List).cast<Map<String, dynamic>>(),
//                 color: base.shade50,
//                 iconColor: base.shade800,
//                 isActive: index == _currentPage,
//                 totalCards: _companies.length,
//                 currentIndex: _currentPage,
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCompanyCertificationCard(
//       BuildContext context, {
//         required String companyName,
//         required IconData logoIcon,
//         required List<Map<String, dynamic>> certifications,
//         required Color color,
//         required Color iconColor,
//         required bool isActive,
//         required int totalCards,
//         required int currentIndex,
//       }) {
//     return Stack(
//       children: [
//         // Card container
//         Container(
//           margin: EdgeInsets.symmetric(horizontal: 4),
//           padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 16),
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(12),
//
//             border: Border.all(color: Colors.grey.shade300, width: 0.8),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 12), // leave space for indicator row
//               Row(
//                 children: [
//                   Icon(logoIcon, size: 22, color: iconColor),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       companyName,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: iconColor,
//                         height: 1.15,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Divider(height: 8, thickness: 0.6, color: Colors.grey.shade400),
//
//               // --- Scrollable certifications list ---
//               Expanded(
//                 child: SingleChildScrollView(
//                   physics: const BouncingScrollPhysics(),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: certifications.map((cert) {
//                       final name = cert['name']?.toString() ?? '';
//                       final number = cert['number']?.toString() ?? '';
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 4.0),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Icon(Icons.check_circle_outline,
//                                 size: 14, color: iconColor.withValues(alpha: 0.8)),
//                             const SizedBox(width: 6),
//                             Expanded(
//                               child: Text(
//                                 number.isEmpty ? name : "$name: $number",
//                                 style: const TextStyle(fontSize: 12, height: 1.3),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         // ✅ Indicator positioned on top INSIDE the card
//         Positioned(
//           top: 165,
//           left: 0,
//           right: 0,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(totalCards, (i) {
//               final bool active = i == currentIndex;
//               return AnimatedContainer(
//                 duration: const Duration(milliseconds: 250),
//                 margin: const EdgeInsets.symmetric(horizontal: 4),
//                 width: active ? 22 : 8,
//                 height: 6,
//                 decoration: BoxDecoration(
//                   color: active ? iconColor : Colors.grey.shade400,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               );
//             }),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';

class CertificationsSection extends StatelessWidget {
  const CertificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Company Certifications & Affiliations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          // --- Vertical Full-Width Cards ---
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
          const SizedBox(height: 10),
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
      width: double.infinity, // ensures full width
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
                ),
              ),
            ],
          ),
          const Divider(height: 12, thickness: 0.5),

          // Certifications List
          ...certifications.map((cert) {
            final bool isStructured = cert is Map<String, String>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: iconColor.withValues(alpha: 0.7)),
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
                        cert['number']!,
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
