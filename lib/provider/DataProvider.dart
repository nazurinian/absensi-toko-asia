import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/api/ApiService.dart';
import 'package:absensitoko/api/FirestoreService.dart';
import 'package:absensitoko/api/RealtimeDatabaseService.dart';
import 'package:absensitoko/models/AttendanceInfoModel.dart';
import 'package:absensitoko/models/AttendanceModel.dart';
import 'package:absensitoko/models/HistoryModel.dart';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirestoreService _fireStoreService = FirestoreService();
  final RealtimeDatabaseService _realtimeDatabaseService = RealtimeDatabaseService();

  Data _dataAbsensi = Data();
  AttendanceInfoModel? _attendanceInfoData;
  HistoryData? _selectedDateHistory; // Model untuk menyimpan data history berdasarkan tanggal
  Map<String, HistoryData> _userHistoryData = {};
  // List<dynamic> _userHistoryData = [];
  Map<String, Map<String, HistoryData>> _allUserHistoryData = {};


  bool _statusAbsensiPagi = false;
  bool _statusAbsensiSiang = false;
  bool _isLoading = false;
  String? _status;
  String? _message;

  Data get dataAbsensi => _dataAbsensi;
  AttendanceInfoModel? get attendanceInfoData => _attendanceInfoData;
  HistoryData? get selectedDateHistory => _selectedDateHistory;
  Map<String, HistoryData> get userHistoryData => _userHistoryData;
  // List<dynamic> get userHistoryData => _userHistoryData;
  Map<String, Map<String, HistoryData>> get allUserHistoryData => _allUserHistoryData;

  bool get statusAbsensiPagi => _statusAbsensiPagi;

  bool get statusAbsensiSiang => _statusAbsensiSiang;

  bool get isLoading => _isLoading;

  String? get status => _status;

  String? get message => _message;

/*
  // Fungsi untuk mengatur status loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
*/

  // ---------------------------- DATA SHEET ------------------------------------
  Future<ApiResult> updateAttendance(
    String waktuAbsensi,
    Attendance attendance,
  ) async {
    final response = await _apiService.updateAttendance(
        waktuAbsensi: waktuAbsensi, attendance: attendance);
    refreshData(true);

    _status = response.status;
    _message = response.message;
    print("tai ayam1: $_status");
    print("tai kambing: $_message");
    if (response.status == 'success') {
      print("pusing");
      refreshData(false, dataIsLoaded: false);
      _dataAbsensi = response.data as Data;
      if (waktuAbsensi == 'pagi') {
        _statusAbsensiPagi = true;
      } else {
        _statusAbsensiSiang = true;
      }
      print('Hasil response update data: ${_dataAbsensi.toString()}');
    } else {
      print("gak pusing");
      refreshData(false, dataIsLoaded: true);
    }

    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // ---------------------------- DATA FIRE STORE ------------------------------------

  // Fungsi untuk mendapatkan data attendance
  Future<void> getData() async {
    _isLoading = true;
    notifyListeners();

    final response = await _fireStoreService.getInfoAttendanceData();

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _attendanceInfoData = response.data;
    } else {
      _attendanceInfoData = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fungsi untuk memperbarui data attendance
  Future<void> updateData(AttendanceInfoModel data) async {
    _isLoading = true;
    notifyListeners();

    final response = await _fireStoreService.updateInfoAttendanceData(data);

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _attendanceInfoData = AttendanceInfoModel(
        breaktime: data.breaktime ?? _attendanceInfoData?.breaktime,
        nationalHoliday:
            data.nationalHoliday ?? _attendanceInfoData?.nationalHoliday,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  // // Untuk Data History
  // Future<ApiResult> getHistory(String userName, String tanggal) async {
  //   final response = await _fireStoreService.getHistory(userName, tanggal);
  //   if (response.status == 'success') {
  //     _attendanceHistoryData = response.data;
  //   }
  //   notifyListeners();
  //   return response;
  // }
  //
  // Future<ApiResult> updateHistory(
  //     String userName, String tanggal, HistoryModel data) async {
  //   final response =
  //       await _fireStoreService.updateHistory(userName, tanggal, data);
  //   if (response.status == 'success') {
  //     _attendanceHistoryData = data; // Atau gunakan update parsial
  //   }
  //   notifyListeners();
  //   return response;
  // }
  
/*  // Mengambil semua history untuk pengguna tertentu
  Future<void> fetchAllHistory(String userName) async {
    // _setLoading(true);
    final result = await _fireStoreService.getAllHistoryForUser(userName);
    if (result.status == 'success' && result.data != null) {
      _historyModel = result.data;
    } else {
      print(result.message); // Tampilkan pesan jika gagal mengambil data
    }
    // _setLoading(false);
  }

  // Mengambil data history berdasarkan tanggal
  Future<void> fetchHistoryByDate(String userName, String date) async {
    // _setLoading(true);
    final result = await _fireStoreService.getHistoryByDate(userName, date);
    if (result.status == 'success') {
      _selectedDateHistory = result.data;
    } else {
      print(result.message); // Tampilkan pesan jika gagal mengambil data
      _selectedDateHistory = null;
    }
    // _setLoading(false);
  }

  // Memperbarui data history untuk tanggal tertentu
  Future<void> updateHistory(String userName, String date, HistoryData newHistoryData) async {
    // _setLoading(true);
    final result = await _fireStoreService.updateHistory(userName, date, newHistoryData);
    if (result.status == 'success') {
      // Jika berhasil, perbarui data di dalam provider
      _selectedDateHistory = newHistoryData;

      // Jika historyModel tidak null, update data secara langsung di dalamnya
      if (_historyModel != null && _historyModel!.historyData != null) {
        _historyModel!.historyData![date] = newHistoryData;
      }

      notifyListeners();
    } else {
      print(result.message); // Tampilkan pesan jika gagal memperbarui data
    }
    // _setLoading(false);
  }*/


  // Fungsi untuk inisialisasi data history
  Future<void> initializeHistory(String userName, String date) async {
    final result = await _realtimeDatabaseService.initializeHistory(userName, date);
    // Handle the result if needed
    notifyListeners();
  }

  // Fungsi untuk mendapatkan history user berdasarkan tanggal tertentu
  Future<void> getHistoryForUserByDate(String userName, String date) async {
    final result = await _realtimeDatabaseService.getHistoryForUserByDate(userName, date);
    print(result.data.toString());
    if (result.status == 'success') {
      _selectedDateHistory = HistoryData.fromMap(result.data);
    } else {
      // Handle error case
      print(result.message);
    }
    notifyListeners();
  }

  // Fungsi untuk memperbarui data history user
  Future<void> updateHistory(String userName, String date, HistoryData data) async {
    final result = await _realtimeDatabaseService.updateHistory(userName, date, data);
    if (result.status == 'success') {
      // Update local data if needed, or re-fetch
      notifyListeners();
    } else {
      // Handle error case
      print(result.message);
    }
  }

  // Fungsi untuk mendapatkan semua history dari user tertentu
  Future<ApiResult<dynamic>> getAllHistoryForUser(String userName, String date) async {
    _isLoading = true;
    _status = null;
    _message = null;

    final response = await _realtimeDatabaseService.getAllHistoryForUser(userName, date);

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      // Fungsi 3: Get All Data by User (Menggunakan Map)
      _userHistoryData = response.data;
      // Fungsi 3: Get All Data by User (Menggunakan List - Jangan Hapus)
      // _userHistoryData = response.data; // Simpan data history ke dalam state
    } else {
      _userHistoryData = {};
      // _userHistoryData = []; // Kosongkan data jika tidak berhasil
    }

    _isLoading = false;
    notifyListeners(); // Beritahu pendengar untuk memperbarui UI
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

  // Fungsi untuk mendapatkan semua history dari semua user
  Future<void> getAllHistory(String date) async {
    _isLoading = true;
    notifyListeners();

    // final response = await _fireStoreService.getAllHistory(date);
    final response = await _realtimeDatabaseService.getAllHistory(date);

    if (response.isNotEmpty) {
      _allUserHistoryData = response;
    } else {
      _allUserHistoryData = {};
    }

    _isLoading = false;
    notifyListeners();
  }


  Map<String, Map<String, Map<String, HistoryData>>> _allCompleteHistory = {};
  Map<String, Map<String, Map<String, HistoryData>>> get allCompleteHistory => _allCompleteHistory;


  // Fungsi untuk mengambil seluruh history dari semua pengguna
  Future<void> getAllCompleteHistory() async {
    try {
      // Memanggil fungsi getAllHistoryCompletely dari FirestoreService
      final result = await _realtimeDatabaseService.getAllHistoryCompletely();

      // Update data lokal dan notifikasi
      _allCompleteHistory = result;
      notifyListeners();
    } catch (e) {
      print('Error in fetchAllCompleteHistory: $e');
    }
  }

  // Membersihkan data terpilih (jika ingin mengosongkan state pada tanggal tertentu)
  void clearSelectedDateHistory() {
    _selectedDateHistory = null;
    notifyListeners();
  }

  // ---------------------------- CLEAR | REFRESH ------------------------------------
  void refreshData(bool isRefresh, {bool dataIsLoaded = true}) {
    if (isRefresh) {
      _status = null;
      _message = null;
      // _isData1Loaded = false;
      // _isData2Loaded = false;
      // _responsePostData = Pembukuan();
    } else {
      if (dataIsLoaded) {
        // _isData1Loaded = true;
        // _isData2Loaded = true;
      } else {
        // _isData1Loaded = false;
        // _isData2Loaded = false;
      }
    }
  }

  void clearData() {
    // _data = [];
    // _filteredData = [];
    // _combinedData = [];
    // _sheetNames = [];
    //
    // _isData1Loaded = false;
    // _isData2Loaded = false;
    // _isSheetDataLoaded = false;
    _isLoading = false;
    _status = null;
    _message = null;

    /// Notify nya di nonaktifkan karena ini hanya nge set ke null semua, ngga butuh respon perubahan
    // notifyListeners();
  }

  void statusClear() {
    _status = 'success';
    _message = '';

    notifyListeners();
  }

/*
// List<Pembukuan> _data = [];
// List<Pembukuan> _filteredData = [];
// List<Pembukuan> _combinedData = [];
// List<String> _sheetNames = [];
// Map<String, List<Pembukuan>> _allSheetData = {};
// Data _responsePostData = Data();

// bool _isData1Loaded = false;
// bool _isData2Loaded = false;
// bool _isSheetDataLoaded = false;
// bool _isAllSheetDataLoaded = false;

// List<Pembukuan> get data => _data;
//
// List<Pembukuan> get filteredData => _filteredData;
//
// List<Pembukuan> get combinedData => _combinedData;

// List<String> get sheetNames => _sheetNames;

// Map<String, List<Pembukuan>> get allSheetData => _allSheetData;

// Data get responsePostData=> _responsePostData;

// bool get isData1Loaded => _isData1Loaded;

// bool get isData2Loaded => _isData2Loaded;

// bool get isSheetDataLoaded => _isSheetDataLoaded;

// bool get isAllSheetDataLoaded => _isAllSheetDataLoaded;

// List<String> _data = [];
//
//   List<String> get data => _data;
//
//   void addData(String value) {
//     _data.add(value);
//     notifyListeners();
//   }
//
//   void removeData(String value) {
//     _data.remove(value);
//     notifyListeners();
//   }

*/
}
