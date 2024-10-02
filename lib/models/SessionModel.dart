class SessionModel {
  final String uid;
  final String? email;
  final String? role;
  final String? loginTimestamp;
  final bool isLogin;

  SessionModel({
    required this.uid,
    this.email,
    this.role,
    this.loginTimestamp,
    this.isLogin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'loginTimestamp': loginTimestamp,
      'isLogin': isLogin,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      uid: map['uid'] ?? '',
      email: map['email'],
      role: map['role'],
      loginTimestamp: map['loginTimestamp'],
      isLogin: map['isLogin'] ?? false,
    );
  }
}
