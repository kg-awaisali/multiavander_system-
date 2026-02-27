class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final int role;
  final double walletBalance;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.walletBalance = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'] is int ? json['role'] : int.parse(json['role'].toString()),
      walletBalance: json['wallet_balance'] != null ? double.parse(json['wallet_balance'].toString()) : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'wallet_balance': walletBalance,
  };
}
