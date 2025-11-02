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
    this.aspectRatio,
  });

  final List<CategoryItem> items;
  final Color iconColor;
  final Color textColor;
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

        // ✅ Adjust aspect ratio dynamically to avoid overflow
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
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
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
                data: IconThemeData(size: 50, color: iconColor), // ⬆️ increased to 50
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
                  color: textColor,
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
      return Icon(icon.icon, size: size);
    }
    return SizedBox(height: size, width: size, child: FittedBox(child: icon));
  }
}
