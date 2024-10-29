import 'package:absensitoko/models/SessionModel.dart';
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
}
