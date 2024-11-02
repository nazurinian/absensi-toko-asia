import 'package:absensitoko/core/constants/constants.dart';
import 'package:absensitoko/data/models/attendance_info_model.dart';
import 'package:absensitoko/data/models/history_model.dart';
import 'package:absensitoko/utils/helpers/general_helper.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:absensitoko/data/models/time_model.dart';

/*
class TimeProvider extends ChangeNotifier {
  Timer? _timer;
  CustomTime _currentTime = CustomTime.getCurrentTime();

  String _morningAttendanceMessage = '';
  String _afternoonAttendanceMessage = '';
  String _countDownText = '00:00';

  int _breakHour = 11;
  int _breakMinute = 40;

  bool _checkAbsenPagi = false;
  bool _checkAbsenSiang = false;
  bool _tepatWaktuPagi = false;
  bool _tepatWaktuSiang = false;
  String _attendanceStatus = '';

  CustomTime get currentTime => _currentTime;

  String get countDownText => _countDownText;

  String get morningAttendanceMessage => _morningAttendanceMessage;

  String get afternoonAttendanceMessage => _afternoonAttendanceMessage;

  String get attendanceStatus => _attendanceStatus;

  TimeProvider() {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = CustomTime.getCurrentTime();
      _updateAttendanceState();
      notifyListeners();
    });
  }

  void stopUpdatingTime() {
    _timer?.cancel();
  }

  // Helper to handle common countdown messages and checks
  void _setAttendanceMessage(
    DateTime now,
    DateTime startTime,
    DateTime endTime,
    DateTime offTime,
    DateTime storeCloseTime,
    String attendanceOnTime,
    String attendanceOnLateTime,
    String onTimeMessage,
    String lateMessage,
    String absentMessage,
    bool isAfternoon,
  ) {
    if (isWithinTimeRange(now, storeCloseTime,
        storeCloseTime.add(const Duration(hours: 11, minutes: 30)))) {
      if (isAfternoon) {
        _afternoonAttendanceMessage = '';
        resetAttendanceCheck('siang');
      } else {
        _morningAttendanceMessage = 'Toko Tutup';
        resetAttendanceCheck('pagi');
      }
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(
            now,
            startTime.subtract(const Duration(hours: 1, minutes: 40)),
            startTime.subtract(const Duration(minutes: 30))) &&
        !isAfternoon) {
      _morningAttendanceMessage = 'Toko Belum Buka';
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(
          now,
          offTime.subtract(const Duration(hours: 2)),
          startTime.subtract(const Duration(minutes: 30)),
        ) &&
        isAfternoon) {
      DateTime breakTime = offTime.subtract(const Duration(hours: 2));
      DateTime siangStoreOpen = offTime.subtract(const Duration(hours: 1));
      _afternoonAttendanceMessage =
          'Waktu ISHOMA, Jam: ${formatTime(breakTime)} - ${formatTime(siangStoreOpen)}\nAnda Dapat memulai absen jam: ${formatTime(startTime)}';
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(
        now, startTime.subtract(const Duration(minutes: 30)), startTime)) {
      if (isAfternoon) {
        _afternoonAttendanceMessage =
            'Persiapan 30 menit sebelum absen Siang dimulai';
      } else {
        _morningAttendanceMessage =
            'Persiapan 30 menit sebelum absen Pagi dimulai';
      }
      _countDownText = _formatDuration(startTime.difference(now));
    } else if (isWithinTimeRange(now, startTime, storeCloseTime) &&
        _checkAbsenPagi &&
        !isAfternoon) {
      if (isWithinTimeRange(now, startTime, endTime)) {
        _morningAttendanceMessage = attendanceOnTime;
        _tepatWaktuPagi = true;
      } else if (isWithinTimeRange(now, endTime, storeCloseTime) &&
          !_tepatWaktuPagi) {
        _morningAttendanceMessage = attendanceOnLateTime;
      }
      _attendanceStatus = '';
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(now, startTime, storeCloseTime) &&
        _checkAbsenSiang &&
        isAfternoon) {
      if (isWithinTimeRange(now, startTime, endTime)) {
        _afternoonAttendanceMessage = attendanceOnTime;
        _tepatWaktuSiang = true;
      } else if (isWithinTimeRange(now, endTime, storeCloseTime) &&
          !_tepatWaktuSiang) {
        _afternoonAttendanceMessage = attendanceOnLateTime;
      }
      _attendanceStatus = '';
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(now, startTime, endTime)) {
      if (isAfternoon) {
        _afternoonAttendanceMessage = onTimeMessage;
      } else {
        _morningAttendanceMessage = onTimeMessage;
      }
      _attendanceStatus = 'T';
      _countDownText = _formatDuration(endTime.difference(now));
    } else if (isWithinTimeRange(now, startTime, offTime)) {
      if (isAfternoon) {
        _afternoonAttendanceMessage = lateMessage;
      } else {
        _morningAttendanceMessage = lateMessage;
      }
      _attendanceStatus = 'L';
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(now, offTime, storeCloseTime)) {
      if (isAfternoon) {
        _afternoonAttendanceMessage = absentMessage;
      } else {
        _morningAttendanceMessage = absentMessage;
      }
      _countDownText = _currentTime.getIdnTime();
    } else {
      if (isAfternoon) {
        _afternoonAttendanceMessage = '';
        resetAttendanceCheck('siang');
      } else {
        _morningAttendanceMessage = 'Toko Tutup';
        resetAttendanceCheck('pagi');
      }
      _countDownText = _currentTime.getIdnTime();
    }
  }

  void _updateAttendanceState() {
    DateTime now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );

    // Pagi Absence Logic
    DateTime startPagi = DateTime(now.year, now.month, now.day, 6, 50);
    DateTime endPagi = startPagi.add(const Duration(minutes: 14));
    DateTime offPagi = DateTime(now.year, now.month, now.day, 10, 0);
    DateTime storeCloseTime = DateTime(now.year, now.month, now.day, 17, 30);

    _setAttendanceMessage(
      now,
      startPagi,
      endPagi,
      offPagi,
      storeCloseTime,
      'Berhasil Absen pagi tepat waktu',
      'Berhasil Absen pagi lewat waktu (Terlambat)',
      'Waktu tepat waktu absen pagi',
      'Anda terlambat masuk pagi',
      'Anda tidak hadir pagi ini',
      false,
    );

    // Siang Absence Logic
    DateTime breakTime =
        DateTime(now.year, now.month, now.day, _breakHour, _breakMinute);
    DateTime storeOpenSiangTime = breakTime.add(const Duration(hours: 1));
    DateTime startSiang =
        storeOpenSiangTime.subtract(const Duration(minutes: 20));
    DateTime endSiang = startSiang.add(const Duration(minutes: 30));
    DateTime offSiang = storeOpenSiangTime.add(const Duration(hours: 1));

    _setAttendanceMessage(
      now,
      startSiang,
      endSiang,
      offSiang,
      storeCloseTime,
      'Berhasil Absen siang tepat waktu',
      'Berhasil Absen siang lewat waktu (Terlambat)',
      'Waktu tepat waktu absen siang',
      'Absen terlambat masuk siang',
      'Anda tidak hadir siang ini',
      true,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  bool isPagiButtonActive(HistoryData historyData, AttendanceInfoModel info) {
    DateTime now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );

    // Periksa apakah hari ini tanggal merah
    bool isHoliday = info.nationalHoliday!.isNotEmpty ? true : false;

    // Start dan end time untuk absen pagi (tepat waktu)
    DateTime startPagi = isHoliday
        ? DateTime(now.year, now.month, now.day, morningHolidayStartHour, morningHolidayStartMinute)
        : DateTime(now.year, now.month, now.day, morningStartHour, morningStartMinute);
    DateTime endPagi = startPagi.add(const Duration(minutes: attendanceTimerInterval));

    // Batas akhir untuk absen telat
    DateTime lateEndPagi = DateTime(now.year, now.month, now.day, morningLateEndHour, morningLateEndMinute);

    // Cek apakah user sudah absen pagi
    bool alreadyCheckedIn = (historyData.tLPagi != null || historyData.tLPagi!.isNotEmpty) ? true : false;

    // Tombol aktif hanya jika belum absen dan waktu dalam jangka yang ditentukan
    return !alreadyCheckedIn &&
        (isWithinTimeRange(now, startPagi, lateEndPagi) ||
            isWithinTimeRange(now, endPagi, lateEndPagi));
  }

  bool isSiangButtonActive(HistoryData historyData, AttendanceInfoModel info) {
    DateTime now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );

    // Waktu break time yang diatur di AppInfoModel
    DateTime breakTime = DateTime(now.year, now.month, now.day,
        _breakHour, _breakMinute);

    // Start dan end time untuk absen siang (tepat waktu)
    DateTime startSiang = breakTime.add(const Duration(minutes: afternoonPreparationMinutes - 10)); // 10 menit sebelum mulai
    DateTime endSiang = breakTime.add(const Duration(minutes: afternoonPreparationMinutes + 4)); // 4 menit setelah

    // Batas akhir untuk absen telat
    DateTime lateEndSiang = breakTime.add(const Duration(minutes: afternoonLateToEndMinutes + afternoonPreparationMinutes)); // 1 jam setelah break

    // Cek apakah user sudah absen siang
    bool alreadyCheckedIn = (historyData.tLPagi != null || historyData.tLPagi!.isNotEmpty) ? true : false;

    // Tombol aktif hanya jika belum absen dan waktu dalam jangka yang ditentukan
    return !alreadyCheckedIn &&
        (isWithinTimeRange(now, startSiang, lateEndSiang) ||
            isWithinTimeRange(now, endSiang, lateEndSiang));
  }

  bool isWithinTimeRange(DateTime currentTime, DateTime startTime, DateTime endTime) {
    return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
  }

  void updateBreakTime(int hour, int minute) {
    _breakHour = hour;
    _breakMinute = minute;
    notifyListeners();
  }

  void resetAttendanceCheck(String type) {
    if (type == 'pagi') {
      _checkAbsenPagi = false;
      _tepatWaktuPagi = false;
    } else if (type == 'siang') {
      _checkAbsenSiang = false;
      _tepatWaktuSiang = false;
    }

  }

  void onButtonClick(String type) {
    if (type == 'pagi' && !_checkAbsenPagi) {
      _checkAbsenPagi = true;
    } else if (type == 'siang' && !_checkAbsenSiang) {
      _checkAbsenSiang = true;
    }
  }
}
*/

// Attendance time configuration
class AttendanceTimeConfig {
  static const int morningStartHour = 6;
  static const int morningStartMinute = 50;
  static const int morningEndHour = 7;
  static const int morningEndMinute = 4;
  static const int morningLateEndHour = 10;
  static const int morningLateEndMinute = 0;

  static const int afternoonPreparationMinutes = 80;
  static const int afternoonLateToEndMinutes = 60;

  static const int morningHolidayStartHour = 7;
  static const int morningHolidayStartMinute = 30;

  static const int attendanceTimerInterval = 14;
  static const int storeClosedHour = 17;
  static const int storeClosedMinute = 30;
}

// Attendance Time Provider
class TimeProvider extends ChangeNotifier {
  Timer? _timer;
  CustomTime _currentTime = CustomTime.getCurrentTime();

  // Default Break Time
  int _breakHour = 12;
  int _breakMinute = 0;

  String _morningAttendanceMessage = '';
  String _afternoonAttendanceMessage = '';
  String _countDownText = '00:00';

  bool _isMorningCheckedIn = false;
  bool _isAfternoonCheckedIn = false;
  bool _isMorningOnTime = false;
  bool _isAfternoonOnTime = false;
  String _attendanceStatus = '';

  TimeProvider() {
    _startTimer();
  }

  // Getters
  CustomTime get currentTime => _currentTime;
  String get countDownText => _countDownText;
  String get morningAttendanceMessage => _morningAttendanceMessage;
  String get afternoonAttendanceMessage => _afternoonAttendanceMessage;
  String get attendanceStatus => _attendanceStatus;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = CustomTime.getCurrentTime();
      _updateAttendanceState();
      notifyListeners();
    });
  }

  void stopUpdatingTime() {
    _timer?.cancel();
  }

  // Update attendance message and timer
  void _setAttendanceMessage(
      {required DateTime now,
        required DateTime startTime,
        required DateTime endTime,
        required DateTime offTime,
        required DateTime storeCloseTime,
        required String onTimeMessage,
        required String lateMessage,
        required String absentMessage,
        bool isAfternoon = false}) {
    // Check if store is closed
    if (isWithinTimeRange(
        now,
        storeCloseTime,
        storeCloseTime.add(const Duration(hours: 11, minutes: 30)))) {
      _clearMessages(isAfternoon, storeClosedMessage: 'Toko Tutup');
    }
    // Check preparation time before attendance
    else if (isWithinTimeRange(
        now,
        startTime.subtract(const Duration(minutes: 30)),
        startTime)) {
      _setPreparationMessage(isAfternoon);
    }
    // Check on-time and late attendance
    else if (isWithinTimeRange(now, startTime, offTime)) {
      if (isWithinTimeRange(now, startTime, endTime)) {
        _updateAttendanceMessage(onTimeMessage, isAfternoon);
        _setAttendanceStatus('T');
      } else if (isWithinTimeRange(now, endTime, offTime)) {
        _updateAttendanceMessage(lateMessage, isAfternoon);
        _setAttendanceStatus('L');
      }
    }
    // If past off time, mark as absent
    else if (isWithinTimeRange(now, offTime, storeCloseTime)) {
      _updateAttendanceMessage(absentMessage, isAfternoon);
      _setAttendanceStatus('A');
    } else {
      _clearMessages(isAfternoon);
    }
    _countDownText = _currentTime.getIdnTime();
  }

  // Helper functions to manage messages and attendance state
  void _clearMessages(bool isAfternoon, {String? storeClosedMessage}) {
    if (isAfternoon) {
      _afternoonAttendanceMessage = storeClosedMessage ?? '';
      resetAttendanceCheck('afternoon');
    } else {
      _morningAttendanceMessage = storeClosedMessage ?? 'Toko Tutup';
      resetAttendanceCheck('morning');
    }
  }

  void _setPreparationMessage(bool isAfternoon) {
    if (isAfternoon) {
      _afternoonAttendanceMessage = 'Persiapan absen Siang';
    } else {
      _morningAttendanceMessage = 'Persiapan absen Pagi';
    }
  }

  void _updateAttendanceMessage(String message, bool isAfternoon) {
    if (isAfternoon) {
      _afternoonAttendanceMessage = message;
      _isAfternoonOnTime = true;
    } else {
      _morningAttendanceMessage = message;
      _isMorningOnTime = true;
    }
  }

  void _setAttendanceStatus(String status) {
    _attendanceStatus = status;
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

    DateTime storeCloseTime = DateTime(now.year, now.month, now.day,
        AttendanceTimeConfig.storeClosedHour, AttendanceTimeConfig.storeClosedMinute);

    // Morning Attendance Time
    DateTime morningStart = DateTime(now.year, now.month, now.day,
        AttendanceTimeConfig.morningStartHour, AttendanceTimeConfig.morningStartMinute);
    DateTime morningEnd = morningStart.add(const Duration(minutes: AttendanceTimeConfig.attendanceTimerInterval));
    DateTime morningLateEnd = DateTime(now.year, now.month, now.day,
        AttendanceTimeConfig.morningLateEndHour, AttendanceTimeConfig.morningLateEndMinute);

    _setAttendanceMessage(
      now: now,
      startTime: morningStart,
      endTime: morningEnd,
      offTime: morningLateEnd,
      storeCloseTime: storeCloseTime,
      onTimeMessage: 'Berhasil Absen pagi tepat waktu',
      lateMessage: 'Terlambat absen pagi',
      absentMessage: 'Tidak hadir pagi ini',
      isAfternoon: false,
    );

    // Afternoon Attendance Time
    DateTime breakTime = DateTime(now.year, now.month, now.day, _breakHour, _breakMinute);
    DateTime afternoonStart = breakTime.add(const Duration(minutes: AttendanceTimeConfig.afternoonPreparationMinutes - 10));
    DateTime afternoonEnd = breakTime.add(const Duration(minutes: AttendanceTimeConfig.afternoonPreparationMinutes + 4));
    DateTime afternoonLateEnd = breakTime.add(const Duration(minutes: AttendanceTimeConfig.afternoonLateToEndMinutes + AttendanceTimeConfig.afternoonPreparationMinutes));

    _setAttendanceMessage(
      now: now,
      startTime: afternoonStart,
      endTime: afternoonEnd,
      offTime: afternoonLateEnd,
      storeCloseTime: storeCloseTime,
      onTimeMessage: 'Berhasil Absen siang tepat waktu',
      lateMessage: 'Terlambat absen siang',
      absentMessage: 'Tidak hadir siang ini',
      isAfternoon: true,
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
    bool isHoliday = nationalHoliday.isNotEmpty || now.weekday == DateTime.sunday;

    // Start dan end time untuk absen pagi (tepat waktu)
    DateTime startPagi = isHoliday
        ? DateTime(now.year, now.month, now.day, morningHolidayStartHour, morningHolidayStartMinute)
        : DateTime(now.year, now.month, now.day, morningStartHour, morningStartMinute);
    DateTime endPagi = startPagi.add(const Duration(minutes: attendanceTimerInterval));

    // Batas akhir untuk absen telat
    DateTime lateEndPagi = DateTime(now.year, now.month, now.day, morningLateEndHour, morningLateEndMinute);

    // Cek apakah user sudah absen pagi
    bool alreadyCheckedIn = (historyData.tLPagi != null && historyData.tLPagi!.isNotEmpty) ? true : false;

    // Tombol aktif hanya jika belum absen dan waktu dalam jangka yang ditentukan
    return !alreadyCheckedIn &&
        (isWithinTimeRange(now, startPagi, lateEndPagi) ||
            isWithinTimeRange(now, endPagi, lateEndPagi));
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
    DateTime breakTime = DateTime(now.year, now.month, now.day,
        _breakHour, _breakMinute);

    // Start dan end time untuk absen siang (tepat waktu)
    DateTime startSiang = breakTime.add(const Duration(minutes: afternoonPreparationMinutes - 10)); // 10 menit sebelum mulai
    DateTime endSiang = breakTime.add(const Duration(minutes: afternoonPreparationMinutes + 4)); // 4 menit setelah

    // Batas akhir untuk absen telat
    DateTime lateEndSiang = breakTime.add(const Duration(minutes: afternoonLateToEndMinutes + afternoonPreparationMinutes)); // 1 jam setelah break

    // Cek apakah user sudah absen siang
    bool alreadyCheckedIn = (historyData.tLSiang != null && historyData.tLSiang!.isNotEmpty) ? true : false;

    // Tombol aktif hanya jika belum absen dan waktu dalam jangka yang ditentukan
    return !alreadyCheckedIn &&
        (isWithinTimeRange(now, startSiang, lateEndSiang) ||
            isWithinTimeRange(now, endSiang, lateEndSiang));
  }

  bool isWithinTimeRange(DateTime currentTime, DateTime startTime, DateTime endTime) {
    // > || <
    // return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
    // >= || <=
    return (currentTime.isAfter(startTime) || currentTime == startTime) &&
        (currentTime.isBefore(endTime) || currentTime == endTime);
  }

  void updateBreakTime(int hour, int minute) {
    _breakHour = hour;
    _breakMinute = minute;
    notifyListeners();
  }

  void resetAttendanceCheck(String period) {
    if (period == 'morning') {
      _isMorningCheckedIn = false;
      _isMorningOnTime = false;
    } else if (period == 'afternoon') {
      _isAfternoonCheckedIn = false;
      _isAfternoonOnTime = false;
    }
  }

  void onButtonClick(String period) {
    if (period == 'morning' && !_isMorningCheckedIn) {
      _isMorningCheckedIn = true;
    } else if (period == 'afternoon' && !_isAfternoonCheckedIn) {
      _isAfternoonCheckedIn = true;
    }
  }
}