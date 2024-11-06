import 'package:absensitoko/data/models/session_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static Future<SessionModel?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final email = prefs.getString('email');
    final role = prefs.getString('role');
    final loginTimestamp = prefs.getString('loginTimestamp');
    final loginDevice = prefs.getString('loginDevice');
    final isLogin = prefs.getBool('isLogin') ?? false;

    if (uid != null) {
      return SessionModel(
        uid: uid,
        email: email,
        role: role,
        loginTimestamp: loginTimestamp,
        loginDevice: loginDevice,
        isLogin: isLogin,
      );
    }
    return null;
  }

  static Future<void> saveSession(SessionModel session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', session.uid);
    await prefs.setString('email', session.email ?? '');
    await prefs.setString('role', session.role ?? '');
    await prefs.setString('loginTimestamp', session.loginTimestamp ?? '');
    await prefs.setString('loginDevice', session.loginDevice ?? '');
    await prefs.setBool('isLogin', session.isLogin);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await prefs.remove('email');
    await prefs.remove('role');
    await prefs.remove('loginTimestamp');
    await prefs.remove('loginDevice');
    await prefs.setBool('isLogin', false);
  }

  // Ini untuk mengeluarkan akun dari device lain (logout) satu akun satu device aja yg boleh login
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('deviceId');
    return deviceId ?? '';
  }

  static Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deviceId', deviceId);
  }

  // Ini untuk mengakali update otomatis dan init data diawal
  static Future<String> loadLastDate() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastDate = prefs.getString('lastDate');
    return lastDate ?? '';
  }

  static Future<void> saveLastDate(String lastDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastDate', lastDate);
  }

  static Future<void> clearLastDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastDate');
  }

  // Gak usah diclear sih karena device id itu unik
  // static Future<void> clearDeviceId() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('deviceId');
  // }
}
