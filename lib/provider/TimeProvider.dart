import 'package:flutter/material.dart';
import 'dart:async';
import 'package:absensitoko/models/CustomTimeModel.dart';

class TimeProvider extends ChangeNotifier {
  Timer? _timer;
  CustomTime _currentTime = CustomTime.getCurrentTime();

  CustomTime _dataTime(String serverTime) =>
      CustomTime.fromServerTime(serverTime);

  CustomTime get currentTime => _currentTime;

  CustomTime dataTime(String serverTime) => _dataTime(serverTime);

  TimeProvider() {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = CustomTime.getCurrentTime();
      notifyListeners();
    });
  }

  void stopUpdatingTime() {
    _timer?.cancel();
  }
}
