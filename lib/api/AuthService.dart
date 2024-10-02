import 'package:firebase_auth/firebase_auth.dart';
import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/api/FirestoreService.dart';
import 'package:absensitoko/api/SessionService.dart';
import 'package:absensitoko/models/SessionModel.dart';
import 'package:absensitoko/models/UserModel.dart';
import 'package:absensitoko/utils/FirebaseAuthErrorHelper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<ApiResult<dynamic>> loginUser(
    String email,
    String password,
    String dateTime,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final response = await _firestoreService.getUser(firebaseUser.uid);

        if (response.status == 'success') {
          UserModel? user = response.data;
          String message = 'Login berhasil';

          if (user == null) {
            user = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName ?? '',
              phoneNumber: firebaseUser.phoneNumber ?? '',
              city: '',
              institution: '',
              role: 'other',
              photoURL: firebaseUser.photoURL ?? '',
              firstTimeLogin: dateTime,
              loginTimestamp: dateTime,
              logoutTimestamp: '',
            );

            final saveResponse = await _firestoreService.saveUser(user);
            if (saveResponse.status == 'error') {
              return ApiResult(
                  status: 'error', message: 'Login pertama anda gagal');
            } else {
              message = 'Login pertama anda berhasil';
            }
          }

          SessionModel userSession = SessionModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            role: user.role ?? '',
            loginTimestamp: dateTime,
            isLogin: true,
          );
          await SessionService.saveSession(userSession);

          return ApiResult(
            status: 'success',
            message: message,
            data: user,
          );
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

  Future<ApiResult<dynamic>> registerUser(
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
          city: '',
          institution: '',
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
  }

  Future<ApiResult> signOut() async {
    try {
      await _auth.signOut();
      await SessionService.clearSession();
      return ApiResult(status: 'success', message: 'Logout success');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      String errorMessage = FirebaseAuthErrorHelper.getErrorMessage(e);
      return ApiResult(status: 'error', message: errorMessage);
    } catch (e) {
      print('Sign out error: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
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
