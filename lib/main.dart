import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'core/theme.dart';
import 'modules/splash_screen.dart'; 
import 'modules/auth/views/login_screen.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'modules/home/views/home_screen.dart';
import 'modules/search/views/search_results_screen.dart';
import 'modules/admin/views/admin_attributes_screen.dart';
import 'modules/notifications/views/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Step 1: Firebase Initialize karein
  await initializeFirebase();
  
  // ✅ Step 2: GetStorage Initialize karein
  await GetStorage.init();
  
  // ✅ Step 3: Auth Controller Initialize karein
  Get.put(AuthController());
  
  // ✅ Step 4: App Run karein
  runApp(const MyApp());
}

// ✅ Firebase Initialization Function
Future<void> initializeFirebase() async {
  try {
    print('🚀 Firebase initializing...');
    
    // Firebase ko initialize karein with platform options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('✅ Firebase successfully connected!');
    print('📱 Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    
    // Enable Offline Persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, 
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
    );
    print('💾 Firestore Offline Persistence Enabled');
    
  } catch (error) {
    print('❌ Firebase connection failed: $error');
    print('⚠️ App will run without Firebase features');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(), // Start with University Splash
      getPages: [
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/search-results', page: () => const SearchResultsScreen()),
        GetPage(name: '/admin/attributes', page: () => const AdminAttributesScreen()),
        GetPage(name: '/notifications', page: () => const NotificationScreen()),
      ],
    );
  }
}