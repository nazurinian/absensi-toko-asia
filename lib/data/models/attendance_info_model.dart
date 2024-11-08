import 'dart:convert';

class AttendanceInfoModel {
  final String? breakTime;
  final String? nationalHoliday;

  AttendanceInfoModel({this.breakTime, this.nationalHoliday});

  // Fungsi untuk mengubah dari Map ke AttendanceModel dengan nilai default
  factory AttendanceInfoModel.fromMap(Map<String, dynamic> map) {
    return AttendanceInfoModel(
      breakTime: map['break_time'] as String,
      nationalHoliday: map['national_holiday'] as String,
    );
  }

  // Fungsi untuk mengubah dari AttendanceModel ke Map, tanpa menggunakan .isNotEmpty
  Map<String, dynamic> toMap() {
    return {
      // if (breakTime != null && breakTime!.isNotEmpty) 'break_time': breakTime,
      // if (nationalHoliday != null && nationalHoliday!.isNotEmpty) 'national_holiday': nationalHoliday,
      'break_time': breakTime,
      'national_holiday': nationalHoliday,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return toJson().toString();
  }
}
