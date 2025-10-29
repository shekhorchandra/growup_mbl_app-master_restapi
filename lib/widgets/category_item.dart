import 'package:flutter/material.dart';

class CategoryItem {
  final Widget icon;
  final String title;
  final VoidCallback? onTap;

  const CategoryItem({
    required this.icon,
    required this.title,
    this.onTap,
  });
}

class CategoryGridCard extends StatelessWidget {
  const CategoryGridCard({
    super.key,
    required this.items,
    this.iconColor = const Color(0xFF2E7D32),
    this.textColor = const Color(0xFF555555),
    this.bgColor = Colors.white,
    this.minCrossAxisCount = 3,
    this.maxCrossAxisCount = 4,
    this.titleFontSize = 10,
  });

  final List<CategoryItem> items;
  final Color iconColor;
  final Color textColor;
  final Color bgColor;
  final int minCrossAxisCount; // used on narrow screens
  final int maxCrossAxisCount; // used on wide screens
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Simple responsive columns: 2 on narrow, 4 on wide
        final crossAxisCount = c.maxWidth < 520 ? minCrossAxisCount : maxCrossAxisCount;

        // Card aspect ratio so the reserved title area + icon fit nicely
        // You can tweak this if you want taller/shorter cards.
        final childAspectRatio = c.maxWidth < 520 ? 1.62 : 1.3;

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
    // Reserve space equal to exactly 2 lines of text (so 1-line titles won’t shrink the card).
    // lineHeight ~ 1.25 for good readability.
    final double lineHeight = 1.25;
    final double twoLineBoxHeight = titleFontSize * lineHeight * 2;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              blurRadius: 3,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(size: 34, color: iconColor),
              child: _wrapIcon(item.icon, 28),
              
            ),
            const SizedBox(height: 0),
            // Fixed-height box to ensure all cards are equal height whether 1 or 2 lines
            SizedBox(
              height: twoLineBoxHeight,
              child: Center(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    height: lineHeight,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _wrapIcon(Widget icon, double size) {
    if (icon is Icon) {
      return Icon(icon.icon, size: size,);
    }
    return SizedBox(height: size, width: size, child: FittedBox(child: icon));
  }
}
