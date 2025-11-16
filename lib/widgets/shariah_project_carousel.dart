import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:growup_agro/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/assets.dart';
import '../models/live_project_model.dart';
import '../views/project_Descriotion_page.dart';

class ShariahProjectCarousel extends StatefulWidget {
  final List<LiveProject> projects;

  const ShariahProjectCarousel({super.key, required this.projects});

  @override
  State<ShariahProjectCarousel> createState() => _ShariahProjectCarouselState();
}

class _ShariahProjectCarouselState extends State<ShariahProjectCarousel> {
  int _currentIndex = 0;
  String? investorCode; // ✅ store investor code here

  @override
  void initState() {
    super.initState();
    _loadInvestorCode(); // ✅ load from shared preferences
  }

  Future<void> _loadInvestorCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('investor_code');
    setState(() {
      investorCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = widget.projects;

    if (projects.isEmpty) {
      return const Center(child: Text('No projects available.'));
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height *
          (MediaQuery.of(context).size.width >= 600 ? 0.25 : 0.25),
      child: CarouselSlider(
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height * 0.20,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          enlargeCenterPage: true,
          viewportFraction: 1.0,
          enableInfiniteScroll: true,
        ),
        items: projects.map((project) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(
                      color: Colors.green[700]!, // left border color
                      width: 5,          // left border thickness
                    ),
                  ),
                  borderRadius: const BorderRadius.all(
                   Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15), // soft shadow color
                      blurRadius: 8,       // how soft the shadow looks
                      spreadRadius: 1,     // how far it spreads
                      offset: const Offset(0, 3), // position (x, y)
                    ),
                  ],
                ),

                clipBehavior: Clip.antiAlias,
                child: _buildProjectCard(
                  context: context,
                  imageUrl: project.imageUrl ?? '',
                  projectId: project.id!,
                  name: project.projectName ?? 'N/A',
                  type: project.investmentType_name ?? "N/A",
                  goal: '${project.investmentGoal ?? '0'} Tk',
                  duration: project.project_duration_viewer ?? 'N/A',
                  minInvestment: '${project.min_investment_amount ?? '0'} Tk',
                  time: '${project.remaining_opportunity_days ?? 0} Days',
                  roi: '${project.annualRoi ?? 0}%',
                  isTablet: MediaQuery.of(context).size.width >= 600,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectCard({
    required BuildContext context,
    required String imageUrl,
    required int projectId,
    required String name,
    required String type,
    required String goal,
    required String duration,
    required String minInvestment,
    required String time,
    required String roi,
    required bool isTablet,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isTablet = screenWidth >= 600;
    final cardHeight = isTablet ? screenHeight * 0.48 : screenHeight * 0.18;
    final cardWidth = screenWidth * 0.97;

    final imageWidth = cardWidth * 0.4;
    final imageHeight = cardHeight * 0.95;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: imageWidth,
                  height: imageHeight,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, size: screenWidth * 0.06),
                ),
              ),
            ),
          ),

          // Right: Info + Button
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.018,
                    horizontal: screenWidth * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet
                                ? screenWidth * 0.022
                                : screenWidth * 0.036,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      ...[
                        _infoRow(label: 'Type:', value: type),
                        _infoRow(label: 'Goal:', value: goal),
                        _infoRow(label: 'Duration:', value: duration + ' Month'),
                        _infoRow(label: 'Min Invest:', value: minInvestment),
                        _infoRow(label: 'Time:', value: time),
                      ],
                      SizedBox(height: screenHeight * 0.01),
                      /*SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Invest Now",
                          height: 32,
                          backgroundColor: Colors.green,
                          isRound: false,
                          onPressed: () {
                            if (investorCode == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Investor not logged in!',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectDescriptionPage(
                                  projectId: projectId,
                                  investorCode: investorCode!,
                                ),
                              ),
                            );
                          },
                        ),
                      ),*/
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.004,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          Assets.iconsEarning,
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ROI $roi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet
                                ? screenWidth * 0.020
                                : screenWidth * 0.022,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // helper for info rows
  Widget _infoRow({
    required String label,
    required String value,
    double fontSize = 12,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey, fontSize: fontSize),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
