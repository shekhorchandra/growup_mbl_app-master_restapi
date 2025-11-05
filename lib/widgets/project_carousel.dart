import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // your local lib path if different

class ProjectCarousel extends StatefulWidget {
  const ProjectCarousel({super.key, required this.projects});
  final List<dynamic> projects; // keep your model type here

  @override
  State<ProjectCarousel> createState() => _ProjectCarouselState();
}

class _ProjectCarouselState extends State<ProjectCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height * (isTablet ? 0.24 : 0.22),
            viewportFraction: 0.92,                 // show a bit of next card
            padEnds: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 650),
            autoPlayCurve: Curves.easeInOut,
            enableInfiniteScroll: true,
            pageSnapping: true,
            enlargeCenterPage: true,
            enlargeStrategy: CenterPageEnlargeStrategy.height,
            enlargeFactor: 0.18,                   // subtle pop
            onPageChanged: (i, _) => setState(() => _current = i),
          ),
          items: widget.projects.map((p) {
            return Builder(
              builder: (context) {
                return _ProjectCard(
                  imageUrl: p.imageUrl ?? '',
                  name: p.projectName ?? 'N/A',
                  type: p.investmentType_name ?? 'N/A',
                  goal: '${p.investmentGoal ?? '0'} Tk',
                  duration: p.project_duration_viewer ?? 'N/A',
                  minInvestment: '${p.min_investment_amount ?? '0'} tk',
                  time: '${p.remaining_opportunity_days ?? 0} Days',
                  roi: '${p.annualRoi ?? 0}%',
                  onInvestNow: () {
                    // TODO: navigate or open details
                  },
                );
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        _DotsIndicator(
          count: widget.projects.length,
          current: _current,
          activeDotIsPill: true, // first item in your mock looks like a pill
          activeSize: const Size(46, 12),
          dotSize: 10,
          activeColor: const Color(0xFF2E7D32),
          color: const Color(0xFF8BC34A),
          spacing: 10,
        ),
      ],
    );
  }
}

/// The card that matches your screenshot.
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.imageUrl,
    required this.name,
    required this.type,
    required this.goal,
    required this.duration,
    required this.minInvestment,
    required this.time,
    required this.roi,
    required this.onInvestNow,
  });

  final String imageUrl;
  final String name;
  final String type;
  final String goal;
  final String duration;
  final String minInvestment;
  final String time;
  final String roi;
  final VoidCallback onInvestNow;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Stack(
        children: [
          // Card body
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, 6),
                  color: Color(0x14000000),
                )
              ],
              border: Border.all(color: const Color(0xFFE7F3EA), width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1, // square like your mock
                    child: imageUrl.isEmpty
                        ? Container(color: const Color(0xFFECEFF1))
                        : Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                ),

                // details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // title
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isWide ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 6),

                        _kv('Type:', type),
                        _kv('Investment Goal:', goal),
                        _kv('Duration:', duration),
                        _kv('Min. Investment:', minInvestment),
                        _kv('Investment Time:', time),
                      ],
                    ),
                  ),
                ),

                // vertical "Invest Now"
                _InvestNowVertical(onTap: onInvestNow),
              ],
            ),
          ),

          // top-right ROI badge
          Positioned(
            right: 56, // keep clear of the vertical pill
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA24C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.show_chart, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'ROI $roi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          text: '$k ',
          style: const TextStyle(
            color: Color(0xFF7A7A7A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(
              text: v,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical green pill with rotated text "Invest Now"
class _InvestNowVertical extends StatelessWidget {
  const _InvestNowVertical({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
          width: 56,
          height: double.infinity,
          color: const Color(0xFF2E7D32),
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: const Text(
                'Invest Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean dots like your mock (first one can be a rounded pill)
class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.current,
    this.activeDotIsPill = false,
    this.activeSize = const Size(30, 10),
    this.dotSize = 8,
    this.spacing = 8,
    this.activeColor = Colors.green,
    this.color = Colors.grey,
  });

  final int count;
  final int current;
  final bool activeDotIsPill;
  final Size activeSize;
  final double dotSize;
  final double spacing;
  final Color activeColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool isActive = i == current;
        final Size size = isActive && activeDotIsPill
            ? activeSize
            : Size.square(dotSize);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: isActive ? activeColor : color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
