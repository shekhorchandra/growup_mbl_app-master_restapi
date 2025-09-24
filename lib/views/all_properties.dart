import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  Future<AllPropertiesResponse> fetchProperties() async {
    final response = await http.get(
      Uri.parse("https://admin-growup.onebitstore.site/api/properties"),
    );

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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7, // more responsive aspect ratio
            ),
            itemBuilder: (context, index) {
              final package = propertyPackages[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          "https://admin-growup.onebitstore.site${package.imageUrl}",
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported,
                                    size: 40),
                              ),
                        ),
                      ),
                    ),

                    // Info
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              package.propertyName,
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              package.packageName,
                              style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Button flush bottom
                    SizedBox(
                      height: screenHeight * 0.05,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'See Details',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035),
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
}
