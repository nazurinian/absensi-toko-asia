/*
import 'package:absensitoko/utils/DisplaySize.dart';
import 'package:flutter/material.dart';

class TimePicker {
  static void customTime(BuildContext context, String schedule, int initHour,
      int initMinute, Function(TimeOfDay) onSelecttime) {
    showTimePicker(
      helpText: schedule,
      initialTime: TimeOfDay(hour: initHour, minute: initMinute),
      initialEntryMode: TimePickerEntryMode.dial,
      context: context,
      builder: (context, child) {
        return SafeArea(
          child: Container(
            margin: EdgeInsets.symmetric(
                vertical: screenHeight(context) * 0.08,
                horizontal: screenWidth(context) * 0.08),
            child: child!,
          ),
        );
      },
    ).then(
      (time) {
        if (time != null) {
          onSelecttime(time);
        }
      },
    );
  }
}
*/
