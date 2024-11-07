import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:absensitoko/api/api_result.dart';
import 'package:absensitoko/api/services/firestore_service.dart';
import 'package:absensitoko/api/services/session_service.dart';
import 'package:absensitoko/data/models/user_model.dart';
import 'package:absensitoko/utils/helpers/firebase_auth_error_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fireStoreService = FirestoreService();

  Future<ApiResult<dynamic>> loginUser(
    BuildContext context,
    String email,
    String password,
    String dateTime,
    String loginDevice,
    LatLng loginLocation,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return ApiResult(status: 'error', message: 'User tidak ditemukan');
      }

      if(context.mounted) {
        return await _processLogin(
            firebaseUser, context, dateTime, loginDevice, loginLocation);
      } else {
        return ApiResult(status: 'error', message: 'Context tidak ditemukan');
      }
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e);
    } catch (e) {
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  Future<ApiResult<dynamic>> _processLogin(
    User firebaseUser,
    BuildContext context,
    String dateTime,
    String loginDevice,
    LatLng loginLocation,
  ) async {
    final response = await _fireStoreService.getUser(firebaseUser.uid);
    String message = response.data == null ? 'Login pertama anda berhasil' : 'Login berhasil';

    if (response.status != 'success') {
      message = response.data == null ? 'Login pertama anda gagal' : 'Login gagal';
      return ApiResult(status: 'error', message: response.message);
    }

    UserModel? user = response.data ??
        _initializeNewUser(firebaseUser, dateTime, loginDevice, loginLocation);

    if (user != null) {
      user.loginTimestamp = dateTime;
      user.loginLat = loginLocation.latitude.toString();
      user.loginLong = loginLocation.longitude.toString();
    }

    if (user!.loginDevice!.isNotEmpty && context.mounted) {
      final confirmed = await _confirmLogin(context);
      if (!confirmed) {
        await _auth.signOut();
        return ApiResult(
          status: 'error',
          message:
              'Gagal login diperangkat ini! \nAnda telah login di perangkat lain',
        );
      }
    }

    user.loginDevice = loginDevice;
    final saveResponse = response.data == null
        ? await _fireStoreService.saveUser(user)
        : await _fireStoreService.updateUser(user);

    if (saveResponse.status == 'error') {
      return ApiResult(status: 'error', message: message);
    }

    if (response.data == null) {
      return ApiResult(status: 'success', message: message);
    }

    return ApiResult(status: 'success', message: message, data: user);
  }

  UserModel _initializeNewUser(User firebaseUser, String dateTime,
      String loginDevice, LatLng loginLocation) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      phoneNumber: firebaseUser.phoneNumber ?? '',
      department: '',
      role: 'other',
      photoURL: firebaseUser.photoURL ?? '',
      firstTimeLogin: dateTime,
      loginTimestamp: dateTime,
      logoutTimestamp: '',
      loginDevice: loginDevice,
      loginLat: loginLocation.latitude.toString(),
      loginLong: loginLocation.longitude.toString(),
    );
  }

  Future<bool> _confirmLogin(BuildContext context) async {
    return await DialogUtils.showConfirmationDialog(
          context: context,
          title: 'Konfirmasi Login',
          content: const Text(
            'Anda telah login di perangkat lain sebelumnya, Lanjutkan login?',
            textAlign: TextAlign.justify,
          ),
        ) ??
        false;
  }

  Future<ApiResult> signOut(UserModel user, bool sessionExpired) async {
    // 1. Update status login di Firestore kalau memang maish login jika tidak (sesi logout habis maka tidak perlu memperbarui status login difirestore)
    if (!sessionExpired) {
      final saveResponse = await _fireStoreService.updateUser(user);
      if (saveResponse.status == 'error') {
        return ApiResult(
          status: 'error',
          message: 'Gagal memperbarui status login di Firestore',
        );
      }
    }

    // 2. Hapus session di perangkat lokal
    await _clearSession();

    // 3. Logout dari sistem autentikasi
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e);
    } catch (e) {
      return ApiResult(status: 'error', message: e.toString());
    }

    return ApiResult(status: 'success', message: 'Logout success');
  }

  Future<void> _clearSession() async {
    await SessionService.clearSession();
  }

  ApiResult _handleFirebaseAuthError(FirebaseAuthException e) {
    String errorMessage = FirebaseAuthErrorHelper.getErrorMessage(e);
    return ApiResult(status: 'error', message: errorMessage);
  }

  Future<ApiResult<dynamic>> updateUserAuthData({
    String? photoURL,
    String? displayName,
    String? phoneNumber,
    String? verificationId,
    String? smsCode,
  }) async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        return ApiResult(status: 'error', message: 'User tidak ditemukan');
      }

      await _updateUserProfile(
          user, photoURL, displayName, phoneNumber, verificationId, smsCode);
      return ApiResult(
          status: 'success', message: 'Berhasil memperbarui data auth user');
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e);
    } catch (e) {
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  Future<void> _updateUserProfile(
      User user,
      String? photoURL,
      String? displayName,
      String? phoneNumber,
      String? verificationId,
      String? smsCode) async {
    if (photoURL != null) await user.updatePhotoURL(photoURL);
    if (displayName != null) await user.updateDisplayName(displayName);

    // if (phoneNumber != null) {
    //   await user.updatePhoneNumber(PhoneAuthProvider.credential(
    //     verificationId: verificationId ?? '', // Verification ID from Firebase Phone Authentication
    //     smsCode: smsCode ?? '', // SMS code from Firebase Phone Authentication
    //   ));
    // }

    await user.reload();
  }
}

// Reset Password Function
/*  Future<ApiResult<dynamic>> sendPasswordResetEmail(
    String email,
  ) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return ApiResult(
          status: 'success',
          message:
              'Permintaan reset password $email berhasil, silakan cek email anda');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      String errorMessage = FirebaseAuthErrorHelper.getErrorMessage(e);
      return ApiResult(status: 'error', message: errorMessage);
    } catch (e) {
      print('Login error: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }*/

// Register User Function
/*  Future<ApiResult<dynamic>> registerUser(
    String email,
    String password,
    String dateTime,
  ) async {
    try {
      UserCredential userCredentialRegister =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = userCredentialRegister.user;

      if (firebaseUser != null) {
        UserModel user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: '',
          phoneNumber: '',
          // city: '',
          department: '',
          role: 'other',
          photoURL: firebaseUser.photoURL ?? '',
          firstTimeLogin: dateTime,
          loginTimestamp: '',
          logoutTimestamp: '',
        );

        final response = await _firestoreService.saveUser(user);

        if (response.status == 'success') {
          return ApiResult(
              status: 'success', message: 'Berhasil membuat akun baru');
        } else {
          return ApiResult(
              status: 'error', message: 'Gagal menyimpan data akun baru');
        }
      } else {
        return ApiResult(status: 'error', message: 'Gagal membuat akun baru');
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      String errorMessage = FirebaseAuthErrorHelper.getErrorMessage(e);
      return ApiResult(status: 'error', message: errorMessage);
    } catch (e) {
      print('Registration error: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }*/