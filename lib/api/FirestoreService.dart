import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/models/UserModel.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<ApiResult<dynamic>> saveUser(UserModel user) async {
    final dataToSave = user.toMap()..removeWhere((key, value) => value == null);
    try {
      await _db.collection('users').doc(user.uid).set(dataToSave);
      return ApiResult(
          status: 'success', message: 'Berhasil menyimpan data awal user');
    } catch (e) {
      print('Error saving user first data: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  Future<ApiResult<dynamic>> updateUser(UserModel user) async {
    final dataToSave = user.toMap()..removeWhere((key, value) => value == null);

    try {
      await _db.collection('users').doc(user.uid).update(dataToSave);
      return ApiResult(
          status: 'success',
          message: 'Berhasil mengupdate data user'
      );
    } catch (e) {
      print('Error updating user data: $e');
      return ApiResult(
          status: 'error',
          message: 'Gagal mengupdate data user: ${e.toString()}'
      );
    }
  }

  Future<ApiResult<dynamic>> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        UserModel? user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        return ApiResult(
          status: 'success',
          message: 'Berhasil memperoleh data user',
          data: user,
        );
      }
      return ApiResult(
          status: 'success', message: 'User belum terdaftar', data: null);
    } catch (e) {
      print('Error getting user: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  Future<ApiResult<dynamic>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('users').get();

      if (querySnapshot.size == 0 || querySnapshot.docs.isEmpty) {
        print('No users found.');
        return ApiResult(status: 'error', message: 'No users found', data: []);
      }
      List<UserModel> users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      return ApiResult(
        status: 'success',
        message: 'Berhasil memperoleh list user',
        data: users,
      );
    } catch (e) {
      print('Error getting list of users: $e');
      return ApiResult(status: 'error', message: e.toString(), data: []);
    }
  }

  Future<ApiResult<dynamic>> updateUserProfileData(
      String uid, {
        String? city,
        String? displayName,
        String? department,
        String? phoneNumber,
        String? role,
        String? photoURL,
        // String? loginTimestamp,
        // String? logoutTimestamp,
      }) async {
    try {
      Map<String, dynamic> data = {};
      if (city != null) data['city'] = city;
      if (displayName != null) data['displayName'] = displayName;
      if (department != null) data['department'] = department;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (role != null) data['role'] = role;
      if (photoURL != null) data['photoURL'] = photoURL;
      // if (loginTimestamp != null) data['loginTimestamp'] = loginTimestamp;
      // if (logoutTimestamp != null) data['logoutTimestamp'] = logoutTimestamp;

      await _db.collection('users').doc(uid).update(data);
      return ApiResult(
          status: 'success', message: 'Berhasil memperbarui profil user');
    } catch (e) {
      print('Error updating user profile: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }
}
