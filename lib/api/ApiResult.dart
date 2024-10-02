import 'package:absensitoko/models/AttendanceModel.dart';

class ApiResult<T> {
  final String status;
  final String? message;
  final T? data;

  ApiResult({
    required this.status,
    this.message,
    this.data,
  });

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResult(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data,
      };

/*  static List<Pembukuan> fromJsonList(dynamic json) {
    return (json as List<dynamic>)
        .map((item) => Pembukuan.fromJson(item as Map<String, dynamic>))
        .toList();
  }*/
}
