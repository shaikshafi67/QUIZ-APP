import 'package:flutter/material.dart';

class LogoBackground extends StatelessWidget {
  final Widget child;

  const LogoBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Background Logo (Watermark)
        Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: 0.1, // 10% visible (very faint)
              child: Image.asset(
                'assets/images/logo.png',
                width: 300, // Large size
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        
        // 2. The Page Content (Login page, etc.)
        child, 
      ],
    );
  }
}