import 'package:flutter/material.dart';
import 'package:growup_agro/widgets/custom_button.dart';
import 'package:growup_agro/utils/invoice_utils.dart';

class InvoiceActionButtons extends StatefulWidget {
  final String? viewUrl;
  final String? downloadUrl;
  final String invoiceNo;
  final String? status;

  const InvoiceActionButtons({
    super.key,
    required this.viewUrl,
    required this.downloadUrl,
    required this.invoiceNo,
    this.status,
  });

  @override
  State<InvoiceActionButtons> createState() => _InvoiceActionButtonsState();
}

class _InvoiceActionButtonsState extends State<InvoiceActionButtons> {
  bool isViewing = false;
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.status?.toLowerCase() != "approved") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.block, color: Colors.red, size: 22),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomButton(
          // text: isViewing ? "Viewing..." : "View",
          height: 28,
          fontSize: 10,
          textColor: Colors.blue,
          icon: Icons.visibility,
          loading: isViewing,
          backgroundColor: Colors.blue.shade50,
          onPressed: isViewing
              ? null
              : () async {
            setState(() => isViewing = true);
            await viewInvoice(context, widget.viewUrl);
            setState(() => isViewing = false);
          }, text: '',
        ),
        SizedBox(width: 8),
        CustomButton(
          // text: isDownloading ? "Downloading..." : "Download",
          textColor: Colors.orange,
          height: 28,
          fontSize: 10,
          icon: Icons.download,
          loading: isDownloading,
          backgroundColor: Colors.orange.shade50,
          onPressed: isDownloading
              ? null
              : () async {
            setState(() => isDownloading = true);
            await downloadInvoice(
              context,
              widget.downloadUrl,
              widget.invoiceNo,
            );
            setState(() => isDownloading = false);
          }, text: '',
        ),
      ],
    );
  }
}
