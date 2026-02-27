import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Smart Shop';
  
  // Use local server for API
  // Use local server for API
  static String get baseUrl {
    return 'https://codegeeks.easycode4u.com/api'; 
  }
  
  // Base URL without /api for storage paths
  static String get serverUrl {
    return 'https://codegeeks.easycode4u.com/public';
  }
  
  // Helper to get full image URL from relative path
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path; // Already full URL
    
    // Ensure path has a leading slash
    String cleanPath = path.startsWith('/') ? path : '/$path';
    
    // Review images are in /public/uploads/reviews/
    if (cleanPath.contains('/uploads/reviews/')) {
      return 'https://codegeeks.easycode4u.com/public$cleanPath';
    }
    
    // All other images (products, etc.) use base serverUrl without /public
    return 'https://codegeeks.easycode4u.com$cleanPath';
  }
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
