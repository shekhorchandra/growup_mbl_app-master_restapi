// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
//
// class NewsWebViewPage extends StatefulWidget {
//   const NewsWebViewPage({Key? key}) : super(key: key);
//
//   @override
//   State<NewsWebViewPage> createState() => _NewsWebViewPageState();
// }
//
// class _NewsWebViewPageState extends State<NewsWebViewPage> {
//   late final WebViewController _controller;
//   bool _isLoading = true;
//
//   static const String _initialUrl = 'https://growupagro.tech/news';
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Create controller and configure it.
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0x00000000))
//       ..setNavigationDelegate(NavigationDelegate(
//         onPageStarted: (String url) {
//           setState(() => _isLoading = true);
//         },
//         onPageFinished: (String url) {
//           setState(() => _isLoading = false);
//         },
//         onNavigationRequest: (NavigationRequest request) {
//           // Allow navigation inside the WebView. You can block external URLs if you want.
//           return NavigationDecision.navigate;
//         },
//         onWebResourceError: (WebResourceError error) {
//           // Optional: show error or log
//         },
//       ))
//       ..loadRequest(Uri.parse(_initialUrl));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF2E7D32),
//         foregroundColor: Colors.white,
//         title: const Text("News", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => _controller.reload(),
//             tooltip: 'Reload',
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           // WebViewWidget is the visual widget for the WebViewController
//           WebViewWidget(controller: _controller),
//
//           // Loading indicator
//           if (_isLoading)
//             const Center(
//               child: CircularProgressIndicator(),
//             ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  // static const String _url = 'https://growupagro.tech/news';
  final String _url = ApiConstants.newsUrl;

  @override
  void initState() {
    super.initState();
    _openBrowser();
  }

  Future<void> _openBrowser() async {
    final Uri uri = Uri.parse(_url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
    // After opening the browser, close this page
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
