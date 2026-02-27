import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import '../../../data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/login_screen.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../chat/controllers/chat_controller.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var user = Rxn<UserModel>();
  bool get isLoggedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if(token != null) {
       fetchProfile();
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    try {
      final response = await ApiClient.post('/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, data['access_token']);
        
        user.value = UserModel.fromJson(data['user']);
        
        // Persist role for quick checks
        await prefs.setInt('role', user.value!.role);

        // Refresh Data
        try {
          final cartCtrl = Get.isRegistered<CartController>() 
              ? Get.find<CartController>() 
              : Get.put(CartController());
          
          final chatCtrl = Get.isRegistered<ChatController>()
              ? Get.find<ChatController>()
              : Get.put(ChatController());

          cartCtrl.fetchCartFromServer();
        } catch (e) {
          print('Data refresh error: $e');
        }

        return true;
      } else {
        String errorMessage = 'Invalid credentials';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          if (response.body.contains('<!DOCTYPE html>')) {
             errorMessage = "Server Error (500). Please check Laravel logs.";
          }
        }
        Get.snackbar('Login Failed', errorMessage, backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Login Exception: $e', backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register(String name, String email, String password, String phone) async {
    isLoading.value = true;
    try {
      final response = await ApiClient.post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password, // Laravel usually expects this
        'phone': phone,
        'role': 3, // Buyer
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, data['access_token']);
        user.value = UserModel.fromJson(data['user']);
        await prefs.setInt('role', user.value!.role);
        
        // Refresh Data
        try {
          final cartCtrl = Get.isRegistered<CartController>() 
              ? Get.find<CartController>() 
              : Get.put(CartController());
          
          final chatCtrl = Get.isRegistered<ChatController>()
              ? Get.find<ChatController>()
              : Get.put(ChatController());

          cartCtrl.fetchCartFromServer();
          // chatCtrl.fetchRooms(); // Firestore uses streams
        } catch (e) {
          print('Registration refresh error: $e');
        }

        return true;
      } else {
        Get.snackbar('Error', 'Registration Failed: ${response.body}');
        return false;
      }
    } catch (e) {
       Get.snackbar('Error', 'Register Exception: $e');
       return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> registerSeller(
    String name, String shopName, String phone, String email, String password, {
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? bankName,
    String? accountTitle,
    String? accountNumber,
  }) async {
    isLoading.value = true;
    try {
      final response = await ApiClient.post('/seller/register', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'shop_name': shopName,
        'address': address ?? '',
        'city': city ?? '',
        'state': state ?? '',
        'postal_code': postalCode ?? '',
        'bank_name': bankName ?? '',
        'account_title': accountTitle ?? '',
        'account_number': accountNumber ?? '',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Registration submitted! Pending admin approval.');
        return true;
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar('Error', data['message'] ?? 'Seller Registration Failed');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Exception: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await ApiClient.get('/user');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        user.value = UserModel.fromJson(data);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data));
      }
    } catch (e) {
      print('Profile fetch error: $e');
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove('role');

    // Completely remove controllers on logout to ensure fresh state on next login
    try {
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().clearCart();
        Get.delete<CartController>(force: true);
      }
      if (Get.isRegistered<ChatController>()) {
        Get.delete<ChatController>(force: true);
      }
    } catch (e) {
      print('Logout cleanup error: $e');
    }

    user.value = null;
    Get.offAll(() => LoginScreen());
  }
}
