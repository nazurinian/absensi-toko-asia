import 'package:absensitoko/data/models/version_model.dart';
import 'package:absensitoko/data/models/attendance_info_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:absensitoko/api/api_result.dart';
import 'package:absensitoko/data/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------- USER ------------------------------------
  // Ini fungsi untuk menyimpan data user pertama kali
  Future<ApiResult> saveUser(UserModel user) async {
    final dataToSave = user.toMap()..removeWhere((key, value) => value == null);
    try {
      await _db.collection('users').doc(user.uid).set(dataToSave);
      return ApiResult(
          status: 'success', message: 'Berhasil menyimpan data awal user');
    } catch (e) {
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  // Ini update untuk kebutuhan logout
  Future<ApiResult> updateUser(UserModel user) async {
    final dataToSave = user.toMap()..removeWhere((key, value) => value == null);

    try {
      await _db.collection('users').doc(user.uid).update(dataToSave);
      return ApiResult(
          status: 'success', message: 'Berhasil mengupdate data user');
    } catch (e) {
      return ApiResult(
          status: 'error',
          message: 'Gagal mengupdate data user: ${e.toString()}');
    }
  }

  // Ini fungsi penting untuk mendapatkan data user
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
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  // Saat ini, fungsi ini untuk cek nama yg sama aja
  Future<ApiResult<dynamic>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('users').get();

      if (querySnapshot.size == 0 || querySnapshot.docs.isEmpty) {
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
      return ApiResult(status: 'error', message: e.toString(), data: []);
    }
  }

  // Ini update untuk kebutuhan data secara spesifik
  Future<ApiResult<dynamic>> updateUserProfileData(
    String uid, {
    String? displayName,
    String? department,
    String? phoneNumber,
    String? role,
    String? photoURL,
  }) async {
    try {
      Map<String, dynamic> data = {};
      if (displayName != null) data['displayName'] = displayName;
      if (department != null) data['department'] = department;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (role != null) data['role'] = role;
      if (photoURL != null) data['photoURL'] = photoURL;

      await _db.collection('users').doc(uid).update(data);
      return ApiResult(
          status: 'success', message: 'Berhasil memperbarui profil user');
    } catch (e) {
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  // ---------------------------- DATA ------------------------------------

  // Fungsi untuk mendapatkan data attendance
  Future<ApiResult<AttendanceInfoModel>> getAttendanceInfo() async {
    try {
      DocumentSnapshot doc =
          await _db.collection('attendance').doc('information').get();
      if (doc.exists) {
        AttendanceInfoModel data =
            AttendanceInfoModel.fromMap(doc.data() as Map<String, dynamic>);
        return ApiResult(
          status: 'success',
          message: 'Berhasil memperoleh data attendance',
          data: data,
        );
      }
      return ApiResult(
        status: 'success',
        message: 'Data attendance belum tersedia',
        data: AttendanceInfoModel(
            breakTime: 'Data belum tersedia',
            nationalHoliday: 'Tidak ada libur'),
      );
    } catch (e) {
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  // Fungsi untuk memperbarui data attendance
  Future<ApiResult> updateAttendanceInfo(AttendanceInfoModel data) async {
    try {
      final Map<String, dynamic> updateData = data.toMap();

      await _db.collection('attendance').doc('information').update(updateData);
      return ApiResult(
        status: 'success',
        message: 'Berhasil memperbarui data attendance',
      );
    } catch (e) {
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  Future<ApiResult<AppVersionModel>> getAppVersion() async {
    final snapshot = await _db.collection('information').doc('latest_version').get();
    if (snapshot.exists) {
      AppVersionModel data = AppVersionModel.fromMap(snapshot.data() as Map<String, dynamic>);
      return ApiResult(status: 'success', message: 'Berhasil memperoleh data versi aplikasi', data: data);
      // return AppVersionModel.fromDocument(snapshot);
    }
    return ApiResult(status: 'error', message: 'Data versi aplikasi belum tersedia');
  }

  Future<void> updateAppVersion(AppVersionModel appVersion) async {
    await _db.collection('information').doc('latest_version').set(appVersion.toMap());
  }
}

// (GAK JADI PAKE FIRESTORE, GANTI PAKE RTDB) Fungsi untuk mendapatkan data history
/*  // Fungsi untuk menginisialisasi data history
  Future<ApiResult<dynamic>> initializeHistory(
    String userName,
    String date,
  ) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYYMM
    String tanggal = date.substring(8); // Ambil tanggal
    try {
      final initialData =
          HistoryData().toMap(); // Sesuaikan dengan struktur data

      final checkDoc = await _db
          .collection('history')
          .doc(userName)
          .collection(tahunBulan)
          .doc(tanggal)
          .get();

      if (!checkDoc.exists) {
        await _db
            .collection('history')
            .doc(userName)
            .collection(tahunBulan)
            .doc(tanggal)
            .set({});
      } else {
        print('Data sudah ada');
      }

      return ApiResult(
          status: 'success',
          message:
              'Inisialisasi data history berhasil untuk pengguna: $userName');
    } catch (e) {
      print('Error initializing history: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  // Fungsi untuk mendapatkan data history user berdasarkan tanggal tertentu
  Future<ApiResult<dynamic>> getHistoryForUserByDate(
      String userName, String date) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYYMM
    String tanggal = date.substring(8); // Ambil tanggal
    try {
      final doc = await _db
          .collection('history')
          .doc(userName)
          .collection(tahunBulan)
          .doc(tanggal)
          .get();

      if (doc.exists) {
        return ApiResult(
          status: 'success',
          message: 'Data history berhasil Diperoleh.',
          data: doc.data(),
        );
      } else {
        return ApiResult(status: 'error', message: 'Data tidak ditemukan.');
      }
    } catch (e) {
      print('Error getting history: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  // Fungsi untuk memperbarui data history user
  Future<ApiResult<dynamic>> updateHistory(
      String userName, String date, HistoryData data) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYYMM
    String tanggal = date.substring(8); // Ambil tanggal
    try {
      final updateData = data.toMap()
        ..removeWhere((key, value) => value == null); // Hapus field null

      await _db
          .collection('history')
          .doc(userName)
          .collection(tahunBulan)
          .doc(tanggal)
          .update(updateData);

      return ApiResult(
          status: 'success', message: 'Data history berhasil diperbarui.');
    } catch (e) {
      print('Error updating history: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  // Fungsi untuk mendapatkan semua history dari user tertentu
  Future<ApiResult<dynamic>> getAllHistoryForUser(
      String userName, String date) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYYMM
    try {
      final userHistoryCollection =
          _db.collection('history').doc(userName).collection(tahunBulan);

      final snapshot = await userHistoryCollection.get();

      if (snapshot.docs.isNotEmpty) {
        // Fungsi 3: Get All Data by User (Menggunakan Map)
        Map<String, HistoryData> allHistory = {};

        for (var doc in snapshot.docs) {
          // Ambil data dari setiap dokumen
          String dateKey = doc.id; // Kunci tanggal
          HistoryData historyData =
              HistoryData.fromMap(doc.data() as Map<String, dynamic>);

          allHistory[dateKey] =
              historyData; // Mengisi map dengan tanggal sebagai kunci
        }
        return ApiResult(
          status: 'success',
          data: allHistory,
        );

        // Fungsi 3: Get All Data by User (Menggunakan List - Jangan Hapus)
        // print(snapshot.docs.map((doc) => doc.data()).toList());
        // return ApiResult(
        //   status: 'success',
        //   data: snapshot.docs.map((doc) => doc.data()).toList(),
        // );
      } else {
        return ApiResult(
            status: 'error', message: 'Tidak ada history untuk user ini.');
      }
    } catch (e) {
      print('Error getting all history for user: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  Future<Map<String, Map<String, HistoryData>>> getAllHistory(
      String date) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYYMM

    try {
      final querySnapshot = await _db.collection('history').get();

      Map<String, Map<String, HistoryData>> allHistory = {};

      for (var userDoc in querySnapshot.docs) {
        String userName = userDoc.id; // Nama pengguna
        final userHistoryMap = <String, HistoryData>{};

        // Ambil semua koleksi bulan
        final monthSnapshot =
            await userDoc.reference.collection(tahunBulan).get();
        for (var monthDoc in monthSnapshot.docs) {
          String monthKey = monthDoc.id; // Kunci bulan
          HistoryData historyData =
              HistoryData.fromMap(monthDoc.data() as Map<String, dynamic>);
          userHistoryMap[monthKey] =
              historyData; // Mengisi map dengan bulan sebagai kunci
        }

        allHistory[userName] =
            userHistoryMap; // Mengisi map dengan nama pengguna
      }

      return allHistory;
    } catch (e) {
      print('Error getting all history: $e');
      return {};
    }
  }*/