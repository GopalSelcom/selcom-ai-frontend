class ActivateWalletRequest {
  const ActivateWalletRequest({
    required this.name,
    required this.dob,
    required this.phone,
    required this.address1,
    required this.address2,
    this.email = '',
  });

  final String name;
  final String dob;
  final String phone;
  final String email;
  final String address1;
  final String address2;

  Map<String, dynamic> toJson() => {
    'name': name,
    'id_type': '',
    'id_number': '',
    'id_expiry': '',
    'dob': dob,
    'phone': phone,
    'email': email,
    'address1': address1,
    'address2': address2,
  };
}
