import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../models/all_properties.model.dart';

class PropertyCarousel extends StatefulWidget {
  const PropertyCarousel({
    super.key,
    required this.displayPackages,
  });

  final List<PropertyPackage> displayPackages; // use your proper model if you want

  @override
  State<PropertyCarousel> createState() => _PropertyCarouselState();
}

class _PropertyCarouselState extends State<PropertyCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBEF), // light green bg like screenshot
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarouselSlider(
            options: CarouselOptions(
              // height equals card height
              height: isTablet ? 320 : 300,

              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),

              // two cards in view (space for inner padding)
              viewportFraction: 0.48,

              // equal sized cards (no zoom)
              enlargeCenterPage: false,

              enableInfiniteScroll: true,
              pageSnapping: true,
              padEnds: true,

              onPageChanged: (i, _) => setState(() => _current = i),
            ),
            items: widget.displayPackages.map((pkg) {
              return Builder(
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: _PropertyCard(
                      imageUrl: "https://growupagro.tech${pkg.imageUrl}",
                      title: "${pkg.propertyName}\n${pkg.packageName}",
                      onSeeDetails: () {
                        // TODO: navigate to details
                      },
                      onOrderNow: () {
                        // TODO: order now action
                      },
                    ),
                  );
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          _BulgedDotsIndicator(
            count: widget.displayPackages.length,
            current: _current,
            activeColor: const Color(0xFF2E7D32),
            color: const Color(0xFF8BC34A),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.imageUrl,
    required this.title,
    required this.onSeeDetails,
    required this.onOrderNow,
  });

  final String imageUrl;
  final String title;
  final VoidCallback onSeeDetails;
  final VoidCallback onOrderNow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // image
            AspectRatio(
              aspectRatio: 16 / 10,
              child: imageUrl.isEmpty
                  ? Container(color: const Color(0xFFECEFF1))
                  : Image.network(imageUrl, fit: BoxFit.cover),
            ),

            // title
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),

            const Spacer(),

            // buttons with rounded pills and white notch between
            SizedBox(
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          text: 'See Details',
                          background: const Color(0xFF2E7D32),
                          onTap: onSeeDetails,
                          roundLeft: true,
                          roundRight: false,
                        ),
                      ),
                      Expanded(
                        child: _PillButton(
                          text: 'Order Now',
                          background: const Color(0xFFFFA24C),
                          onTap: onOrderNow,
                          roundLeft: false,
                          roundRight: true,
                        ),
                      ),
                    ],
                  ),
                  // white notch
                  Positioned(
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.text,
    required this.background,
    required this.onTap,
    required this.roundLeft,
    required this.roundRight,
  });

  final String text;
  final Color background;
  final VoidCallback onTap;
  final bool roundLeft;
  final bool roundRight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Ink(
        height: 42,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.horizontal(
            left: roundLeft ? const Radius.circular(14) : Radius.zero,
            right: roundRight ? const Radius.circular(14) : Radius.zero,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// pill-style active + round dots indicator like the screenshot
class _BulgedDotsIndicator extends StatelessWidget {
  const _BulgedDotsIndicator({
    required this.count,
    required this.current,
    this.activeColor = Colors.green,
    this.color = Colors.grey,
  });

  final int count;
  final int current;
  final Color activeColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool isActive = i == current;
        final Size size = isActive ? const Size(46, 12) : const Size(12, 12);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: isActive ? activeColor : color.withValues(alpha: .75),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
