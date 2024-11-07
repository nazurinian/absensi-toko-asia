import 'package:absensitoko/api/api_result.dart';
import 'package:absensitoko/api/services/api_service.dart';
import 'package:absensitoko/api/services/firestore_service.dart';
import 'package:absensitoko/api/services/realtime_database_service.dart';
import 'package:absensitoko/data/models/version_model.dart';
import 'package:absensitoko/data/models/attendance_info_model.dart';
import 'package:absensitoko/data/models/attendance_model.dart';
import 'package:absensitoko/data/models/history_model.dart';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirestoreService _fireStoreService = FirestoreService();
  final RealtimeDatabaseService _realtimeDatabaseService =
      RealtimeDatabaseService();
  final Duration _timeoutDuration =
      const Duration(seconds: 5); // Defaultnya 5 detik + toleransi 5 detik

  // Data sheet
  Data _dataAbsensi = Data();

  // Data models
  HistoryData? _selectedDateHistory;
  DailyHistory? _userHistoryData;
  MonthlyHistory? _allUserHistoryData;
  HistoryModel? _allCompleteHistory;

  // Info models
  AttendanceInfoModel? _attendanceInfoData;
  AppVersionModel? _appVersion;

  bool _isLoading = false;
  String? _status;
  String? _message;

  Data? get dataAbsensi => _dataAbsensi;

  HistoryData? get selectedDateHistory => _selectedDateHistory;

  DailyHistory? get userHistoryData => _userHistoryData;

  MonthlyHistory? get allUserHistoryData => _allUserHistoryData;

  HistoryModel? get allCompleteHistory => _allCompleteHistory;

  AttendanceInfoModel? get attendanceInfoData => _attendanceInfoData;

  AppVersionModel? get appVersion => _appVersion;

  bool get isLoading => _isLoading;

  String? get status => _status;

  String? get message => _message;

  // Boolean flags to indicate data availability
  bool get isSelectedDateHistoryAvailable => _selectedDateHistory != null;

  bool get isUserHistoryDataAvailable => _userHistoryData != null;

  bool get isAllUserHistoryDataAvailable => _allUserHistoryData != null;

  bool get isAllCompleteHistoryAvailable => _allCompleteHistory != null;

  bool get isAttendanceInfoAvailable => _attendanceInfoData != null;

  bool get isAppVersionAvailable => _appVersion != null;

  // bool get statusAbsensi =>
  //     _selectedDateHistory?.tLPagi != null &&
  //     _selectedDateHistory?.tLSiang != null &&
  //     _selectedDateHistory!.tLPagi!.isNotEmpty &&
  //     _selectedDateHistory!.tLSiang!.isNotEmpty;

  bool get statusAbsensiPagi =>
      _selectedDateHistory?.tLPagi != null &&
      _selectedDateHistory!.tLPagi!.isNotEmpty;

  bool get statusAbsensiSiang =>
      _selectedDateHistory?.tLSiang != null &&
      _selectedDateHistory!.tLSiang!.isNotEmpty;

  // ---------------------------- DATA SHEET ------------------------------------
  Future<ApiResult> updateAttendance(String waktuAbsensi, Attendance attendance,
      {bool isRefresh = false}) async {
    resetLoadDataStatus();

    var previousData = _dataAbsensi;

    final response = await _apiService
        .updateAttendance(
      waktuAbsensi: waktuAbsensi,
      attendance: attendance,
    )
        .timeout(_timeoutDuration, onTimeout: () {
      _message = 'Update absensi operation timed out';
      return ApiResult(status: 'error', message: _message ?? '');
    });

    _status = response.status;
    _message = response.message;

    if (response.status == 'success') {
      _dataAbsensi = response.data as Data;
    } else {
      if (isRefresh) {
        _message = 'Gagal memperbarui data absensi';
        _dataAbsensi = previousData;
      } else {
        _dataAbsensi = Data();
      }
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // ---------------------------- DATA FIRE STORE ------------------------------------

  // Fungsi untuk mendapatkan data attendance
  Future<ApiResult> getAttendanceInfo({bool isRefresh = false}) async {
    resetLoadDataStatus();

    var previousData = _attendanceInfoData;

    final response = await _fireStoreService.getAttendanceInfo().timeout(
      _timeoutDuration,
      onTimeout: () {
        _message = 'Get attendance info operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    _status = response.status;
    _message = response.message;

    if (response.status == 'success') {
      _attendanceInfoData = response.data;
    } else {
      if (isRefresh) {
        _message = 'Gagal memperoleh informasi absensi';
        _attendanceInfoData = previousData;
      } else {
        _attendanceInfoData = null;
      }
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk memperbarui data attendance
  Future<ApiResult> updateAttendanceInfo(AttendanceInfoModel data) async {
    resetLoadDataStatus();

    final response = await _fireStoreService.updateAttendanceInfo(data).timeout(
      _timeoutDuration,
      onTimeout: () {
        _message = 'Update attendance info operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    _status = response.status;
    _message = response.message;

    // Tanpa response data langsung update by apps langsung
    if (response.status == 'success') {
      _attendanceInfoData = AttendanceInfoModel(
        breakTime: data.breakTime ?? _attendanceInfoData?.breakTime,
        nationalHoliday:
            data.nationalHoliday ?? _attendanceInfoData?.nationalHoliday,
      );
    } else {
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  Future<ApiResult> getAppVersion() async {
    final result = await _fireStoreService.getAppVersion().timeout(
      _timeoutDuration,
      onTimeout: () {
        _message = 'Get app version operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    if (result.status == 'success') {
      _appVersion = result.data;
    } else {
      _appVersion = null;
    }

    notifyListeners();
    return ApiResult(
        status: 'success',
        message: 'Berhasil memperoleh versi aplikasi',
        data: _appVersion);
  }

  // Fungsi set hanya ane yg bisa pake buat testing
  Future<void> updateAppVersion(AppVersionModel appVersion) async {
    await _fireStoreService.updateAppVersion(appVersion).timeout(
      _timeoutDuration,
      onTimeout: () {
        throw 'Update app version operation timed out';
      },
    );
    notifyListeners();
  }

  // ---------------------------- DATA RTDB ------------------------------------

  // Fungsi untuk inisialisasi data history
  Future<ApiResult> initializeHistory(String userName, HistoryData historyData,
      {bool isRefresh = false}) async {
    resetLoadDataStatus();

    final response = await _realtimeDatabaseService
        .initializeHistory(userName, historyData)
        .timeout(_timeoutDuration, onTimeout: () {
      _message = 'Initialize history operation timed out';
      return ApiResult(status: 'error', message: _message ?? '');
    });

    _status = response.status;
    _message = response.message;

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk mendapatkan history user berdasarkan tanggal tertentu
  Future<ApiResult> getThisDayHistory(String userName, String date,
      {bool isRefresh = false}) async {
    resetLoadDataStatus();

    // Simpan data lama untuk refresh
    var previousData = _selectedDateHistory;

    final response = await _realtimeDatabaseService
        .getThisDayHistory(userName, date)
        .timeout(_timeoutDuration, onTimeout: () {
      _message = 'Get this day history operation timed out';
      return ApiResult(status: 'error', message: _message ?? '');
    });

    _status = response.status;
    _message = response.message;

    if (response.status == 'success') {
      _selectedDateHistory = response.data;
    } else {
      // Jika ini adalah refresh, kembalikan data lama jika tidak ada data baru
      if (isRefresh) {
        _selectedDateHistory = previousData; // Mengembalikan data lama
      } else {
        _selectedDateHistory = null;
      }
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk memperbarui data history user
  Future<ApiResult> updateThisDayHistory(
      String userName, String date, HistoryData data) async {
    resetLoadDataStatus();

    final response = await _realtimeDatabaseService
        .updateThisDayHistory(userName, date, data)
        .timeout(_timeoutDuration, onTimeout: () {
      _message = 'Update this day history operation timed out';
      return ApiResult(status: 'error', message: _message ?? '');
    });

    _status = response.status;
    _message = response.message;

    if (response.status == 'success') {
      _selectedDateHistory = response.data;
    } else {
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk mendapatkan semua history dari user tertentu
  Future<ApiResult> getAllDayHistory(String userName, String date,
      {bool isRefresh = false}) async {
    resetLoadDataStatus();

    var previousData = _userHistoryData;

    final response = await _realtimeDatabaseService
        .getAllDayHistory(userName, date)
        .timeout(_timeoutDuration, onTimeout: () {
      _message = 'Get all day history operation timed out';
      return ApiResult(status: 'error', message: _message ?? '');
    });

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _userHistoryData = response.data;
    } else {
      if (isRefresh) {
        _message = 'Gagal merefresh seluruh data history harian user ';
        _userHistoryData = previousData;
      } else {
        _userHistoryData = null;
      }
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk mendapatkan semua history dari semua user
  Future<ApiResult> getAllMonthHistory(String userName,
      {bool isRefresh = false}) async {
    resetLoadDataStatus();

    var previousData = _allUserHistoryData;

    final response = await _realtimeDatabaseService
        .getAllMonthHistory(userName)
        .timeout(_timeoutDuration, onTimeout: () {
      _message = 'Get all month history operation timed out';
      return ApiResult(status: 'error', message: _message ?? '');
    });

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _allUserHistoryData = response.data;
    } else {
      if (isRefresh) {
        _message = 'Gagal merefresh seluruh data history bulanan user';
        _allUserHistoryData = previousData;
      } else {
        _allUserHistoryData = null;
      }
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk mengambil seluruh history dari semua pengguna
  Future<ApiResult> getAllCompleteHistory({bool isRefresh = false}) async {
    resetLoadDataStatus();

    var previousData = _allCompleteHistory;

    final response = await _realtimeDatabaseService
        .getAllHistoryCompletely()
        .timeout(_timeoutDuration, onTimeout: () {
      _message = 'Get all complete history operation timed out';
      return ApiResult(status: 'error', message: _message ?? '');
    });

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _allCompleteHistory = response.data;
    } else {
      if (isRefresh) {
        _message = 'Gagal merefresh seluruh data history';
        _allCompleteHistory = previousData;
      } else {
        _allCompleteHistory = null;
      }
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // ---------------------------- CLEAR | REFRESH ------------------------------------
  // Ini digunakan ketika logout dengan mengosongkan semua data
  void clearData() {
    _dataAbsensi = Data();
    _attendanceInfoData = null;
    _selectedDateHistory = null;
    _userHistoryData = null;
    _allUserHistoryData = null;
    _allCompleteHistory = null;

    _status = null;
    _message = null;

    notifyListeners();
  }

  // Ini digunakan ketika ingin mengosongkan status dan pesan
  void resetLoadDataStatus() {
    _isLoading = true;
    _status = '';
    _message = '';
    // notifyListeners();
  }
}

/*
  // Map<String, HistoryData> _userHistoryData = {};
  // Map<String, Map<String, HistoryData>> _allUserHistoryData = {};
  // Map<String, Map<String, Map<String, HistoryData>>> _allCompleteHistory = {};

  // Map<String, HistoryData> get userHistoryData => _userHistoryData;
  // Map<String, Map<String, HistoryData>> get allUserHistoryData =>
  //     _allUserHistoryData;
  // Map<String, Map<String, Map<String, HistoryData>>> get allCompleteHistory =>
  //     _allCompleteHistory;

  // Fungsi untuk mengatur status loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Membersihkan data terpilih (jika ingin mengosongkan state pada tanggal tertentu)
  void clearSelectedDateHistory() {
    _selectedDateHistory = null;
    notifyListeners();
  }

  List<String> _data = [];

  List<String> get data => _data;

  void addData(String value) {
    _data.add(value);
    notifyListeners();
  }

  void removeData(String value) {
    _data.remove(value);
    notifyListeners();
  }
*/