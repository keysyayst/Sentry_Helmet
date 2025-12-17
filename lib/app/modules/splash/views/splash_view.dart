import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../core/theme/app_colors.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('[SPLASH VIEW] build() called');
    print(
      '[SPLASH VIEW] Controller registered: ${Get.isRegistered<SplashController>()}',
    );
    // Ensure controller is initialized and trigger navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[SPLASH VIEW] addPostFrameCallback executed');
      // This runs after the first frame is rendered
      if (!Get.isRegistered<SplashController>()) {
        print('[SPLASH VIEW] Controller not registered, creating now...');
        Get.put(SplashController());
      } else {
        print('[SPLASH VIEW] Controller already registered');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Icon(Icons.sports_motorsports, size: 120, color: Colors.white),
              const SizedBox(height: 24),

              // App Name
              const Text(
                'SENTRY HELMET',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Smart Helmet for Your Safety',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
