import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'screens/home_page.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SpaceSplashScreen(),
        '/home': (context) => const HomePage(),
      },
    ),
  );
}

class SpaceSplashScreen extends StatefulWidget {
  const SpaceSplashScreen({super.key});

  @override
  State<SpaceSplashScreen> createState() => _SpaceSplashScreenState();
}

class _SpaceSplashScreenState extends State<SpaceSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _navigated = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Auto navigation fallback after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (!_navigated) {
        _navigated = true;
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _buildAnimatedStars() {
    return List.generate(30, (index) {
      return Positioned(
        left: _random.nextDouble() * MediaQuery.of(context).size.width,
        top: _random.nextDouble() * MediaQuery.of(context).size.height,
        child: AnimatedOpacity(
          opacity: _random.nextBool() ? 1.0 : 0.4,
          duration: Duration(milliseconds: 500 + _random.nextInt(800)),
          child: Icon(
            Icons.star,
            size: _random.nextDouble() * 3 + 2,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A043C),
      body: Stack(
        children: [
          // Glowing Nebula Background
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/nebula_bg.svg',
              fit: BoxFit.cover,
              colorBlendMode: BlendMode.screen,
              color: Colors.tealAccent.withOpacity(0.05),
            ),
          ),

          ..._buildAnimatedStars(),

          Center(
            child: ScaleTransition(
              scale: _animation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Logo Only (no decoration, larger)
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App Title
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    child: AnimatedTextKit(
                      repeatForever: true,
                      animatedTexts: [
                        TyperAnimatedText('Atmospheric Quality Intelligence'),
                        TyperAnimatedText('Space-Grade Air Quality Analysis'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Circular Loader
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                  ),

                  const SizedBox(height: 30),

                  // Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      if (!_navigated) {
                        _navigated = true;
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      elevation: 10,
                      shadowColor: Colors.tealAccent,
                    ),
                    child: const Text(
                      'GET STARTED',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
