/*
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

  CustomTime _dataTime(String serverTime) =>
      CustomTime.fromServerTime(serverTime);

  CustomTime get currentTime => _currentTime;

  String get countDownText => _countDownText;

  String get morningAttendanceMessage => _morningAttendanceMessage;

  String get afternoonAttendanceMessage => _afternoonAttendanceMessage;

  CustomTime dataTime(String serverTime) => _dataTime(serverTime);

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

  // Morning attendance logic
  void _updateAttendanceState() {
    DateTime now = DateTime(
      _currentTime.getYear(),
      _currentTime.getMonth(),
      _currentTime.getDay(),
      _currentTime.getHour(),
      _currentTime.getMinute(),
      _currentTime.getSecond(),
    );

    // Morning Attendance Time
    DateTime startPagi = DateTime(now.year, now.month, now.day, 6, 40);
    DateTime endPagi = DateTime(now.year, now.month, now.day, 7, 10);
    DateTime offPagi =
        DateTime(now.year, now.month, now.day, 10, 00); // Off time at 10:00

    // Morning Attendance Messages and Countdown
    if (now.isBefore(startPagi.subtract(const Duration(minutes: 30)))) {
      _morningAttendanceMessage = 'Toko belum buka';
      _countDownText = _currentTime.getIdnTime(); // Regular time display
    } else if (now.isBefore(startPagi)) {
      _morningAttendanceMessage = 'Akan Memasuki Waktu Absensi Pagi';
      _countDownText =
          _formatDuration(startPagi.difference(now)); // Countdown 30 min
    } else if (isWithinTimeRange(now, startPagi, endPagi)) {
      _morningAttendanceMessage = 'Menit Absensi Tepat Waktu';
      _countDownText =
          _formatDuration(endPagi.difference(now)); // Countdown attendance
    } else if (isWithinTimeRange(now, endPagi, offPagi)) {
      _morningAttendanceMessage = 'Anda terlambat masuk pagi';
      _countDownText = _currentTime.getIdnTime(); // Regular time display
    } else if (now.isBefore(DateTime(now.year, now.month, now.day, 17, 30))) {
      _morningAttendanceMessage = 'Anda tidak masuk pagi hari ini';
      _countDownText = _currentTime.getIdnTime(); // Regular time display
    } else {
      _morningAttendanceMessage = ''; // Empty after store closes
      _countDownText = _currentTime.getIdnTime();
    }

    // Afternoon Attendance Time
    DateTime breakTime = DateTime(
        now.year, now.month, now.day, _breakHour, _breakMinute); // Jam 13
    DateTime storeOpenSiangTime = breakTime.add(const Duration(hours: 1)); // Jam 14
    DateTime startSiang = storeOpenSiangTime.subtract(
        const Duration(minutes: 20)); // Attendance starts 20 min before store open;
    DateTime endSiang = startSiang
        .add(const Duration(minutes: 30)); // 30 menit durasi absensi siang dari start
    DateTime offSiang = storeOpenSiangTime
        .add(const Duration(hours: 1)); // Off time 1 hour after store open
    DateTime storeCloseTime =
        DateTime(now.year, now.month, now.day, 17, 30); // Jam 17:30

    // Afternoon Attendance Messages and Countdown
    if (now.isAfter(DateTime(now.year, now.month, now.day, 17, 30)) &&
        now.isBefore(DateTime(
            now.year, now.month, now.day, offPagi.hour, offPagi.minute))) {
      _afternoonAttendanceMessage =
          ''; // Blank between 17:30 and 12:00 the next day
    } else if (isWithinTimeRange(
        now, breakTime, startSiang.subtract(const Duration(minutes: 30)))) {
      print(
          'Waktu ISHOMA, Jam: ${breakTime.hour}:${breakTime.minute} - ${storeOpenSiangTime.hour}:${storeOpenSiangTime.minute}\nDapat memulai absen jam: ${startSiang.hour}:${startSiang.minute}');
      _afternoonAttendanceMessage =
          'Waktu ISHOMA, Jam: ${breakTime.hour}:${breakTime.minute} - ${storeOpenSiangTime.hour}:${storeOpenSiangTime.minute}\nDapat memulai absen jam: ${startSiang.hour}:${startSiang.minute}';
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(
        now, startSiang.subtract(const Duration(minutes: 30)), startSiang)) {
      print(
          'Persiapan 30 menit Sebelum masuk waktu absensi siang jam: ${startSiang.hour}:${startSiang.minute} - ${endSiang.hour}:${endSiang.minute}');
      _afternoonAttendanceMessage =
          'Persiapan 30 menit Sebelum masuk waktu absensi siang jam: ${startSiang.hour}:${startSiang.minute} - ${endSiang.hour}:${endSiang.minute}';
      _countDownText =
          _formatDuration(startSiang.difference(now)); // Countdown to start
    } else if (isWithinTimeRange(now, startSiang, storeCloseTime) &&
        _checkAbsenSiang) {
      _countDownText = _currentTime.getIdnTime();
      if (isWithinTimeRange(now, startSiang, endSiang)) {
        _afternoonAttendanceMessage = 'Absen siang tepat waktu';
      } else if (isWithinTimeRange(now, endSiang, storeCloseTime)) {
        _afternoonAttendanceMessage = 'Absen siang lewat waktu (Terlambat)';
      }
    } else if (isWithinTimeRange(now, startSiang, endSiang)) {
      print(
          'Masuk waktu absen, Jam : ${startSiang.hour}:${startSiang.minute} - ${endSiang.hour}:${endSiang.minute}');
      _afternoonAttendanceMessage = 'Menit Absensi Tepat Waktu';
      _countDownText =
          _formatDuration(endSiang.difference(now)); // Countdown attendance
    } else if (isWithinTimeRange(now, startSiang, offSiang)) {
      print(
          'Melewati waktu setelah absen, Jam Selesai : ${endSiang.hour}:${endSiang.minute}');
      _afternoonAttendanceMessage = 'Anda terlambat masuk toko siang ini';
      _countDownText = _currentTime.getIdnTime(); // Regular time display
    } else if (isWithinTimeRange(now, offSiang, storeCloseTime)) {
      print(
          'Tidak hadir siang lebih dari 1 jam, Batas absen jam : ${offSiang.hour}:${offSiang.minute}');
      _afternoonAttendanceMessage = 'Anda tidak hadir siang hari ini karena tidak hadir lebih dari 1 jam';
      _countDownText = _currentTime.getIdnTime(); // Regular time display
    } else {
      _afternoonAttendanceMessage = '';
      _countDownText = _currentTime.getIdnTime(); // Empty before start
      _checkAbsenSiang = false;
    }
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
    DateTime startPagi = DateTime(now.year, now.month, now.day, 6, 40); // 06:40
    DateTime endPagi = DateTime(now.year, now.month, now.day, 10, 0); // 10:00

    return isWithinTimeRange(now, startPagi, endPagi);
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

    DateTime breakTime = DateTime(
        now.year, now.month, now.day, _breakHour, _breakMinute); // Jam 13
    DateTime storeOpenTime = breakTime.add(const Duration(hours: 1)); // Jam 14
    DateTime startSiang = storeOpenTime.subtract(
        const Duration(minutes: 20)); // Attendance starts 20 min before store o open
    DateTime offSiang = storeOpenTime
        .add(const Duration(hours: 1)); // Off time 1 hour after store open

    return !_checkAbsenSiang
        ? isWithinTimeRange(now, startSiang, offSiang)
        : false;
  }

  bool isWithinTimeRange(
      DateTime currentTime, DateTime startTime, DateTime endTime) {
    return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
  }

  void onButtonClick(String type) {
    if (type == 'pagi') {
      _checkAbsenPagi = true;
    } else if (type == 'siang') {
      _checkAbsenSiang = true;
    }
  }

// Reset pesan absensi setelah waktu tutup toko (17:30)
*/
/*  void resetAttendanceMessages() {
    _morningAttendanceMessage = '';
    _afternoonAttendanceMessage = '';
    notifyListeners();
  }*/ /*

}
*/ // yg atas ini udah mantep bagian kode onclick dan sore

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

  CustomTime get currentTime => _currentTime;

  String get countDownText => _countDownText;

  String get morningAttendanceMessage => _morningAttendanceMessage;

  String get afternoonAttendanceMessage => _afternoonAttendanceMessage;

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
      } else {
        _morningAttendanceMessage = 'Toko Tutup';
      }
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(
        now,
        startTime.subtract(const Duration(hours: 1, minutes: 40)),
        startTime.subtract(const Duration(minutes: 30))) && ! isAfternoon) {
      _morningAttendanceMessage = 'Toko Belum Buka';
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(
          now,
          offTime.subtract(const Duration(hours: 2)),
          startTime.subtract(const Duration(minutes: 30)),
        ) &&
        isAfternoon) {
      DateTime breakTime = offTime.subtract(const Duration(hours: 2));
      DateTime storeOpenSiangTime = offTime.subtract(const Duration(hours: 1));
      _afternoonAttendanceMessage =
          'Waktu ISHOMA, Jam: ${breakTime.hour}:${breakTime.minute} - ${storeOpenSiangTime.hour}:${storeOpenSiangTime.minute}\nDapat memulai absen jam: ${startTime.hour}:${startTime.minute}';
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(
        now, startTime.subtract(const Duration(minutes: 30)), startTime)) {
      if (isAfternoon) {
        _afternoonAttendanceMessage =
            'Persiapan 30 menit sebelum absen ${isAfternoon ? 'Siang' : 'Pagi'} dimulai';
      } else {
        _morningAttendanceMessage =
            'Persiapan 30 menit sebelum absen ${isAfternoon ? 'Siang' : 'Pagi'} dimulai';
      }
      _countDownText = _formatDuration(startTime.difference(now));
    } else if (isWithinTimeRange(now, startTime, storeCloseTime) &&
        (_checkAbsenPagi || _checkAbsenSiang)) {
      if (isAfternoon) {
        if (isWithinTimeRange(now, startTime, endTime)) {
          _afternoonAttendanceMessage = attendanceOnTime;
          _afternoonAttendanceMessage = 'Absen siang tepat waktu';
        } else if (isWithinTimeRange(now, endTime, storeCloseTime)) {
          _afternoonAttendanceMessage = attendanceOnLateTime;
          _afternoonAttendanceMessage = 'Absen siang lewat waktu (Terlambat)';
        }
      } else {
        if (isWithinTimeRange(now, startTime, endTime)) {
          _morningAttendanceMessage = attendanceOnTime;
          _morningAttendanceMessage = 'Absen pagi tepat waktu';
        } else if (isWithinTimeRange(now, endTime, storeCloseTime)) {
          _morningAttendanceMessage = attendanceOnLateTime;
          _morningAttendanceMessage = 'Absen pagi lewat waktu (Terlambat)';
        }
      }
      _countDownText = _currentTime.getIdnTime();
    } else if (isWithinTimeRange(now, startTime, endTime)) {
      if (isAfternoon) {
        _afternoonAttendanceMessage = onTimeMessage;
      } else {
        _morningAttendanceMessage = onTimeMessage;
      }
      _countDownText = _formatDuration(endTime.difference(now));
    } else if (isWithinTimeRange(now, startTime, offTime)) {
      if (isAfternoon) {
        _afternoonAttendanceMessage = lateMessage;
      } else {
        _morningAttendanceMessage = lateMessage;
      }
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
        _checkAbsenSiang = false;
      } else {
        _morningAttendanceMessage = '';
        _checkAbsenPagi = false;
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
    DateTime startPagi = DateTime(now.year, now.month, now.day, 6, 40);
    DateTime endPagi = startPagi.add(const Duration(minutes: 30));
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
      'Absen siang tepat waktu',
      'Absen siang lewat waktu (Terlambat)',
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
    } else if (type == 'siang' && !_checkAbsenPagi) {
      _checkAbsenSiang = true;
    }
  }
}

// if (now.isBefore(startTime.subtract(const Duration(minutes: 30)))) {
//   if (isAfternoon) {
//     _afternoonAttendanceMessage = 'Toko belum buka';
//   } else {
//     _morningAttendanceMessage = 'Toko belum buka';
//   }
//   _countDownText = _currentTime.getIdnTime();
//------------------------------------------------------------
// } else if (now.isAfter(storeCloseTime) &&
//     now.isBefore(
//         storeCloseTime.subtract(const Duration(hours: 11, minutes: 20))) &&
//     !isAfternoon) {
//   _morningAttendanceMessage = 'Toko Tutup';
//   _countDownText = _currentTime.getIdnTime();
// } else if (now.isAfter(storeCloseTime) &&
//     now.isBefore(
//         storeCloseTime.subtract(const Duration(hours: 7, minutes: 30))) &&
//     isAfternoon) {
//   _afternoonAttendanceMessage = '';
//   _countDownText = _currentTime.getIdnTime();
