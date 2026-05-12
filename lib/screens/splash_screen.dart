import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<double> _dot1Anim;
  late Animation<double> _dot2Anim;
  late Animation<double> _dot3Anim;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    
    // Set fullscreen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Setup dot bounce animation
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Create three staggered animations for bouncing effect
    _dot1Anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: const Interval(0.0, 0.33, curve: Curves.easeInOut),
      ),
    );
    _dot2Anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: const Interval(0.33, 0.66, curve: Curves.easeInOut),
      ),
    );
    _dot3Anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    _dotController.repeat();

    // Navigate to home after 5 seconds (longer display)
    _navTimer = Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _dotController.dispose();
    _navTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo Image
            Image.asset(
              'assets/icon.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.school,
                  size: 120,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(height: 60),
            // Bouncing loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _dotController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _dot1Anim.value,
                      child: _buildDot(),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _dotController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _dot2Anim.value,
                      child: _buildDot(),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _dotController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _dot3Anim.value,
                      child: _buildDot(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Brand text
            Text(
              'LearnIt',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
