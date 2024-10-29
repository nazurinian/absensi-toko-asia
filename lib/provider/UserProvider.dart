import 'dart:async';

import 'package:flutter/material.dart';
import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/api/AuthService.dart';
import 'package:absensitoko/api/FirestoreService.dart';
import 'package:absensitoko/api/SessionService.dart';
import 'package:absensitoko/models/SessionModel.dart';
import 'package:absensitoko/models/UserModel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _fireStoreService = FirestoreService();

  SessionModel? _currentUserSession;
  UserModel? _currentUser;
  List<UserModel> _listAllUser = [];

  bool _isLoading = false;
  bool _userDataIsLoaded = false;
  bool _listUserIsLoaded = false;
  String? _status;
  String? _message;

  SessionModel? get currentUserSession => _currentUserSession;

  UserModel? get currentUser => _currentUser;

  List<UserModel> get listAllUser => _listAllUser;

  bool get userDataIsLoaded => _userDataIsLoaded;

  bool get listUserIsLoaded => _listUserIsLoaded;

  bool get isLoading => _isLoading;

  String? get status => _status;

  String? get message => _message;

  /// Auth Service Provider
  Future<ApiResult> loginUser(
    BuildContext context,
    String email,
    String password,
    String dateTime,
    String loginDevice,
    LatLng loginLocation,
  ) async {
    _isLoading = true;
    _status = null;
    _message = null;
    _userDataIsLoaded = false;

    final response = await _authService
        .loginUser(
      context,
      email,
      password,
      dateTime,
      loginDevice,
      loginLocation,
    )
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _message = 'Login operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _currentUser = response.data;
      _userDataIsLoaded = true;
    } else {
      _userDataIsLoaded = false;
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  Future<ApiResult> signOut(UserModel user) async {
    final response = await _authService.signOut(user);

    _status = response.status;
    _message = response.message;

    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  /// FireStore Service Provider
  Future<ApiResult> getUser(String uid) async {
    _isLoading = true;
    _status = null;
    _message = null;
    _userDataIsLoaded = false;

    final response = await _fireStoreService.getUser(uid);

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _currentUser = response.data;
      _userDataIsLoaded = true;
    } else {
      _userDataIsLoaded = false;
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  Future<ApiResult> updateUserProfile(
    String uid, {
    String? displayName,
    String? department,
    String? phoneNumber,
    String? role,
    String? photoURL,
    bool roleUpdated = false,
  }) async {
    _isLoading = true;
    _status = null;
    _message = null;

    // Update di firestore
    final updateFireStoreProfile = await _fireStoreService
        .updateUserProfileData(
      uid,
      displayName: displayName,
      department: department,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
      role: role,
    )
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _message = 'Update profile operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    if (updateFireStoreProfile.status == 'error') {
      _status = updateFireStoreProfile.status;
      _message = updateFireStoreProfile.message;
      _isLoading = false;
      notifyListeners();
      return ApiResult(status: _status ?? '', message: _message ?? '');
    }

    // Update di auth
    final updateAuthProfile = await _authService.updateUserAuthData(
      displayName: displayName,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
    );

    if (updateAuthProfile.status == 'error') {
      _status = updateAuthProfile.status;
      _message = updateAuthProfile.message;
      _isLoading = false;
      notifyListeners();
      return ApiResult(status: _status ?? '', message: _message ?? '');
    }

    // Load ulang data user
    final response = await _fireStoreService.getUser(uid);

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _currentUser = response.data;
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  /// Session Service Provider
  Future<void> loadUserSession() async {
    _currentUserSession = await SessionService.getSession();
    notifyListeners();
  }

  Future<void> saveSession(SessionModel user) async {
    await SessionService.saveSession(user);
    _currentUserSession = await SessionService.getSession();

    notifyListeners();
  }

  void clearAccountData() {
    _currentUserSession = null;
    _currentUser = null;
    _listAllUser = [];

    _isLoading = false;
    _userDataIsLoaded = false;
    _listUserIsLoaded = false;
    _status = null;
    _message = null;

    /// Notify nya di nonaktifkan karena ini hanya nge set ke null semua, ngga butuh respon perubahan
    // notifyListeners();
  }

  Future<ApiResult> resetPassword(String email) async {
    _isLoading = true;
    _status = null;
    _message = null;

    final response = await _authService.sendPasswordResetEmail(email);

    _status = response.status;
    _message = response.message;

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

// Get All Users Function (Saat ini baru digunakan untuk pencocokan nama user yang sudah saja)
  Future<ApiResult> getAllUsers() async {
    _isLoading = true;
    _status = null;
    _message = null;

    final response = await _fireStoreService.getAllUsers();

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _listAllUser = response.data;
      _listUserIsLoaded = true;
    } else {
      _listUserIsLoaded = false;
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

// Register User Function
/*  Future<ApiResult> registerUser(
      String email,
      String password,
      String dateTime,
      ) async {
    _isLoading = true;
    _status = null;
    _message = null;

    final response =
    await _authService.registerUser(email, password, dateTime).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _message = 'Register operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    _status = response.status;
    _message = response.message;

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }*/
}
