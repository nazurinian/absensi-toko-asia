import 'package:absensitoko/utils/display_size_util.dart';
import 'package:flutter/material.dart';

class TimePicker {
  static void customTime(BuildContext context, String schedule, {int initHour = 12, int initMinute = 0, required Function(TimeOfDay) onSelecttime}) {
    showTimePicker(
      helpText: schedule,
      initialTime: TimeOfDay(hour: initHour, minute: initMinute),
      initialEntryMode: TimePickerEntryMode.dial,
      context: context,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(8),
              child: child!,
            ),
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
