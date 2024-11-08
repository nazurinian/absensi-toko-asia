import 'dart:io';
import 'package:absensitoko/api/api_result.dart';
import 'package:absensitoko/api/services/firebase_storage_service.dart';
import 'package:flutter/material.dart';

class StorageProvider extends ChangeNotifier {
  final FirebaseStorageService _firebaseStorageService =
      FirebaseStorageService();

  bool _isLoading = false;
  String? _status;
  String? _message;
  String? _imageUrl;

  bool get isLoading => _isLoading;

  String? get status => _status;

  String? get message => _message;

  String? get imageUrl => _imageUrl;

  Future<ApiResult> uploadProfilePicture(File imageFile, String uid) async {
    _isLoading = true;
    _status = null;
    _message = null;
    _imageUrl = null;

    final response = await _firebaseStorageService
        .uploadProfilePicture(imageFile, uid)
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _message = 'Fetch sheet names operation timed out';
        return ApiResult(status: 'error', message: _message ?? '');
      },
    );

    _status = response.status;
    _message = response.message;
    if (response.status == 'success') {
      _imageUrl = response.data;
    }

    _isLoading = false;
    notifyListeners();
    return ApiResult(
        status: _status ?? '', message: _message ?? '', data: _imageUrl);
  }
}
