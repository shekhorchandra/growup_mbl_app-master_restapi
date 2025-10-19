import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  // static const String _url = 'https://growupagro.tech/about-us';
  final String _url = ApiConstants.aboutUsUrl;


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
    // Close this page after opening browser
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optional: show a temporary loading screen while browser opens
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
