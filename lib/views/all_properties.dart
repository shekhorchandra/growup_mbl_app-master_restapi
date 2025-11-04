import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/all_properties.model.dart';

class AllPropertiesPage extends StatefulWidget {
  const AllPropertiesPage({super.key});

  @override
  State<AllPropertiesPage> createState() => _AllPropertiesPageState();
}

class _AllPropertiesPageState extends State<AllPropertiesPage> {
  late Future<AllPropertiesResponse> _futureProperties;

  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _futureProperties = fetchProperties();

    _scrollController.addListener(() {
      if (_scrollController.offset >= 300 && !_showBackToTopButton) {
        setState(() => _showBackToTopButton = true);
      } else if (_scrollController.offset < 300 && _showBackToTopButton) {
        setState(() => _showBackToTopButton = false);
      }
    });
  }

  // Future<AllPropertiesResponse> fetchProperties() async {
  //   final response = await http.get(
  //     Uri.parse("https://growupagro.tech/api/properties"),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return AllPropertiesResponse.fromJson(jsonDecode(response.body));
  //   } else {
  //     throw Exception("Failed to load properties");
  //   }
  // }

  Future<AllPropertiesResponse> fetchProperties() async {
    final response = await http.get(Uri.parse(ApiConstants.allProperties));

    if (response.statusCode == 200) {
      return AllPropertiesResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load properties");
    }
  }


  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine crossAxisCount based on screen width
    int crossAxisCount = 2; // default for phones
    if (screenWidth >= 600) crossAxisCount = 3; // tablets
    if (screenWidth >= 900) crossAxisCount = 4; // large tablets / small desktops
    if (screenWidth >= 1200) crossAxisCount = 5; // large desktops

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "All Properties List",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<AllPropertiesResponse>(
        future: _futureProperties,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData ||
              snapshot.data!.propertyPackages.isEmpty) {
            return const Center(child: Text("No properties found"));
          }

          final propertyPackages = snapshot.data!.propertyPackages;

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: propertyPackages.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.65, // more responsive aspect ratio
            ),
            itemBuilder: (context, index) {
              final package = propertyPackages[index];

              return Card(
                elevation: 3.0, // Softer shadow
                margin: EdgeInsets.zero, // GridView handles spacing
                clipBehavior: Clip.antiAlias, // Ensures content respects the card's shape
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with Price Banner Overlay
                    Expanded(
                      flex: 6, // Give more space to the image
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image.network(
                          //   "https://growupagro.tech${package.imageUrl}",
                          //   fit: BoxFit.cover,
                          //   errorBuilder: (context, error, stack) => Container(
                          //     color: Colors.grey.shade200,
                          //     child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 40),
                          //   ),
                          // ),
                          Image.network(
                            ApiConstants.getPackageImage(package.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 40),
                            ),
                          ),

                          // Price Banner
                          // Positioned(
                          //   bottom: 10,
                          //   left: 10,
                          //   child: Container(
                          //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          //     decoration: BoxDecoration(
                          //       color: Colors.black.withValues(alpha: 0.6),
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //     child: Text(
                          //       '৳ 0', // Assuming you have a price field
                          //       style: const TextStyle(
                          //         color: Colors.white,
                          //         fontSize: 14,
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),

                    // Content Area
                    Expanded(
                      flex: 5, // Give slightly less space to content
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title and Subtitle
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  package.packageName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, color: Colors.grey.shade600, size: 12),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        package.propertyName,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Key Stats with Icons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStat(FontAwesomeIcons.bed, "3"), // Placeholder data
                                _buildStat(FontAwesomeIcons.bath, "2"), // Placeholder data
                                _buildStat(FontAwesomeIcons.rulerCombined, "1200 sqft"), // Placeholder data
                              ],
                            ),

                            // Details Button
                            SizedBox(
                              width: double.infinity,
                              height: 25,
                              child: FilledButton(
                                onPressed: () { /* Navigate to details */ },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Coming Soon...',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      )
          : null,
    );


  }
  // Helper widget for building the stat icons
  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
      ],
    );
  }
}
