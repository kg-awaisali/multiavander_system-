import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../auth/views/login_screen.dart';
import '../../home/views/home_screen.dart';
import '../../admin/views/admin_dashboard_screen.dart';
import '../../seller/views/seller_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final role = prefs.getInt('role');

    if (token != null) {
      if (role == 1) {
        Get.offAll(() => const AdminDashboardScreen());
      } else if (role == 2) {
        Get.offAll(() => const SellerDashboardScreen());
      } else {
        Get.offAll(() => const HomeScreen());
      }
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // CORRECT asset name (matches pubspec.yaml)
            Image.asset(
              'assets/images/app_logo.png',  // Changed to match pubspec.yaml
              width: 180,
              height: 180,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image not found
                print('Error loading logo: $error');
                return const Icon(
                  Icons.shopping_bag,
                  size: 100,
                  color: AppTheme.primaryColor,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'SMART SHOP',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'For Everyone',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}