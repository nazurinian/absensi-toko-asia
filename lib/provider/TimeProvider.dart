import 'package:absensitoko/utils/Helper.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:absensitoko/models/CustomTimeModel.dart';

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

  void updateBreakTime(int hour, int minute) {
    _breakHour = hour;
    _breakMinute = minute;
    notifyListeners();
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

  bool isPagiButtonActive() {
    DateTime now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );
    DateTime startPagi = DateTime(now.year, now.month, now.day, 6, 40);
    DateTime endPagi = DateTime(now.year, now.month, now.day, 10, 0);

    return !_checkAbsenPagi
        ? isWithinTimeRange(now, startPagi, endPagi)
        : false;
  }

  bool isSiangButtonActive() {
    DateTime now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );

    DateTime breakTime =
        DateTime(now.year, now.month, now.day, _breakHour, _breakMinute);
    DateTime storeOpenTime = breakTime.add(const Duration(hours: 1));
    DateTime startSiang = storeOpenTime.subtract(const Duration(minutes: 20));
    DateTime offSiang = storeOpenTime.add(const Duration(hours: 1));

    return !_checkAbsenSiang
        ? isWithinTimeRange(now, startSiang, offSiang)
        : false;
  }

  bool isWithinTimeRange(
      DateTime currentTime, DateTime startTime, DateTime endTime) {
    return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
  }

  void onButtonClick(String type) {
    if (type == 'pagi' && !_checkAbsenPagi) {
      _checkAbsenPagi = true;
    } else if (type == 'siang' && !_checkAbsenSiang) {
      _checkAbsenSiang = true;
    }
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
}
