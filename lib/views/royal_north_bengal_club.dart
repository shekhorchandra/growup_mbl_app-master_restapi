import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NorthCityPage extends StatefulWidget {
  const NorthCityPage({super.key});

  @override
  State<NorthCityPage> createState() => _NorthCityPageState();
}

class _NorthCityPageState extends State<NorthCityPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  // Dummy static data
  final List<Map<String, String>> _properties = [

    {
      "title": "The Royal North-Bengal Club",
      "location": "The Royal Eco City",
      "image": "https://growupagro.tech/storage/uploads/property/packages/68d986bea84f9.jpeg",
      "beds": "8",
      "baths": "4",
      "size": "5000 sqft",
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth >= 600) crossAxisCount = 3;
    if (screenWidth >= 900) crossAxisCount = 4;
    if (screenWidth >= 1200) crossAxisCount = 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Royal North Bengal Club",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _properties.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.65,
        ),
        itemBuilder: (context, index) {
          final property = _properties[index];

          return Card(
            elevation: 3,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 6,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        property["image"]!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey.shade400, size: 40),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                                Icon(Icons.location_on_outlined,
                                    color: Colors.grey.shade600, size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    property["location"]!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStat(
                                FontAwesomeIcons.building, property["beds"]!),
                            _buildStat(
                                FontAwesomeIcons.restroom, property["baths"]!),
                            _buildStat(FontAwesomeIcons.rulerCombined,
                                property["size"]!),
                          ],
                        ),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          height: 25,
                          child: FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Coming Soon...',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
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

  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
        ),
      ],
    );
  }
}
