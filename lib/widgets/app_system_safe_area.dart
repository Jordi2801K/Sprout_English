import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSystemSafeArea extends StatelessWidget {
  const AppSystemSafeArea({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: color,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: color,
        child: SafeArea(bottom: false, left: false, right: false, child: child),
      ),
    );
  }
}
