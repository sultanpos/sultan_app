import 'package:flutter/material.dart';

class ResponsivePage extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsivePage({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > 900;

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return desktop;
    }
    return mobile;
  }
}
