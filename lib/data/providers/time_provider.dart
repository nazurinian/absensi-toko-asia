import 'package:absensitoko/core/constants/constants.dart';
import 'package:absensitoko/data/models/attendance_info_model.dart';
import 'package:absensitoko/data/models/history_model.dart';
import 'package:absensitoko/utils/helpers/general_helper.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:absensitoko/data/models/time_model.dart';
import 'package:ntp/ntp.dart';

// Attendance Time Provider
class TimeProvider extends ChangeNotifier {
  Timer? _timer;

  // CustomTime _currentTime = CustomTime.getCurrentTime();
  late CustomTime _currentTime;
  late DateTime _ntpTime;
  final Duration _gmt8Offset = const Duration(hours: 8); // Offset GMT+8

  // Default Break Time
  int _breakHour = 12;
  int _breakMinute = 0;

  // Holiday
  bool _isHoliday = false;

  // Attendance Messages
  String _morningAttendanceMessage = '';
  String _afternoonAttendanceMessage = '';

  // Countdown Timer
  String _countDownText = '00:00';

  // Attendance Status
  String _morningAttendanceStatus = '';
  String _afternoonAttendanceStatus = '';
  bool _isMorningAlreadyCheckedIn = false;
  bool _isAfternoonAlreadyCheckedIn = false;
  bool _isMorningOnTime = false;
  bool _isAfternoonOnTime = false;

  // Getters
  CustomTime get currentTime => _currentTime;

  String get countDownText => _countDownText;

  String get morningAttendanceMessage => _morningAttendanceMessage;

  String get afternoonAttendanceMessage => _afternoonAttendanceMessage;

  String get morningAttendanceStatus => _morningAttendanceStatus;

  String get afternoonAttendanceStatus => _afternoonAttendanceStatus;

  String get attendancePoint => _calculateAttendancePoint();

/*  TimeProvider() : _currentTime = CustomTime.getCurrentTime() {
    _initializeNtpTime();
  }*/

  TimeProvider() {
    // _currentTime = CustomTime.getCurrentTime();
    // _startTimer();
    _currentTime = CustomTime.getInitialTime();
    _initializeNtpTime();
  }

  Future<void> _initializeNtpTime() async {
    try {
      _ntpTime = await NTP.now(); // Ambil waktu dari server NTP
      _ntpTime = _ntpTime.add(_gmt8Offset); // Set GMT+8 (WITA)
      _startTimer();
    } catch (e) {
      print("Failed to get NTP time: $e");
      // fallback jika tidak ada waktu NTP
      _ntpTime = DateTime.now().add(_gmt8Offset);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Update waktu setiap detik dengan mengacu pada waktu NTP awal
      // Gunakan offset GMT+8 setiap kali update
      DateTime updatedTime = _ntpTime.add(Duration(hours: -7, seconds: timer.tick));
      _currentTime = CustomTime.fromDateTime(updatedTime);
      // print('Difference: ${DateTime.now().difference(_ntpTime).inHours}');

      // _currentTime = CustomTime.getCurrentTime();
      _updateAttendanceState();
      notifyListeners();
    });
  }

  void stopUpdatingTime() {
    _timer?.cancel();
  }

  void updateAttendanceCheck(bool isMorning, {bool isOnTime = false}) {
    if (isMorning) {
      _isMorningAlreadyCheckedIn = true;
      _isMorningOnTime = isOnTime;
    } else {
      _isAfternoonAlreadyCheckedIn = true;
      _isAfternoonOnTime = isOnTime;
    }

    _countDownText = _currentTime.getIdnTime();
    notifyListeners();
  }

  void _setAttendanceStatus(String status, String title) {
    if (title == 'pagi') {
      _isMorningOnTime = status == 'T';
      _morningAttendanceStatus = status;
    } else if (title == 'siang') {
      _isAfternoonOnTime = status == 'T';
      _afternoonAttendanceStatus = status;
    }
  }

  void setHolidayStatus(bool status) {
    _isHoliday = status;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Update attendance message and timer
  String _setAttendanceMessage({
    required String title,
    required DateTime now,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime lateStartTime,
    required DateTime lateEndTime,
    required DateTime overLateStartTime,
    required DateTime overLateEndTime,
    required DateTime breakTime,
    required DateTime storeCloseTime,
  }) {
    // Check if store is closed (SAMPE JAM 05:00)
    // final close = storeCloseTime.add(const Duration(hours: 11, minutes: 30));
    if (isWithinTimeRangeExclusive(now, storeCloseTime,
        storeCloseTime.add(const Duration(hours: -13, minutes: 30)))) {
      // print('1. Store is closed');
      _countDownText = _currentTime.getIdnTime();
      return title == 'siang' ? 'Toko sudah tutup' : '';
    }

    // Check preparation time before attendance (30 minutes before start)
    else if (isWithinTimeRangeExclusive(
        now, startTime.subtract(const Duration(minutes: 30)), startTime)) {
      // print('2. Preparation time');
      _countDownText = _formatDuration(startTime.difference(now));
      return 'Persiapan absen $title';
    }

    // Check on-time attendance (ABSEN TEPAT WAKTU | Sudah absen untuk pagi)
    else if (_isMorningAlreadyCheckedIn &&
        _isMorningOnTime &&
        title == 'pagi') {
      // print('3a. On-time attendance');
      _countDownText = _currentTime.getIdnTime();
      return 'Berhasil absen $title tepat waktu';
    }

    // Check on-time attendance (ABSEN TEPAT WAKTU | Sudah absen untuk siang)
    else if (_isAfternoonAlreadyCheckedIn &&
        _isAfternoonOnTime &&
        title == 'siang') {
      // print('3b. On-time attendance');
      _countDownText = _currentTime.getIdnTime();
      return 'Berhasil absen $title tepat waktu';
    }

    // Check on-time attendance (ABSEN TEPAT WAKTU | Belum absen)
    else if (isWithinTimeRangeInclusive(now, startTime, endTime)) {
      // print('3c. This time to attendance (On-time)');
      _countDownText = _formatDuration(endTime.difference(now));
      _setAttendanceStatus('T', title);
      return 'Waktu tepat waktu untuk absen $title';
    }

    // Check late attendance (ABSEN TELAT | Sudah absen untuk pagi)
    else if (_isMorningAlreadyCheckedIn && title == 'pagi') {
      // print('4a. Late attendance');
      _countDownText = _currentTime.getIdnTime();
      return 'Terlambat, berhasil absen $title';
    }

    // Check late attendance (ABSEN TELAT | Sudah absen untuk siang)
    else if (_isAfternoonAlreadyCheckedIn && title == 'siang') {
      // print('4b. Late attendance');
      _countDownText = _currentTime.getIdnTime();
      return 'Terlambat, berhasil absen $title';
    }

    // Check late attendance (ABSEN TELAT)
    else if (isWithinTimeRangeInclusive(now, lateStartTime, overLateEndTime)) {
      // print('4c. This time to attendance (Late)');
      _countDownText = _currentTime.getIdnTime();
      _setAttendanceStatus('L', title);
      return 'Waktu terlambat untuk absen $title';
    } else if (isWithinTimeRangeInclusive(now, breakTime, startTime) &&
        title == 'siang') {
      // print('7. Break time');
      _countDownText = _currentTime.getIdnTime();
      return 'Belum saatnya waktu absen $title';
    }

    // Diluar waktu pagi dan siang jika tidak hadir
    else if (isWithinTimeRangeInclusive(now, overLateEndTime, storeCloseTime)) {
      // print('5. (Over late $title)');
      _countDownText = _currentTime.getIdnTime();
      _setAttendanceStatus('A', title);
      return 'Tidak hadir $title hari ini';
    }

    // Diluar waktu siang
    else if (now.isBefore(breakTime) && title == 'siang') {
      // print('8. Diluar waktu siang');
      return '';
    } else {
      // print('9. Default');
      _countDownText = _currentTime.getIdnTime();
      return '';
    }
  }

  // Update attendance states for morning and afternoon
  void _updateAttendanceState() {
    DateTime now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );

    // bool isHoliday = nationalHoliday.isNotEmpty || now.weekday == DateTime.sunday;

    final morningStartTime = _isHoliday
        ? DateTime(now.year, now.month, now.day, morningHolidayStartHour,
            morningHolidayStartMinute)
        : DateTime(
            now.year, now.month, now.day, morningStartHour, morningStartMinute);
    final storeCloseTime = DateTime(
        now.year, now.month, now.day, storeClosedHour, storeClosedMinute);
    final breakTime =
        DateTime(now.year, now.month, now.day, _breakHour, _breakMinute);

    // Waktu pagi:
    final morningEndTime = DateTime(
        now.year, now.month, now.day, morningEndHour, morningEndMinute);
    final morningLateStartTime = morningEndTime.add(const Duration(seconds: 1));
    final morningLateEndTime = morningEndTime.add(const Duration(minutes: 5));
    final morningOverLateStartTime =
        morningLateEndTime.add(const Duration(seconds: 1));
    final morningOverLateEndTime = DateTime(
        now.year, now.month, now.day, morningLateEndHour, morningLateEndMinute);

    // bool morningAlreadyCheckedIn = (historyData.tLPagi != null && historyData.tLPagi!.isNotEmpty) ? true : false;

    _morningAttendanceMessage = _setAttendanceMessage(
      title: 'pagi',
      now: now,
      startTime: morningStartTime,
      endTime: morningEndTime,
      lateStartTime: morningLateStartTime,
      lateEndTime: morningLateEndTime,
      overLateStartTime: morningOverLateStartTime,
      overLateEndTime: morningOverLateEndTime,
      breakTime: breakTime,
      storeCloseTime: storeCloseTime,
    );

    // Waktu siang:
    final afternoonStartTime = breakTime
        .add(const Duration(minutes: afternoonPreparationMinutes - 10));
    final afternoonEndTime =
        breakTime.add(const Duration(minutes: afternoonPreparationMinutes + 4));
    final afternoonLateStartTime =
        afternoonEndTime.add(const Duration(seconds: 1));
    final afternoonLateEndTime =
        afternoonEndTime.add(const Duration(minutes: 5));
    final afternoonOverLateStartTime =
        afternoonLateEndTime.add(const Duration(seconds: 1));
    final afternoonOverLateEndTime = breakTime.add(const Duration(
        minutes: afternoonLateToEndMinutes + afternoonPreparationMinutes));

    // bool afternoonAlreadyCheckedIn = (historyData.tLSiang != null && historyData.tLSiang!.isNotEmpty) ? true : false;

    _afternoonAttendanceMessage = _setAttendanceMessage(
      title: 'siang',
      now: now,
      startTime: afternoonStartTime,
      endTime: afternoonEndTime,
      lateStartTime: afternoonLateStartTime,
      lateEndTime: afternoonLateEndTime,
      overLateStartTime: afternoonOverLateStartTime,
      overLateEndTime: afternoonOverLateEndTime,
      breakTime: breakTime,
      storeCloseTime: storeCloseTime,
    );
  }

  bool isPagiButtonActive(HistoryData historyData, String nationalHoliday) {
    DateTime now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );

    // Periksa apakah hari ini tanggal merah (libur nasional atau hari Minggu)
    bool isHoliday =
        nationalHoliday.isNotEmpty || now.weekday == DateTime.sunday;

    // Start dan end time untuk absen pagi (tepat waktu)
    DateTime morningStartTime = isHoliday
        ? DateTime(now.year, now.month, now.day, morningHolidayStartHour,
            morningHolidayStartMinute)
        : DateTime(
            now.year, now.month, now.day, morningStartHour, morningStartMinute);
    DateTime morningEndTime =
        morningStartTime.add(const Duration(minutes: attendanceTimerInterval));

    // Batas akhir untuk absen telat
    DateTime morningLateStartTime =
        morningEndTime.add(const Duration(seconds: 1));
    DateTime morningLateEndTime = DateTime(
        now.year, now.month, now.day, morningLateEndHour, morningLateEndMinute);

/*
    print('Morning Start: $morningStartTime');
    print('Morning End: $morningEndTime');
    print('Morning Late Start: $morningLateStartTime');
    print('Morning Late End: $morningLateEndTime');
*/

    // Cek apakah user sudah absen pagi
    bool alreadyCheckedIn =
        (historyData.tLPagi != null && historyData.tLPagi!.isNotEmpty)
            ? true
            : false;

    // Tombol aktif hanya jika belum absen dan waktu dalam jangka yang ditentukan
    return !alreadyCheckedIn &&
        (isWithinTimeRangeInclusive(now, morningStartTime, morningEndTime) ||
            isWithinTimeRangeInclusive(
                now, morningLateStartTime, morningLateEndTime));
  }

  bool isSiangButtonActive(HistoryData historyData) {
    DateTime now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );

    // Waktu break time yang diatur di AppInfoModel
    DateTime breakTime =
        DateTime(now.year, now.month, now.day, _breakHour, _breakMinute);

    // Start dan end time untuk absen siang (tepat waktu)
    DateTime afternoonStartTime = breakTime.add(const Duration(
        minutes: afternoonPreparationMinutes - 10)); // 10 menit sebelum mulai
    DateTime afternoonEndTime = breakTime.add(const Duration(
        minutes: afternoonPreparationMinutes + 4)); // 4 menit setelah

    // Batas akhir untuk absen telat
    DateTime afternoonLateStartTime =
        afternoonEndTime.add(const Duration(seconds: 1));
    DateTime afternoonLateEndTime = breakTime.add(const Duration(
        minutes: afternoonLateToEndMinutes +
            afternoonPreparationMinutes)); // 1 jam setelah break

/*
    print('Break Time: $breakTime');
    print('Afternoon Start: $afternoonStartTime');
    print('Afternoon End: $afternoonEndTime');
    print('Afternoon Late Start: $afternoonLateStartTime');
    print('Afternoon Late End: $afternoonLateEndTime');
*/

    // Cek apakah user sudah absen siang
    bool alreadyCheckedIn =
        (historyData.tLSiang != null && historyData.tLSiang!.isNotEmpty)
            ? true
            : false;

    // Tombol aktif hanya jika belum absen dan waktu dalam jangka yang ditentukan
    return !alreadyCheckedIn &&
        (isWithinTimeRangeInclusive(
                now, afternoonStartTime, afternoonEndTime) ||
            isWithinTimeRangeInclusive(
                now, afternoonLateStartTime, afternoonLateEndTime));
  }

  bool isWithinTimeRangeInclusive(
      DateTime currentTime, DateTime startTime, DateTime endTime) {
    if (startTime.isAfter(endTime)) {
      // Rentang waktu melewati tengah malam
      return (currentTime.isAfter(startTime) ||
              currentTime.isAtSameMomentAs(startTime)) ||
          (currentTime.isBefore(endTime) ||
              currentTime.isAtSameMomentAs(endTime));
    } else {
      // Rentang waktu dalam satu hari
      return (currentTime.isAfter(startTime) ||
              currentTime.isAtSameMomentAs(startTime)) &&
          (currentTime.isBefore(endTime) ||
              currentTime.isAtSameMomentAs(endTime));
    }
  }

  // Fungsi tanpa batas waktu termasuk (> dan <)
  bool isWithinTimeRangeExclusive(
      DateTime currentTime, DateTime startTime, DateTime endTime) {
    if (startTime.isAfter(endTime)) {
      // Rentang waktu melewati tengah malam
      return (currentTime.isAfter(startTime) ||
              currentTime.isAtSameMomentAs(startTime)) ||
          (currentTime.isBefore(endTime) ||
              currentTime.isAtSameMomentAs(endTime));
    } else {
      // Rentang waktu dalam satu hari
      return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
    }
  }

  void updateBreakTime(int hour, int minute) {
    _breakHour = hour;
    _breakMinute = minute;
    notifyListeners();
  }

  void resetAttendanceCheck() {
    _isMorningAlreadyCheckedIn = false;
    _isAfternoonAlreadyCheckedIn = false;
    _isMorningOnTime = false;
    _isAfternoonOnTime = false;
    notifyListeners();
  }

  String _calculateAttendancePoint() {
    final now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );

    // Waktu pagi :
    // jam 06:50:00 - 07:04:00 untuk poin 0
    // jam 07:04:01 - 07:09:00 untuk poin 5
    // jam 07:09:01 - 10:00:00 untuk poin 10

    // Periksa apakah hari ini tanggal merah (libur nasional atau hari Minggu)
    // bool isHoliday = nationalHoliday.isNotEmpty || now.weekday == DateTime.sunday;
    final morningStartTime = _isHoliday
        ? DateTime(now.year, now.month, now.day, morningHolidayStartHour,
            morningHolidayStartMinute)
        : DateTime(
            now.year, now.month, now.day, morningStartHour, morningStartMinute);
    final storeCloseTime = DateTime(
        now.year, now.month, now.day, storeClosedHour, storeClosedMinute);
    final breakTime =
        DateTime(now.year, now.month, now.day, _breakHour, _breakMinute);

/*
    print('---------------------------------------');
    print('Now: $now');
    print('Store Close: $storeCloseTime');
    print('Break Time: $breakTime');
    print('---------------------------------------');
*/

    // Jika absensi dilakukan sebelum waktu pagi atau setelah tutup toko
    if (now.isBefore(morningStartTime) || now.isAfter(storeCloseTime)) {
      return '';
    }

    // Waktu pagi:
    final morningEndTime = DateTime(
        now.year, now.month, now.day, morningEndHour, morningEndMinute);
    final morningLateStartTime = morningEndTime.add(const Duration(seconds: 1));
    final morningLateEndTime = morningEndTime.add(const Duration(minutes: 5));
    final morningOverLateStartTime =
        morningLateEndTime.add(const Duration(seconds: 1));
    final morningOverLateEndTime = DateTime(
        now.year, now.month, now.day, morningLateEndHour, morningLateEndMinute);

/*
    print('Morning Start: $morningStartTime');
    print('Morning End: $morningEndTime');
    print('Morning Late Start: $morningLateStartTime');
    print('Morning Late End: $morningLateEndTime');
    print('Morning Over Late Start: $morningOverLateStartTime');
    print('Morning Over Late End: $morningOverLateEndTime');
    print('---------------------------------------');
*/

    if (isWithinTimeRangeInclusive(now, morningStartTime, morningEndTime)) {
      return '0'; // Tepat waktu
    } else if (isWithinTimeRangeInclusive(
        now, morningLateStartTime, morningLateEndTime)) {
      return '5'; // Terlambat sedikit
    } else if (now.isAfter(morningOverLateStartTime) &&
        now.isBefore(morningOverLateEndTime)) {
      return '10'; // Terlambat parah
    }

    // Waktu siang:
    final afternoonStartTime = breakTime
        .add(const Duration(minutes: afternoonPreparationMinutes - 10));
    final afternoonEndTime =
        breakTime.add(const Duration(minutes: afternoonPreparationMinutes + 4));
    final afternoonLateStartTime =
        afternoonEndTime.add(const Duration(seconds: 1));
    final afternoonLateEndTime =
        afternoonEndTime.add(const Duration(minutes: 5));
    final afternoonOverLateStartTime =
        afternoonLateEndTime.add(const Duration(seconds: 1));
    final afternoonOverLateEndTime = breakTime.add(const Duration(
        minutes: afternoonLateToEndMinutes + afternoonPreparationMinutes));

/*
    print('Afternoon Start: $afternoonStartTime');
    print('Afternoon End: $afternoonEndTime');
    print('Afternoon Late Start: $afternoonLateStartTime');
    print('Afternoon Late End: $afternoonLateEndTime');
    print('Afternoon Over Late Start: $afternoonOverLateStartTime');
    print('Afternoon Over Late End: $afternoonOverLateEndTime');
    print('---------------------------------------');
*/

    if (isWithinTimeRangeInclusive(now, afternoonStartTime, afternoonEndTime)) {
      return '0'; // Tepat waktu
    } else if (isWithinTimeRangeInclusive(
        now, afternoonLateStartTime, afternoonLateEndTime)) {
      return '5'; // Terlambat sedikit
    } else if (now.isAfter(afternoonOverLateStartTime) &&
        now.isBefore(afternoonOverLateEndTime)) {
      return '10'; // Terlambat parah
    }

    return 'Absent'; // Di luar jam absensi
  }
}
