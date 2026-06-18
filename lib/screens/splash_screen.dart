import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  AppOpenAd? _appOpenAd;
  bool _hasNavigationStarted = false;

  late AnimationController _dotController;
  late Animation<double> _dot1Anim;
  late Animation<double> _dot2Anim;
  late Animation<double> _dot3Anim;

  static const String _appOpenAdUnitId = 'ca-app-pub-8287945486916442/8915457248';

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

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

    _loadAppOpenAd();
    Future.delayed(const Duration(seconds: 5), _tryShowAdAndNavigate);
  }

  Future<void> _tryShowAdAndNavigate() async {
    if (_hasNavigationStarted) return;
    _hasNavigationStarted = true;

    final ad = _appOpenAd;
    if (ad != null) {
      _appOpenAd = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (dismissedAd) {
          dismissedAd.dispose();
          _goToHome();
        },
        onAdFailedToShowFullScreenContent: (failedAd, error) {
          failedAd.dispose();
          debugPrint('App open ad failed to show: $error');
          _goToHome();
        },
      );
      await ad.show();
    } else {
      _goToHome();
    }
  }

  void _goToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _dotController.dispose();
    _appOpenAd?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (_hasNavigationStarted) {
            ad.dispose();
            return;
          }
          setState(() {
            _appOpenAd = ad;
          });
          _tryShowAdAndNavigate();
        },
        onAdFailedToLoad: (error) {
          debugPrint('App open ad failed to load: $error');
          setState(() {});
          _tryShowAdAndNavigate();
        },
      ),
    );
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
            const Text(
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
