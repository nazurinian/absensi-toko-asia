import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:absensitoko/api/api_result.dart';
import 'package:absensitoko/api/services/firestore_service.dart';
import 'package:absensitoko/api/session_service.dart';
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
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final response = await _fireStoreService.getUser(firebaseUser.uid);

        if (response.status == 'success') {
          UserModel? user = response.data;
          String message = 'Login berhasil';

          if (user == null) {
            user = UserModel(
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

            final saveResponse = await _fireStoreService.saveUser(user);
            if (saveResponse.status == 'error') {
              return ApiResult(
                  status: 'error', message: 'Login pertama anda gagal');
            } else {
              message = 'Login pertama anda berhasil';
            }
          } else {
            user.loginTimestamp = dateTime;
            user.loginLat = loginLocation.latitude.toString();
            user.loginLong = loginLocation.longitude.toString();

            if (user.loginDevice!.isNotEmpty) {
              final result = await DialogUtils.showConfirmationDialog(
                context: context,
                title: 'Konfirmasi Login',
                content: Text(
                  'Anda telah login di perangkat lain sebelumnya, Lanjutkan login?',
                  textAlign: TextAlign.justify,
                ),
              );

              if (!result!) {
                await _auth.signOut();
                message = 'Gagal login diperangkat ini! \nAnda telah login di perangkat lain';
              } else {
                user.loginDevice = loginDevice;
                final saveResponse = await _fireStoreService.updateUser(user);
                if (saveResponse.status == 'success') {
                  message = 'Login diperangkat baru berhasil';
                  return ApiResult(
                      status: 'success', message: message, data: user);
                }
                message = 'Login diperangkat baru gagal';
              }
              return ApiResult(status: 'error', message: message);
            } else {
              user.loginDevice = loginDevice;
              final saveResponse = await _fireStoreService.updateUser(user);
              if (saveResponse.status == 'error') {
                return ApiResult(status: 'error', message: 'Login gagal');
              } else {
                message = 'Login berhasil';
              }
            }
          }
          return ApiResult(status: 'success', message: message, data: user);
        } else {
          return ApiResult(status: 'error', message: response.message);
        }
      } else {
        return ApiResult(status: 'error', message: 'User tidak ditemukan');
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      String errorMessage = FirebaseAuthErrorHelper.getErrorMessage(e);
      return ApiResult(status: 'error', message: errorMessage);
    } catch (e) {
      print('Login error: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  Future<ApiResult> signOut(UserModel user) async {
    // 1. Update status login di Firestore
    try {
      final saveResponse = await _fireStoreService.updateUser(user);
      if (saveResponse.status == 'error') {
        return ApiResult(
            status: 'error',
            message: 'Gagal memperbarui status login di Firestore');
      }
    } catch (e) {
      print('Error memperbarui status login di Firestore: $e');
    }

    // 2. Hapus session di perangkat lokal
    try {
      await SessionService.clearSession();
      print('Session berhasil dihapus dari perangkat lokal');
    } catch (e) {
      print('Error menghapus session di perangkat lokal: $e');
    }

    // 3. Logout dari sistem autentikasi
    try {
      await _auth.signOut();
      print('Logout dari sistem autentikasi berhasil');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      String errorMessage = FirebaseAuthErrorHelper.getErrorMessage(e);
      return ApiResult(status: 'error', message: errorMessage);
    } catch (e) {
      print('Sign out error: $e');
      return ApiResult(status: 'error', message: e.toString());
    }

    return ApiResult(status: 'success', message: 'Logout success');
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

      if (user != null) {
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }

        // if (phoneNumber != null) {
        //   await user.updatePhoneNumber(PhoneAuthProvider.credential(
        //     verificationId: verificationId ?? '', // Verification ID from Firebase Phone Authentication
        //     smsCode: smsCode ?? '', // SMS code from Firebase Phone Authentication
        //   ));
        // }

        // Reload user to get the latest updates
        await user.reload();
        return ApiResult(
            status: 'success', message: 'Berhasil memperbarui data auth user');
      } else {
        return ApiResult(status: 'error', message: 'User tidak ditemukan');
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      String errorMessage = FirebaseAuthErrorHelper.getErrorMessage(e);
      return ApiResult(status: 'error', message: errorMessage);
    } catch (e) {
      print('Update user auth data error: $e');
      return ApiResult(status: 'error', message: e.toString());
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
}