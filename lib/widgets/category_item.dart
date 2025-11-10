import 'package:flutter/material.dart';

class CategoryItem {
  final Widget icon;
  final String title;
  final Color itemBgColor;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isLive;
  final List<CategoryItem> subItems;

  const CategoryItem({
    required this.icon,
    required this.title,
    this.itemBgColor = Colors.white,
    this.textColor = const Color(0xFF555555),
    this.onTap,
    this.isLive = false,
    this.subItems = const [],
  });

  bool get hasSubItems => subItems.isNotEmpty;
}

class CategoryGridCard extends StatelessWidget {
  const CategoryGridCard({
    super.key,
    required this.items,
    this.iconColor = Colors.green,
    this.bgColor = Colors.white,
    this.minCrossAxisCount = 3,
    this.maxCrossAxisCount = 4,
    this.titleFontSize = 10,
    this.iconSize = 50,
    this.horizontalGap = 12,
    this.verticalGap = 12,
    this.cardHeight = 70,
    this.subCardHeight = 60,
  });

  final List<CategoryItem> items;
  final Color iconColor;
  final Color bgColor;
  final int minCrossAxisCount;
  final int maxCrossAxisCount;
  final double titleFontSize;
  final double iconSize;
  final double horizontalGap;
  final double verticalGap;
  final double cardHeight;
  final double subCardHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final crossAxisCount =
        width < 520 ? minCrossAxisCount : maxCrossAxisCount;
        final totalGapsWidth = (crossAxisCount - 1) * horizontalGap;
        final tileWidth = (width - totalGapsWidth) / crossAxisCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: horizontalGap,
              runSpacing: verticalGap,
              children: items
                  .map(
                    (item) => SizedBox(
                  width: tileWidth,
                  child: _buildParentCard(context, item),
                ),
              )
                  .toList(),
            ),

            ...items.where((i) => i.hasSubItems).map(
                  (item) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildFullWidthSubTree(context, item),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParentCard(BuildContext context, CategoryItem item) {
    return _buildCard(context, item, iconSize, cardHeight);
  }

  Widget _buildFullWidthSubTree(BuildContext context, CategoryItem item) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth,
      child: _buildSubTree(item.subItems),
    );
  }

  Widget _buildSubTree(List<CategoryItem> subItems) {
    return Column(
      children: List.generate(subItems.length, (index) {
        final sub = subItems[index];
        final isLast = index == subItems.length - 1;

        return _TreeRow(
          isLast: isLast,
          subCardHeight: subCardHeight,
          child: _buildCard(null, sub, iconSize * 0.7, subCardHeight),
        );
      }),
    );
  }

  Widget _buildCard(
      BuildContext? context,
      CategoryItem item,
      double? iconSize,
      double height,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Stack(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: item.itemBgColor,
              border: Border(
                left: BorderSide(color: Colors.green[700]!, width: 3),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(size: iconSize, color: iconColor),
                  child: Center(child: _wrapIcon(item.icon, iconSize!)),
                ),
                const SizedBox(height: 6),
                Text(
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
              ],
            ),
          ),
          if (item.isLive)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    if (icon is Icon) return Icon(icon.icon, size: size);
    return SizedBox(
      height: size,
      width: size,
      child: FittedBox(child: icon),
    );
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.isLast,
    required this.child,
    this.indent = 30,
    this.lineWidth = 2,
    required this.subCardHeight,
  });

  final bool isLast;
  final Widget child;
  final double indent;
  final double subCardHeight;
  final double lineWidth;

  @override
  Widget build(BuildContext context) {
    final Color lineColor = Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: indent,
            height: subCardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                // Vertical line
                Positioned.fill(
                  left: indent / 2 - (lineWidth / 2),
                  bottom: isLast ? subCardHeight / 2 : 0,
                  top: -10,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(width: lineWidth, color: lineColor),
                  ),
                ),

                // Horizontal line
                Positioned(
                  left: indent / 2,
                  top: subCardHeight / 2 - (lineWidth / 2),
                  right: 0,
                  child: Container(height: lineWidth, color: lineColor),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}