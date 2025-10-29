import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class HomeImageSlider extends StatefulWidget {
  const HomeImageSlider({
    super.key,
    required this.imageUrls,
    this.height = 170,
    this.borderRadius = 12,
    this.leftOverlayAsset, // e.g. 'assets/icons/plant_coins.png'
  });

  final List<String> imageUrls;
  final double height;
  final double borderRadius;
  final String? leftOverlayAsset;

  @override
  State<HomeImageSlider> createState() => _HomeImageSliderState();
}

class _HomeImageSliderState extends State<HomeImageSlider> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final br = Radius.circular(widget.borderRadius);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card with rounded corners & subtle shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(br),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Image slider (clipped to rounded)
                SizedBox(
                  height: widget.height,
                  width: double.infinity,
                  child: CarouselSlider.builder(
                    options: CarouselOptions(
                      height: widget.height,
                      autoPlay: true,
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      onPageChanged: (i, _) => setState(() => _current = i),
                    ),
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (context, index, realIdx) {
                      final url = widget.imageUrls[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.all(br),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (c, child, prog) =>
                          prog == null ? child : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (c, e, s) => const Center(
                            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Indicator bar (separate white strip with pill + dots)
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.imageUrls.length, (i) {
                  final bool isActive = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: isActive ? 34 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF1E6A4A) : const Color(0xFF8ED18F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
