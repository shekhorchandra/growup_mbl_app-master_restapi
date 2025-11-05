import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PDFViewPage extends StatefulWidget {
  final String url;
  final String title;

  const PDFViewPage({super.key, required this.url, required this.title});

  @override
  State<PDFViewPage> createState() => _PDFViewPageState();
}

class _PDFViewPageState extends State<PDFViewPage> {
  String? localPath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFromNetwork();
  }

  Future<void> _loadPdfFromNetwork() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_invoice.pdf');
        await file.writeAsBytes(bytes, flush: true);

        if (!mounted) return;
        setState(() {
          localPath = file.path;
          loading = false;
        });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      // 🔙 Show error and navigate back after short delay
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load PDF. Returning to previous page.'),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.green),
      )
          : localPath == null
          ? const Center(child: Text('Failed to open PDF'))
          : PDFView(
        filePath: localPath!,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: true,
        onError: (error) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Failed to load PDF.'),
              ),
            );
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }
}
