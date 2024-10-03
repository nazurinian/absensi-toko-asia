import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/api/ApiService.dart';
import 'package:absensitoko/models/AttendanceModel.dart';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
/*  List<String> _data = [];

  List<String> get data => _data;

  void addData(String value) {
    _data.add(value);
    notifyListeners();
  }

  void removeData(String value) {
    _data.remove(value);
    notifyListeners();
  }*/

  final ApiService _apiService = ApiService();

  // List<Pembukuan> _data = [];
  // List<Pembukuan> _filteredData = [];
  // List<Pembukuan> _combinedData = [];
  // List<String> _sheetNames = [];
  // Map<String, List<Pembukuan>> _allSheetData = {};

  // Data _responsePostData = Data();
  Data _dataAbsensi = Data();
  bool _statusAbsensiPagi = false;
  bool _statusAbsensiSiang = false;

  // bool _isData1Loaded = false;
  // bool _isData2Loaded = false;
  // bool _isSheetDataLoaded = false;
  // bool _isAllSheetDataLoaded = false;
  bool _isLoading = false;
  String? _status;
  String? _message;

  // List<Pembukuan> get data => _data;
  //
  // List<Pembukuan> get filteredData => _filteredData;
  //
  // List<Pembukuan> get combinedData => _combinedData;

  // List<String> get sheetNames => _sheetNames;

  // Map<String, List<Pembukuan>> get allSheetData => _allSheetData;

  // Data get responsePostData=> _responsePostData;

  Data get dataAbsensi => _dataAbsensi;

  bool get statusAbsensiPagi => _statusAbsensiPagi;

  bool get statusAbsensiSiang => _statusAbsensiSiang;

  // bool get isData1Loaded => _isData1Loaded;

  // bool get isData2Loaded => _isData2Loaded;

  // bool get isSheetDataLoaded => _isSheetDataLoaded;

  // bool get isAllSheetDataLoaded => _isAllSheetDataLoaded;

  bool get isLoading => _isLoading;

  String? get status => _status;

  String? get message => _message;

  Future<ApiResult> updateAttendance(
      String waktuAbsensi,
    Attendance attendance,
  ) async {
    final response = await _apiService.updateAttendance(waktuAbsensi: waktuAbsensi, attendance: attendance);
    refreshData(true);

    _status = response.status;
    _message = response.message;
    print("tai ayam1: $_status");
    print("tai kambing: $_message");
    if (response.status == 'success') {
      refreshData(false, dataIsLoaded: false);
      _dataAbsensi = response.data as Data;
    } else {
      refreshData(false, dataIsLoaded: true);
    }

    print('Hasil response update data: ${_dataAbsensi.toString()}');
    notifyListeners();
    return ApiResult(status: _status ?? '', message: _message ?? '');
  }

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
}
