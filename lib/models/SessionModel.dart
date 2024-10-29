class SessionModel {
  final String uid;
  final String? email;
  final String? role;
  final String? loginTimestamp;
  final String? loginDevice;
  final bool isLogin;

  SessionModel({
    required this.uid,
    this.email,
    this.role,
    this.loginTimestamp,
    this.loginDevice,
    this.isLogin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'loginTimestamp': loginTimestamp,
      'loginDevice': loginDevice,
      'isLogin': isLogin,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      uid: map['uid'] ?? '',
      email: map['email'],
      role: map['role'],
      loginTimestamp: map['loginTimestamp'],
      loginDevice: map['loginDevice'],
      isLogin: map['isLogin'] ?? false,
    );
  }
}
