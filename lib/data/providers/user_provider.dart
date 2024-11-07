import 'dart:async';
import 'package:absensitoko/locator.dart';
import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:absensitoko/api/api_result.dart';
import 'package:absensitoko/api/services/auth_service.dart';
import 'package:absensitoko/api/services/firestore_service.dart';
import 'package:absensitoko/api/services/session_service.dart';
import 'package:absensitoko/data/models/session_model.dart';
import 'package:absensitoko/data/models/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _fireStoreService = FirestoreService();
  final context = locator<GlobalKey<NavigatorState>>().currentContext;
  final Duration _timeoutDuration =
      const Duration(seconds: 5); // Defaultnya 5 detik + toleransi 5 detik

  SessionModel? _currentUserSession;
  UserModel? _currentUser;
  List<UserModel> _listAllUser = [];
  String? _deviceId;
  String? _lastDate;

  // bool _userDataIsLoaded = false;
  bool _listUserIsLoaded = false;
  bool _isLoading = false;
  String? _status;
  String? _message;

  SessionModel? get currentUserSession => _currentUserSession;

  UserModel? get currentUser => _currentUser;

  List<UserModel> get listAllUser => _listAllUser;

  String? get deviceID => _deviceId;

  String? get lastDate => _lastDate;

  // bool get userDataIsLoaded => _userDataIsLoaded;
  bool get userDataIsLoaded => _currentUser != null;

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
      _timeoutDuration,
      onTimeout: () async {
        if (context.mounted) {
          LoadingDialog.hide(context);
        }
        final FirebaseAuth auth = FirebaseAuth.instance;
        if (auth.currentUser != null) {
          await auth.signOut();
        }
        _isLoading = false;
        _message = 'Login operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _currentUser = response.data;
    } else {
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  Future<ApiResult> signOut(UserModel user, bool sessionExpired) async {
    final response = await _authService.signOut(user, sessionExpired).timeout(
      _timeoutDuration,
      onTimeout: () async {
        if (context != null) {
          LoadingDialog.hide(context!);
        }
        _message = 'Sign out operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    _status = response.status;
    _message = response.message;

    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  /// FireStore Service Provider
  /// Kalau di dataProvider ada sistem refresh
  Future<ApiResult> getUser(String uid, {bool isRefresh = false}) async {
    _isLoading = true;
    _status = null;
    _message = null;

    var previousData = _currentUser;

    final response = await _fireStoreService.getUser(uid).timeout(
      _timeoutDuration,
      onTimeout: () async {
        _isLoading = false;
        _message = 'Get user data operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _currentUser = response.data;
    } else {
      if (isRefresh) {
        _message = 'Gagal memperbarui data user';
        _currentUser = previousData;
      } else {
        _currentUser = null;
      }
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
      _timeoutDuration,
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

  /// Session Service Provider
  Future<void> loadUserSession() async {
    _currentUserSession = await SessionService.getSession();
    _deviceId = await SessionService.getDeviceId();

    notifyListeners();
  }

  Future<void> saveSession(SessionModel user, deviceId) async {
    await SessionService.saveSession(user);
    _currentUserSession = await SessionService.getSession();

    await SessionService.saveDeviceId(deviceId);
    notifyListeners();
  }

  Future<void> loadLastDate() async {
    _lastDate = await SessionService.loadLastDate();
    notifyListeners();
  }

  Future<void> saveLastDate(String lastDate) async {
    await SessionService.saveLastDate(lastDate);
    notifyListeners();
  }

  Future<void> clearLastDate() async {
    await SessionService.clearLastDate();
    _lastDate = null;

    notifyListeners();
  }

  void clearAccountData() {
    _currentUserSession = null;
    _currentUser = null;
    _listAllUser = [];

    _isLoading = false;
    _listUserIsLoaded = false;
    _status = null;
    _message = null;

    notifyListeners();
  }
}

// Reset Password Function
/*  Future<ApiResult> resetPassword(String email) async {
    _isLoading = true;
    _status = null;
    _message = null;

    final response = await _authService.sendPasswordResetEmail(email);

    _status = response.status;
    _message = response.message;

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }*/

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