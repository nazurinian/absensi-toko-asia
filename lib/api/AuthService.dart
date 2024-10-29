import 'package:absensitoko/themes/colors/Colors.dart';
import 'package:absensitoko/utils/DialogUtils.dart';
import 'package:absensitoko/utils/DisplaySize.dart';
import 'package:absensitoko/utils/LoadingDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/api/FirestoreService.dart';
import 'package:absensitoko/api/SessionService.dart';
import 'package:absensitoko/models/SessionModel.dart';
import 'package:absensitoko/models/UserModel.dart';
import 'package:absensitoko/utils/FirebaseAuthErrorHelper.dart';
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
              // city: '',
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

            print('user anjing: ${user.loginDevice.toString()}');

            if (user.loginDevice!.isNotEmpty) {
              print('user babi: ${user.toString()}');

              final result = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Konfirmasi Login'),
                    content: const Text(
                        'Anda telah login di perangkat lain sebelumnya, tetap login?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: Text('Tidak'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'confirm'),
                        child: Text('Ya'),
                      ),
                    ],
                  );
                },
              );

              if (result == 'cancel') {
                await _auth.signOut();
                message = 'Anda telah login di perangkat lain';
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
              print('user setan: ${user.toString()}');
              user.loginDevice = loginDevice;
              final saveResponse = await _fireStoreService.updateUser(user);
              if (saveResponse.status == 'error') {
                return ApiResult(status: 'error', message: 'Login gagal');
              } else {
                message = 'Login berhasil';
              }
            }
          }

          // SessionModel userSession = SessionModel(
          //   uid: firebaseUser.uid,
          //   email: firebaseUser.email ?? '',
          //   role: user.role ?? '',
          //   loginTimestamp: dateTime,
          //   loginDevice: loginDevice,
          //   isLogin: true,
          // );
          // await SessionService.saveSession(userSession);

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
      // throw 'Email atau Password salah atau tidak ditemukan';
    } catch (e) {
      print('Login error: $e');
      return ApiResult(status: 'error', message: e.toString());
      // throw 'Terjadi kesalahan, silakan coba lagi.';
    }
  }

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

/*  Future<ApiResult> signOut(UserModel user) async {
    try {
      final saveResponse = await _firestoreService.updateUser(user);
      if (saveResponse.status == 'error') {
        return ApiResult(
            status: 'error', message: 'Login gagal');
      }
      await SessionService.clearSession();
      await _auth.signOut();
      return ApiResult(status: 'success', message: 'Logout success');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      String errorMessage = FirebaseAuthErrorHelper.getErrorMessage(e);
      return ApiResult(status: 'error', message: errorMessage);
    } catch (e) {
      print('Sign out error: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }*/

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

  Future<ApiResult<dynamic>> sendPasswordResetEmail(
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
  }
}
