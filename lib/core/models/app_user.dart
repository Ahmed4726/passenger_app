class AppUser {
  AppUser({required this.id, required this.name, required this.email, required this.phone, required this.token});

  final int id;
  final String name;
  final String email;
  final String phone;
  final String token;

  factory AppUser.fromJson(Map<String, dynamic> json, {String? token}) {
    return AppUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      token: token ?? '',
    );
  }
}
