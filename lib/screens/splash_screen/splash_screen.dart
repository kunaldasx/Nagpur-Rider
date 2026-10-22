import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/config/app_images.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import '../../config/colors.dart';
import '../../config/global.dart';
import '../../utils/notification_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start navigation after a delay to show splash screen
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        navigate();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> navigate() async {
    try {
      // Get FCM token (Firebase is already initialized in main.dart)
      try {
        log('🚀 SPLASH SCREEN: Getting FCM token...');

        // Request permission first (important for iOS)
        await NotificationManager().requestPermission();

        // Get FCM token
        final fcmToken = await NotificationManager().getFCMToken();
        log('📧 SPLASH SCREEN: FCM token retrieved: $fcmToken');

        if (fcmToken != null && fcmToken.isNotEmpty) {
          log('✅ SPLASH SCREEN: Token is valid, saving to Global...');
          log('TOKEN :::::::::: $fcmToken');

          // Save FCM token to Global for use throughout the app
          await Global.setFCMToken(fcmToken);
          log('✅ SPLASH SCREEN: Token saved to Global');

          // Already logged in: make sure the backend pushes order alerts
          // to this token. Not awaited, so a slow network can't hold the
          // splash screen.
          NotificationManager().syncTokenWithBackend(fcmToken);
        } else {
          log('⚠️ SPLASH SCREEN: Token is null or empty');
          // Try to get token again after a short delay
          await Future.delayed(Duration(seconds: 1));
          final retryToken = await NotificationManager().getFCMToken();
          if (retryToken != null && retryToken.isNotEmpty) {
            await Global.setFCMToken(retryToken);
            log('✅ SPLASH SCREEN: Token retrieved on retry: $retryToken');
          }
        }
      } catch (e) {
        log('❌ SPLASH SCREEN: Error getting FCM token: $e');
      }

      // Wait for 2 seconds (splash screen duration)
      await Future.delayed(Duration(seconds: 2));

      // Check if widget is still mounted before proceeding
      if (!mounted) {
        return;
      }

      // Check authentication status and redirect accordingly
      final token = await Global.getUserToken();

      if (token != null) {
        // User is authenticated, go to dashboard
        if (mounted) {
          GoRouter.of(context).pushReplacement(AppRoutes.dashboard);
        }
      } else {
        // User is not authenticated, go to login
        if (mounted) {
          GoRouter.of(context).pushReplacement(AppRoutes.login);
        }
      }
    } catch (e) {
      log('❌ SPLASH SCREEN: Navigation error: $e');
      // If there's an error, redirect to login as fallback
      if (mounted) {
        try {
          GoRouter.of(context).pushReplacement(AppRoutes.login);
        } catch (navigationError) {
          log('❌ SPLASH SCREEN: Navigation fallback error: $navigationError');
        }
      }
    }
  }

  @override
  /* Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Animation
            // Lottie.asset(
            //   'assets/lottie/Food Courier.json',
            //   width: 150.w,
            //   height: 150.h,
            //   fit: BoxFit.contain,
            //   repeat: true,
            //   animate: true,
            // ),
            Image.asset(
              AppImages.splashLogo,
              width: 200.w,
              height: 200.h,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  } */
 Widget build(BuildContext context) {
  return Scaffold(
    body: Image.asset('assets/png/splash-rider.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    ),
  );
}
}
