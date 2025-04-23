class User {
  final String id;
  final String displayName;
  final String email;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String idToken;
  User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.idToken,
  });

  bool get isTokenExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'idToken': idToken,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      displayName: json['displayName'],
      email: json['email'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: DateTime.parse(json['expiresAt']),
      idToken: json['idToken'],
    );
  }
} 