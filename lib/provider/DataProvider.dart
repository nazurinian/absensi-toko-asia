import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/api/ApiService.dart';
import 'package:absensitoko/api/FirestoreService.dart';
import 'package:absensitoko/api/RealtimeDatabaseService.dart';
import 'package:absensitoko/models/AppVersionModel.dart';
import 'package:absensitoko/models/AttendanceInfoModel.dart';
import 'package:absensitoko/models/AttendanceModel.dart';
import 'package:absensitoko/models/HistoryModel.dart';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirestoreService _fireStoreService = FirestoreService();
  final RealtimeDatabaseService _realtimeDatabaseService =
      RealtimeDatabaseService();

  // Data sheet
  Data _dataAbsensi = Data();

  // Data models
  AttendanceInfoModel? _attendanceInfoData;
  HistoryData? _selectedDateHistory;
  DailyHistory? _userHistoryData;
  MonthlyHistory? _allUserHistoryData;
  HistoryModel? _allCompleteHistory;

  bool _isLoading = false;
  String? _status;
  String? _message;

  Data? get dataAbsensi => _dataAbsensi;

  AttendanceInfoModel? get attendanceInfoData => _attendanceInfoData;

  HistoryData? get selectedDateHistory => _selectedDateHistory;

  DailyHistory? get userHistoryData => _userHistoryData;

  MonthlyHistory? get allUserHistoryData => _allUserHistoryData;

  HistoryModel? get allCompleteHistory => _allCompleteHistory;

  bool get isLoading => _isLoading;

  String? get status => _status;

  String? get message => _message;

  // Boolean flags to indicate data availability
  bool get isAttendanceInfoAvailable => _attendanceInfoData != null;

  bool get isSelectedDateHistoryAvailable => _selectedDateHistory != null;

  bool get isUserHistoryDataAvailable => _userHistoryData != null;

  bool get isAllUserHistoryDataAvailable => _allUserHistoryData != null;

  bool get isAllCompleteHistoryAvailable => _allCompleteHistory != null;

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

    final response = await _apiService.updateAttendance(
      waktuAbsensi: waktuAbsensi,
      attendance: attendance,
    );

    _status = response.status;
    _message = response.message;

    if (response.status == 'success') {
      _dataAbsensi = response.data as Data;
      print('Hasil response update data: ${_dataAbsensi.toString()}');
    } else {
      if (isRefresh) {
        _message = 'Gagal memperbarui data absensi';
        _dataAbsensi = previousData;
      } else {
        _dataAbsensi = Data();
      }
    }

    print(response.message);
    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // ---------------------------- DATA FIRE STORE ------------------------------------

  // Fungsi untuk mendapatkan data attendance
  Future<ApiResult> getAttendanceInfo({bool isRefresh = false}) async {
    resetLoadDataStatus();

    var previousData = _attendanceInfoData;

    final response = await _fireStoreService.getAttendanceInfo();

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

    print(response.message);
    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk memperbarui data attendance
  Future<ApiResult> updateAttendanceInfo(AttendanceInfoModel data) async {
    resetLoadDataStatus();

    final response = await _fireStoreService.updateAttendanceInfo(data);

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
      print('Gagal melakukan update informasi absensi');
    }

    print(response.message);
    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }


  AppVersionModel? _appVersion;

  AppVersionModel? get appVersion => _appVersion;

  Future<void> getAppVersion() async {
    _appVersion = await _fireStoreService.getAppVersion();
    notifyListeners();
  }

/*  Future<void> updateAppVersion(AppVersionModel appVersion) async {
    await _fireStoreService.updateAppVersion(appVersion);
    _appVersion = appVersion;
    notifyListeners();
  }*/

  // ---------------------------- DATA RTDB ------------------------------------

  // Fungsi untuk inisialisasi data history
  Future<ApiResult> initializeHistory (String userName, String date, {bool isRefresh = false}) async {
    resetLoadDataStatus();

    final response =
        await _realtimeDatabaseService.initializeHistory(userName, date);

    _status = response.status;
    _message = response.message;

    print(response.message);
    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk mendapatkan history user berdasarkan tanggal tertentu
  Future<ApiResult> getThisDayHistory(String userName, String date, {bool isRefresh = false}) async {
    resetLoadDataStatus();

    // Simpan data lama untuk refresh
    var previousData = _selectedDateHistory;

    final response =
        await _realtimeDatabaseService.getThisDayHistory(userName, date);

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

    print(response.message);
    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk memperbarui data history user
  Future<ApiResult> updateThisDayHistory(String userName, String date, HistoryData data) async {
    resetLoadDataStatus();

    final response = await _realtimeDatabaseService.updateThisDayHistory(
        userName, date, data);

    _status = response.status;
    _message = response.message;

    if (response.status == 'success') {
      _selectedDateHistory = response.data;
    } else {
      print('Gagal melakukan pencatatan update pada history');
    }

    print(response.message);
    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk mendapatkan semua history dari user tertentu
  Future<ApiResult> getAllDayHistory(String userName, String date, {bool isRefresh = false}) async {
    resetLoadDataStatus();

    var previousData = _userHistoryData;

    final response =
        await _realtimeDatabaseService.getAllDayHistory(userName, date);

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

    print(response.message);
    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk mendapatkan semua history dari semua user
  Future<ApiResult> getAllMonthHistory(String userName, {bool isRefresh = false}) async {
    resetLoadDataStatus();

    var previousData = _allUserHistoryData;

    final response =
        await _realtimeDatabaseService.getAllMonthHistory(userName);

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

    print(response.message);
    _isLoading = false;
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk mengambil seluruh history dari semua pengguna
  Future<ApiResult> getAllCompleteHistory({bool isRefresh = false}) async {
    resetLoadDataStatus();

    var previousData = _allCompleteHistory;

    final response = await _realtimeDatabaseService.getAllHistoryCompletely();

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

    print(response.message);
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
}
