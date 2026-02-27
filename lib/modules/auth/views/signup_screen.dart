import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme.dart';
import '../../home/views/home_screen.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient.withOpacity(0.15),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor),
                        onPressed: () => Get.back(),
                      ),
                      const Text(
                        "Create New Account",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Join Smart Shop',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28, 
                                  fontWeight: FontWeight.bold, 
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your one-stop shopping destination',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 40),
                              
                              _buildFuturisticField(
                                controller: nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildFuturisticField(
                                controller: emailController,
                                label: 'Email Address',
                                icon: Icons.alternate_email_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildFuturisticField(
                                controller: phoneController,
                                label: 'Phone Number',
                                icon: Icons.phone_iphone_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _buildFuturisticField(
                                controller: passwordController,
                                label: 'Set Password',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                              ),
                              
                              const SizedBox(height: 32),
                              
                              Obx(() => Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: AppTheme.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: authController.isLoading.value 
                                    ? null 
                                    : () async {
                                        if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
                                          Get.snackbar("Error", "Please fill all fields");
                                          return;
                                        }
                                        
                                        bool success = await authController.register(
                                          nameController.text, 
                                          emailController.text, 
                                          passwordController.text,
                                          phoneController.text
                                        );
                                        
                                        if (success) {
                                           Get.offAll(() => const HomeScreen());
                                           Get.snackbar("Success", "Account created successfully!");
                                        }
                                      },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  child: authController.isLoading.value 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                ),
                              )),
                              
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account?", style: TextStyle(color: Colors.grey)),
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text("LOGIN", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.8), size: 20),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}