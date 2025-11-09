import 'package:flutter/material.dart';

class CategoryItem {
  final Widget icon;
  final String title;
  final Color itemBgColor;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isLive; // ✅ New flag for live badge

  const CategoryItem({
    required this.icon,
    required this.title,
    this.itemBgColor = Colors.white,
    this.textColor = const Color(0xFF555555),
    this.onTap,
    this.isLive = false, // ✅ default false
  });
}

class CategoryGridCard extends StatelessWidget {
  const CategoryGridCard({
    super.key,
    required this.items,
    this.iconColor = const Color(0xFF2E7D32),
    this.bgColor = Colors.white,
    this.minCrossAxisCount = 3,
    this.maxCrossAxisCount = 4,
    this.titleFontSize = 10,
    this.aspectRatio,
  });

  final List<CategoryItem> items;
  final Color iconColor;
  final Color bgColor;
  final int minCrossAxisCount;
  final int maxCrossAxisCount;
  final double titleFontSize;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final crossAxisCount = c.maxWidth < 520 ? minCrossAxisCount : maxCrossAxisCount;

        final childAspectRatio = aspectRatio ??
            (c.maxWidth < 400
                ? 1.1
                : c.maxWidth < 520
                ? 1.25
                : 1.35);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) => _buildCard(context, items[index]),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, CategoryItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: item.onTap,
      child: Stack(
        children: [
          // 🟩 Main card container
          Container(
            decoration: BoxDecoration(
              color: item.itemBgColor,
              border: Border(
                left: BorderSide(
                  color: Colors.green[700]!,
                  width: 3,
                ),
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 6,
                  child: IconTheme(
                    data: IconThemeData(size: 50, color: iconColor),
                    child: Center(child: _wrapIcon(item.icon, 50)),
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  flex: 4,
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: item.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔴 “LIVE” badge overlay
          if (item.isLive)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _wrapIcon(Widget icon, double size) {
    if (icon is Icon) {
      return Icon(icon.icon, size: size);
    }
    return SizedBox(height: size, width: size, child: FittedBox(child: icon));
  }
}
