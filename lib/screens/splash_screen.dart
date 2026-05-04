import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_hospital, size: 72, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Nirmaya',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Clinic Management',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 60),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white54),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
