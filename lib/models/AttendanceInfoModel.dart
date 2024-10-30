import 'dart:convert';

class AttendanceInfoModel {
  final String? breaktime;
  final String? nationalHoliday;

  AttendanceInfoModel({this.breaktime, this.nationalHoliday});

  // Fungsi untuk mengubah dari Map ke AttendanceModel dengan nilai default
  factory AttendanceInfoModel.fromMap(Map<String, dynamic> map) {
    return AttendanceInfoModel(
      breaktime: map['breaktime'] as String? ?? 'Data belum tersedia',
      nationalHoliday: map['national_holiday'] as String? ?? 'Tidak ada libur',
    );
  }

  // Fungsi untuk mengubah dari AttendanceModel ke Map, tanpa menggunakan .isNotEmpty
  Map<String, dynamic> toMap() {
    return {
      if (breaktime != null && breaktime!.isNotEmpty) 'breaktime': breaktime,
      if (nationalHoliday != null && nationalHoliday!.isNotEmpty) 'national_holiday': nationalHoliday,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return toJson().toString();
  }
}
