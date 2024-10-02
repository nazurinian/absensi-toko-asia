import 'dart:async';

import 'package:flutter/material.dart';
import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/api/AuthService.dart';
import 'package:absensitoko/api/FirestoreService.dart';
import 'package:absensitoko/api/SessionService.dart';
import 'package:absensitoko/models/SessionModel.dart';
import 'package:absensitoko/models/UserModel.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

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
      String email,
      String password,
      String dateTime,
      ) async {
    _isLoading = true;
    _status = null;
    _message = null;

    final response =
    await _authService.loginUser(email, password, dateTime).timeout(
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
      await _firestoreService.updateUserProfileData(_currentUser!.uid,
          loginTimestamp: dateTime);
    } else {
      _userDataIsLoaded = false;
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  Future<ApiResult> registerUser(
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
  }

  Future<ApiResult> signOut() async {
    final response = await _authService.signOut();

    _status = response.status;
    _message = response.message;

    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
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

  /// FireStore Service Provider
  Future<ApiResult> getUser(String uid) async {
    _isLoading = true;
    _status = null;
    _message = null;

    final response = await _firestoreService.getUser(uid);

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

  Future<ApiResult> getAllUsers() async {
    _isLoading = true;
    _status = null;
    _message = null;

    final response = await _firestoreService.getAllUsers();

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

  Future<ApiResult> updateUserProfile(
      String uid, {
        String? city,
        String? displayName,
        String? institution,
        String? phoneNumber,
        String? role,
        String? photoURL,
        String? loginTimestamp,
        String? logoutTimestamp,
        bool roleUpdated = false,
        bool logout = false,
      }) async {
    if(!logout) {
      _isLoading = true;
      _status = null;
      _message = null;
    }

    final updateFirestoreProfile = await _firestoreService
        .updateUserProfileData(
      uid,
      city: city,
      displayName: displayName,
      institution: institution,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
      role: role,
      loginTimestamp: loginTimestamp,
      logoutTimestamp: logoutTimestamp,
    )
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _message = 'Update profile operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    if (updateFirestoreProfile.status == 'error') {
      _status = updateFirestoreProfile.status;
      _message = updateFirestoreProfile.message;
      _isLoading = false;
      notifyListeners();
      return ApiResult(status: _status ?? '', message: _message ?? '');
    }

    /// Ini buat update Profil Utama(if Atas) atau Updater Role(else Bawah)
    /// Sedangkan jika logout = true, maka if ini akan dilewati
    if(!logout) {
      /// Ini Update Profil Utama
      if (roleUpdated == false) {
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

        final response = await _firestoreService.getUser(uid);

        _status = response.status;
        _message = response.message;
        if (response.status == 'success') {
          _currentUser = response.data;
        }

        /// Ini Update Profil Akun Lain
      } else {
        final response = await _firestoreService.getAllUsers();

        _status = response.status;
        _message = response.message;
        if (response.status == 'success') {
          _listAllUser = response.data;
        }
      }
    } else {
      _status = updateFirestoreProfile.status;
      _message = updateFirestoreProfile.message;
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
}
