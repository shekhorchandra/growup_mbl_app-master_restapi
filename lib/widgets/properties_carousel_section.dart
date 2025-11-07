import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/all_properties.model.dart';

class PropertiesCarouselSection extends StatefulWidget {
  final List<PropertyPackage> propertyPackages;

  const PropertiesCarouselSection({
    super.key,
    required this.propertyPackages,
  });

  @override
  State<PropertiesCarouselSection> createState() => _PropertiesCarouselSectionState();
}

class _PropertiesCarouselSectionState extends State<PropertiesCarouselSection> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final propertyPackages = widget.propertyPackages;

    if (propertyPackages.isEmpty) {
      return const Center(child: Text("No properties found"));
    }

    final double carouselHeight = MediaQuery.of(context).size.height * 0.30;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarouselSlider.builder(
          itemCount: propertyPackages.length,
          options: CarouselOptions(
            height: carouselHeight,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            viewportFraction: 0.60,
            enlargeCenterPage: false,
            enableInfiniteScroll: true,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemBuilder: (context, index, realIdx) {
            final package = propertyPackages[index];
            final imageUrl = "https://growupagro.tech${package.imageUrl}";

            return Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: _buildPropertyCard(
                imageUrl: imageUrl,
                propertyName: package.propertyName,
                packageName: package.packageName,
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: propertyPackages.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentIndex == entry.key ? 18 : 6,
              decoration: BoxDecoration(
                color: _currentIndex == entry.key
                    ? Colors.green
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPropertyCard({
    required String imageUrl,
    required String propertyName,
    required String packageName,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 12,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$propertyName, $packageName",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            text: "See Details",
                            color: Colors.green,
                            topLeft: 0,
                            topRight: 12,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coming soon...'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            text: "Order Now",
                            color: Colors.orange,
                            topLeft: 12,
                            topRight: 0,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coming soon...'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required double topLeft,
    required double topRight,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(topLeft),
              topRight: Radius.circular(topRight),
            ),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
