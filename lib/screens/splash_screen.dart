import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/ecotahu_loader.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  bool _isReady = false;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isReady) {
        if (_progress < 0.85) {
          setState(() {
            _progress = (_progress + math.max(0.01, (0.85 - _progress) * 0.12)).clamp(0.0, 0.85);
          });
        }
      } else {
        timer.cancel();
        setState(() => _progress = 1.0);
        Future.delayed(const Duration(milliseconds: 380), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 450),
              pageBuilder: (_, __, ___) => const MainScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        });
      }
    });

    Future.wait([
      Provider.of<AuthProvider>(context, listen: false).checkLoginStatus(),
      Future.delayed(const Duration(milliseconds: 1100)),
    ]).whenComplete(() {
      if (mounted) {
        _isReady = true;
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EcoTahuSplashLoader(progress: _progress),
    );
  }
}