import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/views/home_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme.dart';

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final shopNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final bankNameController = TextEditingController();
  final accountTitleController = TextEditingController();
  final accountNumberController = TextEditingController();
  
  int currentStep = 0;
  bool isLoading = false;
  bool agreedToTerms = false;

  final List<String> steps = ['Basic Info', 'Shop Details', 'Bank Details'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Futuristic Background
          Container(
            decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient.withOpacity(0.1),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildProgressBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildStepContent(),
                          const SizedBox(height: 32),
                          _buildNavigationButtons(),
                          const SizedBox(height: 40),
                        ],
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.primaryColor),
            onPressed: () => Get.back(),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Seller Portal", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                Text("Establish your digital empire", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, color: Colors.green, size: 28),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          bool isActive = index <= currentStep;
          bool isCurrent = index == currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive ? AppTheme.primaryGradient : null,
                    color: isActive ? null : Colors.grey.shade300,
                    boxShadow: isCurrent ? [
                      BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < currentStep ? AppTheme.primaryColor : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                steps[currentStep],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              if (currentStep == 0) _buildPersonalInfoFields(),
              if (currentStep == 1) _buildShopInfoFields(),
              if (currentStep == 2) _buildBankInfoFields(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoFields() {
    return Column(
      children: [
        _buildFuturisticInput(nameController, 'Owner Full Name', Icons.person_outline),
        _buildFuturisticInput(emailController, 'Business Email', Icons.alternate_email, keyboardType: TextInputType.emailAddress),
        _buildFuturisticInput(phoneController, 'Contact Number', Icons.phone_android, keyboardType: TextInputType.phone),
        _buildFuturisticInput(passwordController, 'Secure Password', Icons.lock_outline, isPassword: true),
      ],
    );
  }

  Widget _buildShopInfoFields() {
    return Column(
      children: [
        _buildFuturisticInput(shopNameController, 'Enterprise Name', Icons.storefront_outlined),
        _buildFuturisticInput(addressController, 'Physical Address', Icons.location_on_outlined),
        Row(
          children: [
            Expanded(child: _buildFuturisticInput(cityController, 'City', Icons.location_city_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildFuturisticInput(stateController, 'State', Icons.map_outlined)),
          ],
        ),
        _buildFuturisticInput(postalCodeController, 'Postal Code', Icons.pin_drop_outlined, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildBankInfoFields() {
    return Column(
      children: [
        _buildFuturisticInput(bankNameController, 'Financial Institution', Icons.account_balance_outlined, required: false),
        _buildFuturisticInput(accountTitleController, 'Account Holder', Icons.person_search_outlined, required: false),
        _buildFuturisticInput(accountNumberController, 'IBAN / Account #', Icons.credit_card_outlined, required: false),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: agreedToTerms,
          onChanged: (v) => setState(() => agreedToTerms = v ?? false),
          title: const Text('I consent to the Digital Merchant Agreement', style: TextStyle(fontSize: 12)),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppTheme.primaryColor,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentStep > 0)
          TextButton(
            onPressed: () => setState(() => currentStep--),
            child: const Text("BACK", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          )
        else
          const SizedBox(),
        
        Container(
          width: 160,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : (currentStep < steps.length - 1 ? () => setState(() => currentStep++) : _submitRegistration),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    currentStep < steps.length - 1 ? 'NEXT PHASE' : 'LAUNCH STORE', 
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticInput(TextEditingController controller, String label, IconData icon, {
    bool isPassword = false, 
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7), size: 20),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1),
          ),
        ),
        validator: required ? (v) => v?.isEmpty == true ? 'This sequence is required' : null : null,
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!agreedToTerms) {
      Get.snackbar('Security Alert', 'Please accept the merchant agreement to proceed.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final authController = Get.find<AuthController>();
      final success = await authController.registerSeller(
        nameController.text,
        shopNameController.text,
        phoneController.text,
        emailController.text,
        passwordController.text,
        address: addressController.text,
        city: cityController.text,
        state: stateController.text,
        postalCode: postalCodeController.text,
        bankName: bankNameController.text,
        accountTitle: accountTitleController.text,
        accountNumber: accountNumberController.text,
      );

      if (success) {
        Get.offAll(() => const HomeScreen());
        Get.snackbar('Protocol Success', 'Application transmitted. Deployment pending review.', 
            backgroundColor: Colors.green.shade100, colorText: Colors.green.shade900);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }
}
