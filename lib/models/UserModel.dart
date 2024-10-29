import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String uid;
  String? email;
  String? displayName;
  String? photoURL;
  String? phoneNumber;
  String? department;
  String? role;
  String? firstTimeLogin;
  String? loginTimestamp;
  String? logoutTimestamp;
  String? loginDevice;
  String? loginLat;
  String? loginLong;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.department,
    this.role,
    this.firstTimeLogin,
    this.loginTimestamp,
    this.logoutTimestamp,
    this.loginDevice,
    this.loginLat,
    this.loginLong,
  });

  factory UserModel.fromFirebaseUser(
    User user, {
    String? phoneNumber,
    String? department,
    String? role,
    String? firstTimeLogin,
    String? loginTimestamp,
    String? logoutTimestamp,
    String? loginDevice,
    String? loginLat,
    String? loginLong,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      phoneNumber: phoneNumber,
      department: department,
      role: role,
      firstTimeLogin: firstTimeLogin,
      loginTimestamp: loginTimestamp,
      logoutTimestamp: logoutTimestamp,
      loginDevice: loginDevice,
      loginLat: loginLat,
      loginLong: loginLong,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'department': department,
      'role': role,
      'firstTimeLogin': firstTimeLogin,
      'loginTimestamp': loginTimestamp,
      'logoutTimestamp': logoutTimestamp,
      'loginDevice': loginDevice,
      'loginLat': loginLat,
      'loginLong': loginLong,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      phoneNumber: map['phoneNumber'],
      department: map['department'],
      role: map['role'],
      firstTimeLogin: map['firstTimeLogin'],
      loginTimestamp: map['loginTimestamp'],
      logoutTimestamp: map['logoutTimestamp'],
      loginDevice: map['loginDevice'],
      loginLat: map['loginLat'],
      loginLong: map['loginLong'],
    );
  }
}
