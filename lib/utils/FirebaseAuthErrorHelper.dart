import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthErrorHelper {
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'wrong-password':
        return 'Password salah. Coba lagi.';
      case 'user-not-found':
        return 'Pengguna tidak ditemukan.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
      case 'email-already-in-use':
        return 'Email ini sudah digunakan oleh akun lain.';
      case 'operation-not-allowed':
        return 'Operasi ini tidak diizinkan. Hubungi administrator.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan password yang lebih kuat.';
      case 'account-exists-with-different-credential':
        return 'Akun ini sudah terdaftar dengan metode login berbeda.';
      case 'invalid-verification-code':
        return 'Kode verifikasi salah. Coba lagi.';
      case 'invalid-verification-id':
        return 'ID verifikasi tidak valid.';
      case 'credential-already-in-use':
        return 'Kredensial ini sudah digunakan oleh akun lain.';
      case 'requires-recent-login':
        return 'Silakan login kembali untuk melanjutkan.';
      case 'provider-already-linked':
        return 'Penyedia autentikasi sudah terhubung ke akun ini.';
      case 'invalid-credential':
        return 'Email atau password tidak valid.'; // Email atau password tidak valid
      case 'network-request-failed':
        return 'Permintaan jaringan gagal. Periksa koneksi internet Anda.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
