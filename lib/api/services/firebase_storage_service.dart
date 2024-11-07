import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:absensitoko/api/api_result.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<ApiResult<String>> uploadProfilePicture(
      File imageFile, String uid) async {
    try {
      Reference storageRef = _storage.ref().child('profile_pictures/$uid');

      UploadTask uploadTask = storageRef.putFile(imageFile);

      // Mendapatkan snapshot dari task upload
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        // Menangani setiap perubahan state dari upload
        switch (snapshot.state) {
          case TaskState.running:
            break;
          case TaskState.paused:
            break;
          case TaskState.success:
            break;
          case TaskState.canceled:
            break;
          case TaskState.error:
            break;
        }
      });

      // Menunggu task upload selesai
      TaskSnapshot snapshot = await uploadTask;

      // Mendapatkan URL download dari file yang telah diupload
      String downloadURL = await snapshot.ref.getDownloadURL();

      return ApiResult(
        status: 'success',
        message: 'Berhasil mengupload gambar',
        data: downloadURL,
      );
    } catch (e) {
      // Menangani error yang terjadi selama proses upload
      return ApiResult(
        status: 'error',
        message: 'Gagal mengupload gambar: $e',
      );
    }
  }
}
