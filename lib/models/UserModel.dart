import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String uid;
  String? email;
  String? displayName;
  String? phoneNumber;
  String? city;
  String? institution;
  String? role;
  String? photoURL;
  String? firstTimeLogin;
  String? loginTimestamp;
  String? logoutTimestamp;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.city,
    this.institution,
    this.role,
    this.photoURL,
    this.firstTimeLogin,
    this.loginTimestamp,
    this.logoutTimestamp,
  });

  factory UserModel.fromFirebaseUser(
    User user, {
    String? role,
    String? phoneNumber,
    String? city,
    String? institution,
    bool? isLogin,
    String? firstTimeLogin,
    String? loginTimestamp,
    String? logoutTimestamp,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      phoneNumber: phoneNumber,
      city: city,
      institution: institution,
      role: role,
      photoURL: user.photoURL,
      firstTimeLogin: firstTimeLogin,
      loginTimestamp: loginTimestamp,
      logoutTimestamp: logoutTimestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'city': city,
      'institution': institution,
      'role': role,
      'photoURL': photoURL,
      'firstTimeLogin': firstTimeLogin,
      'loginTimestamp': loginTimestamp,
      'logoutTimestamp': logoutTimestamp,
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
      phoneNumber: map['phoneNumber'],
      city: map['city'],
      institution: map['institution'],
      role: map['role'],
      photoURL: map['photoURL'],
      firstTimeLogin: map['firstTimeLogin'],
      loginTimestamp: map['loginTimestamp'],
      logoutTimestamp: map['logoutTimestamp'],
    );
  }
}
