import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> _downloadInvoice(
    BuildContext context, String url, String invoiceNo) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading invoice $invoiceNo...')),
    );

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$invoiceNo.pdf';

    await Dio().download(url, filePath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download complete: $invoiceNo.pdf')),
    );

    // ✅ Open file automatically
    await OpenFile.open(filePath);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download failed: $e')),
    );
  }
}
