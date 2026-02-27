# Smart Shop - Multi-Vendor E-Commerce System

**Smart Shop** is a comprehensive, modern multi-vendor e-commerce platform built using **Flutter**. It provides a seamless experience for Admins, Sellers, and Customers, leveraging **Firebase** for real-time data and **GetX** for efficient state management.

## 🚀 Key Features

### 🛡️ Admin Dashboard
- **Attributes Management**: Full control over product attributes and variations.
- **System Configuration**: Manage categories, notifications, and cross-platform settings.
- **User Management**: Oversight of both customers and sellers.

### 🏪 Seller Portal
- **Shop Management**: Dedicated space for sellers to showcase their products.
- **Inventory Control**: Easy product uploads and stock tracking.
- **Communication**: Integrated chat system to interact with customers.

### 🛍️ Customer Experience
- **Smart Search**: Find products quickly with an optimized search module.
- **Seamless Checkout**: Integrated cart system and digital wallet.
- **Real-time Notifications**: Stay updated on orders and promotional offers.
- **Voucher System**: Reward customers with discount codes and special deals.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (v3.10.4+)
- **State Management**: [GetX](https://pub.dev/packages/get)
- **Backend/Database**: [Firebase (Firestore)](https://firebase.google.com/)
- **Authentication**: Firebase Auth
- **Storage**: GetStorage & Shared Preferences
- **Styling**: Google Fonts & Custom Theme Engine

## 📂 Project Structure

```text
lib/
├── core/         # Core utilities, themes, and constants
├── data/         # Models and API/Database services
├── modules/      # Feature-based architecture
│   ├── admin/    # Admin panel screens and logic
│   ├── seller/   # Seller portal modules
│   ├── auth/     # Login and registration
│   ├── home/     # Customer home screen
│   └── ...       # Cart, Chat, Wallet, etc.
└── widgets/      # Reusable UI components
```

## 🏁 Getting Started

1. **Prerequisites**: Ensure you have Flutter installed.
2. **Clone the Repo**:
   ```bash
   git clone https://github.com/kg-awaisali/multiavander_system-.git
   ```
3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Setup Firebase**: Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly placed if you're using your own Firebase project.
5. **Run the App**:
   ```bash
   flutter run
   ```

## 📄 License

This project is developed for educational and professional e-commerce use cases.

---
*Created by Awais Ali*
