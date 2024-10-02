import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:absensitoko/api/ApiResult.dart';

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
            print('Upload is running...');
            break;
          case TaskState.paused:
            print('Upload is paused.');
            break;
          case TaskState.success:
            print('Upload completed successfully.');
            break;
          case TaskState.canceled:
            print('Upload was canceled.');
            break;
          case TaskState.error:
            print('Upload failed.');
            break;
        }
      });

      // Menunggu task upload selesai
      TaskSnapshot snapshot = await uploadTask;

      // Mendapatkan URL download dari file yang telah diupload
      String downloadURL = await snapshot.ref.getDownloadURL();
      print('Download URL: $downloadURL');

      return ApiResult(
        status: 'success',
        message: 'Berhasil mengupload gambar',
        data: downloadURL,
      );
    } catch (e) {
      // Menangani error yang terjadi selama proses upload
      print('Error uploading image: $e');
      return ApiResult(
        status: 'error',
        message: 'Gagal mengupload gambar: $e',
      );
    }
  }
}

/*
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfilePicture(File imageFile, String uid) async {
    try {
      Reference storageRef = _storage.ref().child('profile_pictures/$uid');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
*/
