import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../views/pdf_view_page.dart';

/// Opens the invoice in an external browser (view only — no download)
Future<void> viewInvoice(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice link not available')),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PDFViewPage(url: url, title: 'Invoice Preview'),
    ),
  );
}


/// Downloads invoice PDF and opens save dialog
Future<void> downloadInvoice(BuildContext context, String? url, String invoiceNo) async {
  if (url == null || url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download URL not available')),
    );
    return;
  }

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    responseType: ResponseType.bytes,
  ));

  try {
    final uri = Uri.parse(url);
    final tempDir = await getTemporaryDirectory();
    String baseName = 'invoice_$invoiceNo';
    String extension = '.pdf';
    String tempPath = '${tempDir.path}/$baseName$extension';
    int counter = 1;

    while (await File(tempPath).exists()) {
      tempPath = '${tempDir.path}/$baseName ($counter)$extension';
      counter++;
    }

    final response = await dio.getUri<List<int>>(uri);

    final f = File(tempPath);
    await f.writeAsBytes(response.data!, flush: true);

    final savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: tempPath.split('/').last, // same name as generated
      ),
    );

    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to: $savedPath')),
      );
      await OpenFilex.open(savedPath);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to download')),
    );
  }
}
