import 'package:absensitoko/api/api_result.dart';
import 'package:absensitoko/data/models/history_model.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Fungsi untuk menginisialisasi data history
  Future<ApiResult> initializeHistory(
    String userName, HistoryData historyData,
  ) async {
    String date = historyData.tanggalCreate!;
    String tahunBulan = date.substring(0, 7); // Ambil YYYY-MM
    String tanggal = date.substring(8, 10); // Ambil tanggal DD
    final initialData = historyData.toMap();
    final checkRef = _db.child('history/$userName/$tahunBulan/$tanggal');

    try {
      final checkSnapshot = await checkRef.get();
      if (checkSnapshot.value == null) {
        await checkRef.set(initialData);
      } else {
        return ApiResult(
          status: 'success',
          message: 'Data history sudah ada untuk tanggal ini.',
        );
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
  Future<ApiResult<HistoryData>> getThisDayHistory(
    String userName,
    String date,
  ) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYY-MM
    String tanggal = date.substring(8, 10); // Ambil tanggal DD
    final ref = _db.child('history/$userName/$tahunBulan/$tanggal');
    final snapshot = await ref.get();

    try {
      if (snapshot.value != null) {
        final data = (snapshot.value as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key as String, value as dynamic),
        );

        final historyData = HistoryData.fromMap(data);

        return ApiResult(
          status: 'success',
          message: 'Data history berhasil diperoleh.',
          data: historyData,
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
  Future<ApiResult<HistoryData>> updateThisDayHistory(
    String userName,
    String date,
    HistoryData data,
  ) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYY-MM
    String tanggal = date.substring(8, 10); // Ambil tanggal DD
    final updateData = data.toMap()..removeWhere((key, value) => value == null || value == '');
    final ref = _db.child('history/$userName/$tahunBulan/$tanggal');

    try {
      await ref.update(updateData);

      final snapshot = await ref.get();
      final newData = (snapshot.value as Map<Object?, Object?>).map(
        (key, value) => MapEntry(key as String, value as dynamic),
      );
      final newHistoryData = HistoryData.fromMap(newData);

      print('update Data: ${data.toString()}');
      print('new Data: ${newData.toString()}');
      return ApiResult(
        status: 'success',
        message: 'Data history berhasil diperbarui.',
        data: newHistoryData,
      );
    } catch (e) {
      print('Error updating history: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

// Fungsi untuk mendapatkan semua history dari user tertentu
  Future<ApiResult<DailyHistory>> getAllDayHistory(
    String userName,
    String date,
  ) async {
    String tahunBulan = date.substring(0, 7); // Ambil YYYY-MM
    final ref = _db.child('history/$userName/$tahunBulan');

    try {
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

        final dayHistory = DailyHistory(historyData: historyList);

        return ApiResult(
          status: 'success',
          message: 'Seluruh data history harian anda bulan ini berhasil diperoleh.',
          data: dayHistory,
        );
      } else {
        return ApiResult(
          status: 'error',
          message: 'Data history harian user tidak ditemukan.',
        );
      }
    } catch (e) {
      print('Error getting all history for user: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

  Future<ApiResult<MonthlyHistory>> getAllMonthHistory(String userName) async {
    final ref = _db.child('history/$userName');

    try {
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return ApiResult(
          status: 'error',
          message: 'Data history bulanan user tidak ditemukan.',
        );
      }

      Map<String, DailyHistory> monthlyHistoryMap = {};

      // Iterasi untuk setiap bulan (tahunBulan)
      for (var monthSnapshot in snapshot.children) {
        String monthKey = monthSnapshot.key ?? ''; // contoh: '2024-10'

        Map<String, HistoryData> dayHistoryMap = {};

        // Iterasi untuk setiap hari dalam bulan
        for (var daySnapshot in monthSnapshot.children) {
          String dateKey = daySnapshot.key ?? ''; // contoh: '01' untuk tanggal 1

          // Memastikan daySnapshot.value adalah Map<String, dynamic>
          if (daySnapshot.value is Map) {
            try {
              // Konversi menjadi Map<String, dynamic> untuk HistoryData
              HistoryData historyData = HistoryData.fromMap(
                  Map<String, dynamic>.from(daySnapshot.value as Map));
              dayHistoryMap[dateKey] = historyData; // Isi dayHistoryMap dengan tanggal dan data
            } catch (e) {
              print('Data tidak valid untuk tanggal: $dateKey, tipe data: ${daySnapshot.value.runtimeType}, error: $e');
            }
          } else {
            print('Data tidak valid untuk tanggal: $dateKey, tipe data: ${daySnapshot.value.runtimeType}');
          }
        }

        // Buat objek DailyHistory dari dayHistoryMap
        final dailyHistory = DailyHistory(historyData: dayHistoryMap);
        monthlyHistoryMap[monthKey] = dailyHistory; // Tambahkan ke monthlyHistoryMap
      }

      // Buat objek MonthlyHistory dari monthlyHistoryMap
      final monthlyHistory = MonthlyHistory(dayHistory: monthlyHistoryMap);

      return ApiResult(
        status: 'success',
        message: 'Seluruh data history bulanan anda berhasil diperoleh.',
        data: monthlyHistory,
      );
    } catch (e) {
      print('Error getting all history: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }

// Fungsi untuk mendapatkan semua data history dari semua user
  Future<ApiResult<HistoryModel>>
      getAllHistoryCompletely() async {
    final ref = _db.child('history');

    try {
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return ApiResult(
          status: 'error',
          message: 'Data history tidak ditemukan.',
        );
      }

      // Map<String, Map<String, Map<String, HistoryData>>> allCompleteHistory = {};
      Map<String, MonthlyHistory> allUsersHistoryMap = {};

      // Loop melalui setiap pengguna
      for (var userSnapshot in snapshot.children) {
        String userName = userSnapshot.key ?? '';
        // final userCompleteHistoryMap = <String, Map<String, HistoryData>>{};
        final monthlyHistoryMap = <String, DailyHistory>{};

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

          // userCompleteHistoryMap[tahunBulan] = dateMap; // Masukkan ke map tahunBulan
          monthlyHistoryMap[tahunBulan] = DailyHistory(historyData: dateMap);
        }

        // allCompleteHistory[userName] = userCompleteHistoryMap; // Masukkan ke map nama pengguna
        allUsersHistoryMap[userName] = MonthlyHistory(dayHistory: monthlyHistoryMap);
      }

      return ApiResult(
        status: 'success',
        message: 'Seluruh data history berhasil diperoleh.',
        data: HistoryModel(allUsersHistory: allUsersHistoryMap),
      );
    } catch (e) {
      print('Error getting all complete history: $e');
      return ApiResult(status: 'error', message: e.toString());
    }
  }
}
