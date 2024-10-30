import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/models/HistoryModel.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Fungsi untuk menginisialisasi data history
  Future<ApiResult<dynamic>> initializeHistory(
      String userName, String date) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYY-MM
    String tanggal = date.substring(8); // Ambil tanggal
    try {
      final initialData = HistoryData().toMap();
      final checkRef = _db.child('history/$userName/$tahunBulan/$tanggal');

      final checkSnapshot = await checkRef.get();
      // final initialData = {
      //   'tanggal': '2024-10-30',
      //   'hari': 'Rabu',
      //   'tLPagi': '08:00',
      //   'hadirPagi': 'Ya',
      // };
      print(initialData.toString());
      if (checkSnapshot.value == null) {
        await checkRef.set(initialData);
      } else {
        print('Data sudah ada');
      }

      return ApiResult(
        status: 'success',
        message: 'Inisialisasi data history berhasil untuk pengguna: $userName',
      );
    } catch (e) {
      print('Error initializing history: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  // Fungsi untuk mendapatkan data history user berdasarkan tanggal tertentu
  Future<ApiResult<dynamic>> getHistoryForUserByDate(
      String userName, String date) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYY-MM
    String tanggal = date.substring(8); // Ambil tanggal
    try {
      final ref = _db.child('history/$userName/$tahunBulan/$tanggal');
      final snapshot = await ref.get();

      if (snapshot.value != null) {
        final data = (snapshot.value as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key as String, value as dynamic),
        );
        return ApiResult(
          status: 'success',
          message: 'Data history berhasil diperoleh.',
          data: data,
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
    String tahunBulan = date.substring(0, 7); // Ambil YYYY-MM
    String tanggal = date.substring(8); // Ambil tanggal
    try {
      final updateData = data.toMap()
        ..removeWhere((key, value) => value == null);

      final ref = _db.child('history/$userName/$tahunBulan/$tanggal');
      await ref.update(updateData);

      return ApiResult(
        status: 'success',
        message: 'Data history berhasil diperbarui.',
      );
    } catch (e) {
      print('Error updating history: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

// Fungsi untuk mendapatkan semua history dari user tertentu
  Future<ApiResult<dynamic>> getAllHistoryForUser(
      String userName, String date) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYY-MM
    try {
      final ref = _db.child('history/$userName/$tahunBulan');
      final snapshot = await ref.get();

      if (snapshot.value != null) {
        // Konversi snapshot.value ke Map<String, dynamic>
        Map<String, dynamic> allHistory =
            Map<String, dynamic>.from(snapshot.value as Map<Object?, Object?>);

        // Mengubah setiap entry di allHistory menjadi HistoryData
        final historyList = allHistory.map((key, value) {
          return MapEntry(
              key,
              HistoryData.fromMap(
                  Map<String, dynamic>.from(value as Map<Object?, Object?>)));
        });

        return ApiResult(
          status: 'success',
          data: historyList,
        );
      } else {
        return ApiResult(
          status: 'error',
          message: 'Tidak ada history untuk user ini.',
        );
      }
    } catch (e) {
      print('Error getting all history for user: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  Future<Map<String, Map<String, HistoryData>>> getAllHistory(
      String date) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYYMM
    DatabaseReference ref = FirebaseDatabase.instance.ref().child('history');

    try {
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return {};
      }

      Map<String, Map<String, HistoryData>> allHistory = {};

      for (var userSnapshot in snapshot.children) {
        String userName = userSnapshot.key ?? ''; // Nama pengguna
        final userHistoryMap = <String, HistoryData>{};

        // Akses child berdasarkan bulan yang diminta
        final monthSnapshot = userSnapshot.child(tahunBulan);
        if (monthSnapshot.exists) {
          for (var monthDoc in monthSnapshot.children) {
            String monthKey = monthDoc.key ?? ''; // Kunci bulan
            HistoryData historyData = HistoryData.fromMap(
                Map<String, dynamic>.from(monthDoc.value as Map));
            userHistoryMap[monthKey] =
                historyData; // Mengisi map dengan bulan sebagai kunci
          }
        }

        allHistory[userName] =
            userHistoryMap; // Mengisi map dengan nama pengguna
      }

      return allHistory;
    } catch (e) {
      print('Error getting all history: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, Map<String, HistoryData>>>>
      getAllHistoryCompletely() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child('history');

    try {
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return {};
      }

      Map<String, Map<String, Map<String, HistoryData>>> allCompleteHistory =
          {};

      // Loop melalui setiap pengguna
      for (var userSnapshot in snapshot.children) {
        String userName = userSnapshot.key ?? '';
        final userCompleteHistoryMap = <String, Map<String, HistoryData>>{};

        // Loop melalui setiap tahunBulan untuk pengguna ini
        for (var yearMonthSnapshot in userSnapshot.children) {
          String tahunBulan = yearMonthSnapshot.key ?? '';
          final dateMap = <String, HistoryData>{};

          // Loop melalui setiap tanggal di dalam tahunBulan ini
          for (var dateSnapshot in yearMonthSnapshot.children) {
            String date = dateSnapshot.key ?? '';
            HistoryData historyData = HistoryData.fromMap(
                Map<String, dynamic>.from(dateSnapshot.value as Map));
            dateMap[date] = historyData; // Masukkan ke map tanggal
          }

          userCompleteHistoryMap[tahunBulan] =
              dateMap; // Masukkan ke map tahunBulan
        }

        allCompleteHistory[userName] =
            userCompleteHistoryMap; // Masukkan ke map nama pengguna
      }

      return allCompleteHistory;
    } catch (e) {
      print('Error getting all complete history: $e');
      return {};
    }
  }

// Fungsi untuk mendapatkan semua data history dari semua user
/*  Future<Map<String, Map<String, Map<String, HistoryData>>>> getAllHistoryCompletely() async {
    try {
      final snapshot = await _db.child('history').once();
      Map<String, Map<String, Map<String, HistoryData>>> allCompleteHistory = {};

      if (snapshot.snapshot.value != null) {
        Map<String, dynamic> allData = Map<String, dynamic>.from(snapshot.value);
        allData.forEach((userName, userData) {
          Map<String, Map<String, HistoryData>> userCompleteHistoryMap = {};
          Map<String, dynamic>.from(userData).forEach((tahunBulan, dateData) {
            Map<String, HistoryData> dateMap = {};
            Map<String, dynamic>.from(dateData).forEach((tanggal, historyData) {
              dateMap[tanggal] = HistoryData.fromMap(Map<String, dynamic>.from(historyData));
            });
            userCompleteHistoryMap[tahunBulan] = dateMap;
          });
          allCompleteHistory[userName] = userCompleteHistoryMap;
        });
      }
      return allCompleteHistory;
    } catch (e) {
      print('Error getting all complete history: $e');
      return {};
    }
  }*/
}
