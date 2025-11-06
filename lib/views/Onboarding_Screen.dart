import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'package:growup_agro/views/login.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  final List<Map<String, dynamic>> pages = [
    {
      "icon": Icons.grass,
      "title": "The Future of Farming, Today.",
      "subtitle":
      "Join a community of modern farmers. Get insights, manage crops, and grow your business.",
      "image": "assets/images/futurefram.jpg",
    },
    {
      "icon": Icons.show_chart,
      "title": "Invest in Agro-Projects",
      "subtitle":
      "Fund promising agricultural projects and become a trusted partner in their success.",
      "image": "assets/images/animal.jpg",
    },
    {
      "icon": Icons.home,
      "title": "Own Your Farmland",
      "subtitle":
      "Buy or invest in agricultural land. Build your dream farm for a sustainable future.",
      "image": "assets/images/fram.jpg",
    },
    {
      "icon": Icons.shopping_cart,
      "title": "Shop for Agri-essentials",
      "subtitle":
      "Seeds, fertilizers, and machinery—get all your farming needs from our trusted marketplace.",
      "image": "assets/images/agriessn.jpg",
    },
    {
      "icon": "",
      "title": "",
      "subtitle": "",
      "image": "assets/images/APP-BG1-Recovered.jpg",
    },
    /* Example video page:
    {
      "isVideo": true,
      "videoSource": "asset",
      "videoPath": "assets/videos/intro.mov",
    }, */
  ];

  VideoPlayerController? _videoController;
  bool _videoReady = false;

  int get _videoPageIndex => pages.indexWhere((p) => p['isVideo'] == true);

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyLogin()),
    );
  }

  void _onNextTap() {
    if (currentPage == pages.length - 1) {
      _complete();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final i = _videoPageIndex;
    if (i != -1) {
      final isAsset = (pages[i]['videoSource'] ?? 'asset') == 'asset';
      _videoController = isAsset
          ? VideoPlayerController.asset(pages[i]['videoPath'])
          : VideoPlayerController.networkUrl(Uri.parse(pages[i]['videoPath']));

      _videoController!
        ..setLooping(true)
        ..setVolume(0.0)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _videoReady = true);
          if (currentPage == i) _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() => currentPage = index);

              final i = _videoPageIndex;
              if (_videoController != null && i != -1) {
                if (index == i) {
                  if (_videoReady) _videoController!.play();
                } else {
                  _videoController!.pause();
                }
              }
            },
            itemBuilder: (context, index) {
              final data = pages[index];
              final isVideo = data['isVideo'] == true;
              final isLastPage = index == pages.length - 1;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Background
                  if (isVideo)
                    _VideoBackground(controller: _videoController, ready: _videoReady)
                  else
                    Image.asset(data["image"]!, fit: BoxFit.cover),

                  // Blur + gradient only for non-last pages
                  if (!isVideo && !isLastPage) ...[
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(color: Colors.black.withOpacity(0.3)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],

                  // Card with icon/title/subtitle only for non-last pages
                  if (!isVideo && !isLastPage)
                    Align(
                      alignment: const Alignment(0, -0.1),
                      child: Card(
                        color: Colors.black.withOpacity(0.65),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: EdgeInsets.symmetric(horizontal: screenW * 0.08),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenH * 0.04,
                            horizontal: screenW * 0.06,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                            data["icon"] == "" ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                            children: [
                              if (data["icon"] != "")
                                Icon(data["icon"], color: Colors.white, size: screenW * 0.15),
                              SizedBox(height: screenH * 0.02),
                              Text(
                                data["title"] ?? '',
                                style: TextStyle(
                                  fontSize: screenW * 0.09,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: data["icon"] == "" ? TextAlign.center : TextAlign.start,
                              ),
                              SizedBox(height: screenH * 0.015),
                              Text(
                                data["subtitle"] ?? '',
                                style: TextStyle(
                                  fontSize: screenW * 0.04,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                                textAlign: data["icon"] == "" ? TextAlign.center : TextAlign.start,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Skip button
          Positioned(
            top: screenH * 0.06,
            right: screenW * 0.05,
            child: TextButton(
              onPressed: _complete,
              child: const Text(
                "Skip",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Dots + Next button
          Positioned(
            bottom: screenH * 0.08,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                        (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: screenW * 0.01),
                      width: currentPage == i ? screenW * 0.06 : screenW * 0.025,
                      height: screenH * 0.01,
                      decoration: BoxDecoration(
                        color: currentPage == i ? Colors.green : Colors.white54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenH * 0.03),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenW * 0.3,
                      vertical: screenH * 0.018,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _onNextTap,
                  child: Text(
                    currentPage == pages.length - 1 ? "Get Started" : "Next",
                    style: TextStyle(
                      fontSize: screenW * 0.045,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoBackground extends StatelessWidget {
  const _VideoBackground({required this.controller, required this.ready});

  final VideoPlayerController? controller;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !ready || !controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    final value = controller!.value;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: value.size.width,
        height: value.size.height,
        child: VideoPlayer(controller!),
      ),
    );
  }
}
