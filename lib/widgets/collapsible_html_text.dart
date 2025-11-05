import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class CollapsibleHtmlText extends StatefulWidget {
  final String htmlContent;
  final int collapsedLines;
  final Color expandButtonColor;
  final String expandLabel;
  final String collapseLabel;

  const CollapsibleHtmlText({
    Key? key,
    required this.htmlContent,
    this.collapsedLines = 4,
    this.expandButtonColor = Colors.green,
    this.expandLabel = 'Read more',
    this.collapseLabel = 'Collapse',
  }) : super(key: key);

  @override
  State<CollapsibleHtmlText> createState() => _CollapsibleHtmlTextState();
}

class _CollapsibleHtmlTextState extends State<CollapsibleHtmlText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildCollapsedHtml(),
          secondChild: Html(data: widget.htmlContent),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: widget.expandButtonColor,
            ),
            label: Text(
              _isExpanded ? widget.collapseLabel : widget.expandLabel,
              style: TextStyle(
                color: widget.expandButtonColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedHtml() {
    // Extract plain text from HTML for preview
    final plainText = widget.htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    return Text(
      plainText,
      maxLines: widget.collapsedLines,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.black87, height: 1.5),
    );
  }
}
