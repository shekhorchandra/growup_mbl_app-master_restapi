import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<Offset> _logoOffset;
  late Animation<double> _logoOpacity;

  late AnimationController _sloganController;
  late Animation<Offset> _sloganOffset;
  late Animation<double> _sloganOpacity;

  late AnimationController _buttonController;
  late Animation<Offset> _buttonOffset;
  late Animation<double> _buttonOpacity;

  bool isLoading = false;

  // 🎥 Video controller
  late VideoPlayerController _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    // Initialize video background
    _videoController = VideoPlayerController.asset('assets/videos/intro.mov')
      ..setLooping(true)
      ..setVolume(0.0) // 🔇 Mute
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _videoReady = true);
          _videoController.play();
        }
      });

    // Logo Animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoOffset =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
        );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(_logoController);

    // Slogan Animation
    _sloganController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sloganOffset =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _sloganController, curve: Curves.easeOut),
        );
    _sloganOpacity =
        Tween<double>(begin: 0, end: 1).animate(_sloganController);

    // Button Animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonOffset =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
        );
    _buttonOpacity =
        Tween<double>(begin: 0, end: 1).animate(_buttonController);

    // Start animations sequentially
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoController.forward();
    await _sloganController.forward();
    await _buttonController.forward();
  }

  void _handlePress() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => isLoading = false);
    Navigator.pushNamed(context, 'register');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _sloganController.dispose();
    _buttonController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScaleFactorOf(context);
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🎥 Video background
          if (_videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            Container(color: Colors.black),

          // semi-transparent overlay for readability
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: height * 0.10),
                        ],
                      ),
                    ),
                  ),
                ),

                // Buttons Animation
                SlideTransition(
                  position: _buttonOffset,
                  child: FadeTransition(
                    opacity: _buttonOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, 'login'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.shade700,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isLoading ? null : _handlePress,
                            child: isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'Create an account',
                              style: TextStyle(
                                fontSize: 15 * textScale,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
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
