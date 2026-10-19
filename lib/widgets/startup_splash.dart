import 'dart:async';

import 'package:flutter/material.dart';

class StartupSplash extends StatefulWidget {
  const StartupSplash({
    super.key,
    required this.child,
    this.holdDuration = const Duration(milliseconds: 1500),
    this.fadeDuration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final Duration holdDuration;
  final Duration fadeDuration;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> {
  bool _visible = true;
  bool _fading = false;
  Timer? _holdTimer;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _startExitAnimation();
  }

  void _startExitAnimation() {
    _holdTimer = Timer(widget.holdDuration, () {
      if (!mounted) return;

      setState(() => _fading = true);
      _fadeTimer = Timer(widget.fadeDuration, () {
        if (!mounted) return;

        setState(() => _visible = false);
      });
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          AnimatedOpacity(
            opacity: _fading ? 0 : 1,
            duration: widget.fadeDuration,
            curve: Curves.easeOutCubic,
            child: const _SplashContent(),
          ),
      ],
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  static const _background = Color(0xFFFFFBF5);
  static const _textColor = Color(0xFF263445);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/branding/sprout_english_logo.png',
                  width: 118,
                  height: 118,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sprout English',
                textAlign: TextAlign.center,
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      decoration: TextDecoration.none,
                    ) ??
                    const TextStyle(
                      color: _textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      decoration: TextDecoration.none,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
