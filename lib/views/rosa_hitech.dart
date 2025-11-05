import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:growup_agro/widgets/custom_button.dart';

class RosahitechCityPage extends StatefulWidget {
  const RosahitechCityPage({super.key});

  @override
  State<RosahitechCityPage> createState() => _RosahitechCityPageState();
}

class _RosahitechCityPageState extends State<RosahitechCityPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  // 🔹 Static dummy data
  final List<Map<String, String>> _properties = [
    {
      "title": "ROSA Residence Tower A",
      "location": "ROSA Hi-Tech City",
      "image":
          "https://growupagro.tech/storage/uploads/property/packages/68d98670d9d1f.jpeg",
      "beds": "15",
      "baths": "10",
      "size": "12000 sqft",
    },
    {
      "title": "ROSA Residence Tower B",
      "location": "ROSA Hi-Tech City",
      "image":
          "https://growupagro.tech/storage/uploads/property/packages/68d98688f1570.jpeg",
      "beds": "10",
      "baths": "6",
      "size": "8000 sqft",
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset >= 300 && !_showBackToTopButton) {
        setState(() => _showBackToTopButton = true);
      } else if (_scrollController.offset < 300 && _showBackToTopButton) {
        setState(() => _showBackToTopButton = false);
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Responsive grid
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth >= 600) crossAxisCount = 3;
    if (screenWidth >= 900) crossAxisCount = 4;
    if (screenWidth >= 1200) crossAxisCount = 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ROSA Hi-Tech City",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _properties.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, index) {
          final property = _properties[index];
          return _buildPropertyCard(property);
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

  // 🔹 Property Card (matches AllPropertiesPage layout)
  Widget _buildPropertyCard(Map<String, String> property) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 5,
            child: SizedBox.expand(
              child: Image.network(
                property["image"]!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          // Details
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title & Location
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property["title"]!,
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
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey.shade600,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property["location"]!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(FontAwesomeIcons.building, property["beds"]!),
                      _buildStat(FontAwesomeIcons.restroom, property["baths"]!),
                      _buildStat(
                        FontAwesomeIcons.rulerCombined,
                        property["size"]!,
                      ),
                    ],
                  ),

                  // Full-width CustomButton
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: "Coming Soon...",
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Coming soon: Property details page"),
                          ),
                        );
                      },
                      backgroundColor: const Color(0xFF2E7D32),
                      height: 28,
                      fontSize: 12,
                      borderRadius: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Small icon + text utility
  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}
