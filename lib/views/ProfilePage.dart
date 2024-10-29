import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:absensitoko/models/UserModel.dart';
import 'package:absensitoko/provider/StorageProvider.dart';
import 'package:absensitoko/provider/UserProvider.dart';
import 'package:absensitoko/themes/fonts/Fonts.dart';
import 'package:absensitoko/utils/BaseState.dart';
import 'package:absensitoko/utils/DialogUtils.dart';
import 'package:absensitoko/utils/Helper.dart';
import 'package:absensitoko/utils/ListItem.dart';
import 'package:absensitoko/utils/LoadingDialog.dart';
import 'package:absensitoko/utils/ProfileAvatar.dart';
import 'package:absensitoko/views/DetailImagePage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends BaseState<ProfilePage> {
  late UserProvider _userProvider;
  UserModel? _user;
  List<String> _registeredAccount = [];
  final ImagePicker _picker = ImagePicker();
  final String _heroTag = 'profile-picture';
  String? _selectedCountryCode = '+62';
  bool _dataIsChanged = false;

  final Map<String, TextEditingController> _controllers = {
    'Nama': TextEditingController(),
    // 'Email': TextEditingController(),
    'Kota Asal': TextEditingController(),
    'Bagian': TextEditingController(),
    'Nomor Telepon': TextEditingController(),
    // 'Role': TextEditingController(),
  };

  final Map<String, FocusNode> _focusNodes = {
    'Nama': FocusNode(),
    // 'Email': FocusNode(),
    'Kota Asal': FocusNode(),
    'Bagian': FocusNode(),
    'Nomor Telepon': FocusNode(),
    // 'Role': FocusNode(),
  };

  Future<void> _fetchUserData() async {
    UserModel? userData = _userProvider.currentUser;

    if (!_userProvider.userDataIsLoaded) {
      try {
        await _userProvider.loadUserSession();
        final userDataSession = _userProvider.currentUserSession;

        final message = await _userProvider.getUser(userDataSession!.uid);

        if (message.status == 'success') {
          userData = _userProvider.currentUser;
          setState(() {
            _user = userData;
            if (_user?.phoneNumber?.isEmpty ?? true) {
              _selectedCountryCode = '+62';
            } else {
              _selectedCountryCode =
                  getCountryFromPhoneNumber(_user!.phoneNumber!);
            }
          });
          ToastUtil.showToast('Berhasil memperoleh data', ToastStatus.success);
        } else {
          ToastUtil.showToast(message.message ?? '', ToastStatus.error);
        }
      } catch (e) {
        ToastUtil.showToast('Gagal memperoleh data', ToastStatus.error);
      }
    } else {
      setState(() {
        _user = userData;
        if (_user?.phoneNumber?.isEmpty ?? true) {
          _selectedCountryCode = '+62';
        } else {
          _selectedCountryCode = getCountryFromPhoneNumber(_user!.phoneNumber!);
        }
      });
    }
    if (_user!.displayName!.isEmpty) {
      _getListAccountName();
    }
  }

  Future<void> _updateUserProfileData(
    String title, {
    String? displayName,
    String? department,
    String? phoneNumber,
    String? photoURL,
  }) async {
    if (_user != null) {
      try {
        await _userProvider.updateUserProfile(
          _user!.uid,
          displayName: displayName,
          department: department,
          phoneNumber: phoneNumber,
          photoURL: photoURL,
        );

        setState(() {
          _user = _userProvider.currentUser;
        });
      } catch (e) {
        ToastUtil.showToast(
            'Gagal mengubah ${title.toLowerCase()}', ToastStatus.error);
      } finally {
        safeContext((context) {
          LoadingDialog.hide(context);
        });
        ToastUtil.showToast(
            'Berhasil mengubah ${title.toLowerCase()}', ToastStatus.success);
      }
    }
  }

  void _updateProfileDataSession(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void _updateProcess(String title) {
    String dataUpdate = capitalizeEachWord(_controllers[title]!.text).trim();

    if (dataUpdate == '') {
      ToastUtil.showToast('Tidak boleh kosong', ToastStatus.error);
      return;
    }

    LoadingDialog.show(context);
    if (title == 'Nama' && _user!.displayName!.isEmpty) {
      _updateUserProfileData(title, displayName: dataUpdate);
      _updateProfileDataSession('displayName', dataUpdate);
    } else if (title == 'Bagian') {
      _updateUserProfileData(title, department: dataUpdate);
      _updateProfileDataSession('department', dataUpdate);
    } else if (title == 'Nomor Telepon') {
      String hpPenerima;
      if (_selectedCountryCode == '+62') {
        hpPenerima = _selectedCountryCode! + formatPhoneNumber(dataUpdate);
      } else {
        hpPenerima = _selectedCountryCode! + dataUpdate;
      }
      _updateUserProfileData(title, phoneNumber: hpPenerima);
      _updateProfileDataSession('phoneNumber', hpPenerima);
    }

    _dataIsChanged = true;
    _controllers[title]!.clear();
    _focusNodes[title]!.unfocus();
  }

  /// Ini Percobaan 1, masih default
/*  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);
      final prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid != null) {
        LoadingDialog.show(context);
        final response =
            await _storageService.uploadProfilePicture(imageFile, uid);
        String? imageUrl = response.data;
        if (response.status == 'success' && imageUrl != null) {
          print('Berhasil mengupload gambar');
          ToastUtil.showToast(
              'Berhasil mengupload gambar', ToastStatus.success);
          await _updateUserProfileData("Foto Profil", photoURL: imageUrl);
          _updateProfileDataSession('photoURL', imageUrl);
        } else {
          print('Gagal mengupload gambar');
          ToastUtil.showToast('Gagal mengupload gambar', ToastStatus.error);
        }
      } else {
        print('UID tidak ditemukan');
        ToastUtil.showToast('UID tidak ditemukan', ToastStatus.error);
      }
    }
  }*/

  /// Ini percobaan 2, udah bisa image croppernya, ada activity image cropper yg ditambahkan
/*  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Convert XFile to File
      File imageFile = File(image.path);

      // Crop the image
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Gambar',
            toolbarColor: Colors.blue,  // Warna AppBar
            toolbarWidgetColor: Colors.white,  // Warna teks dan ikon
            statusBarColor: Colors.blueAccent,  // Warna status bar
            backgroundColor: Colors.black,  // Warna latar belakang layar crop
            activeControlsWidgetColor: Colors.blue,  // Warna kontrol aktif
            initAspectRatio: CropAspectRatioPreset.original,  // Rasio aspek awal
            lockAspectRatio: false,  // Mengunci rasio aspek
          ),
          IOSUiSettings(
            title: 'Edit Gambar',  // Judul di iOS
            minimumAspectRatio: 1.0,  // Rasio aspek minimum
          ),
        ],
      );

      if (croppedFile != null) {
        File croppedImageFile = File(croppedFile.path);

        final prefs = await SharedPreferences.getInstance();
        String? uid = prefs.getString('uid');

        if (uid != null) {
          LoadingDialog.show(context);
          final response =
          await _storageService.uploadProfilePicture(croppedImageFile, uid);
          String? imageUrl = response.data;
          if (response.status == 'success' && imageUrl != null) {
            print('Berhasil mengupload gambar');
            ToastUtil.showToast(
                'Berhasil mengupload gambar', ToastStatus.success);
            await _updateUserProfileData("Foto Profil", photoURL: imageUrl);
            _updateProfileDataSession('photoURL', imageUrl);
          } else {
            print('Gagal mengupload gambar');
            ToastUtil.showToast('Gagal mengupload gambar', ToastStatus.error);
          }
        } else {
          print('UID tidak ditemukan');
          ToastUtil.showToast('UID tidak ditemukan', ToastStatus.error);
        }
      } else {
        print('Gambar tidak dicrop');
        ToastUtil.showToast('Gambar tidak dicrop', ToastStatus.error);
      }
    }
  }*/

  /// Ini percobaan 3, bisa dari kamera juga:
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      // Convert XFile to File
      File imageFile = File(image.path);
      // Menyimpan gambar ke galeri
      // await GallerySaver.saveImage(imageFile.path);

      // Crop the image
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Gambar',
            toolbarColor: Colors.blue,
            // Warna AppBar
            toolbarWidgetColor: Colors.white,
            // Warna teks dan ikon
            statusBarColor: Colors.blueAccent,
            // Warna status bar
            backgroundColor: Colors.black,
            // Warna latar belakang layar crop
            activeControlsWidgetColor: Colors.blue,
            // Warna kontrol aktif
            initAspectRatio: CropAspectRatioPreset.original,
            // Rasio aspek awal
            lockAspectRatio: false, // Mengunci rasio aspek
          ),
          IOSUiSettings(
            title: 'Edit Gambar', // Judul di iOS
            minimumAspectRatio: 1.0, // Rasio aspek minimum
          ),
        ],
      );

      if (croppedFile != null) {
        File croppedImageFile = File(croppedFile.path);
        // await GallerySaver.saveImage(croppedImageFile.path); // Untuk Nyimpen ke galeri hasil cropnya

        final prefs = await SharedPreferences.getInstance();
        String? uid = prefs.getString('uid');

        if (uid != null) {
          // LoadingDialog.show(context);
          // final response =
          //     await _storageService.uploadProfilePicture(croppedImageFile, uid);

          /// Ganti pake state provider biar sama semuanya
          safeContext(
            (context) async {
              LoadingDialog.show(context);
              final response =
                  await Provider.of<StorageProvider>(context, listen: false)
                      .uploadProfilePicture(croppedImageFile, uid);
              String? imageUrl = response.data;
              if (response.status == 'success' && imageUrl != null) {
                print('Berhasil mengupload gambar');
                ToastUtil.showToast(
                    'Berhasil mengupload gambar', ToastStatus.success);
                await _updateUserProfileData("Foto Profil", photoURL: imageUrl);
                _updateProfileDataSession('photoURL', imageUrl);
              } else {
                safeContext(
                  (context) => LoadingDialog.hide(context),
                );
                print('Gagal mengupload gambar');
                ToastUtil.showToast(
                    'Gagal mengupload gambar', ToastStatus.error);
              }
            },
          );
        } else {
          print('UID tidak ditemukan');
          ToastUtil.showToast('UID tidak ditemukan', ToastStatus.error);
        }
      } else {
        print('Gambar tidak dicrop');
        ToastUtil.showToast('Gambar tidak dicrop', ToastStatus.error);
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(10.0)),
                ),
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.mediaLibrary.request();
    if (status.isGranted) {
      safeContext(
        (context) {
          DialogUtils.showConfirmationDialog(
              context: context,
              title: "Update Foto Profil",
              content: const Text(
                  'Yakin ingin melakukan update data profil, Foto Profil?'),
              onConfirm: () => _showImageSourceActionSheet(context));
        },
      );
    } else {
      print('Izin ditolak');
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

  void _getListAccountName() async {
    try {
      final response = await _userProvider.getAllUsers();
      if (response.status == 'success') {
        final listUserName = _userProvider.listAllUser
            .map((user) => user.displayName ?? '')
            .toList();
        setState(() {
          _registeredAccount = listUserName;
        });
        print('Daftar list akun: $_registeredAccount');
        print('Berhasil memperoleh list user');
        ToastUtil.showToast(
            'Berhasil memperoleh list user', ToastStatus.success);
      } else {
        print('Gagal memperoleh list user');
        ToastUtil.showToast('Gagal memperoleh list user', ToastStatus.error);
      }
    } catch (e) {
      print('Error: $e');
      ToastUtil.showToast('Error: $e', ToastStatus.error);
    }
  }

  void _unFocus() {
    _focusNodes.forEach((key, focusNode) {
      if (focusNode.hasFocus) {
        focusNode.unfocus();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    _fetchUserData();
  }

  @override
  void dispose() {
    super.dispose();
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    _focusNodes.forEach((key, focusNode) {
      focusNode.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context, _dataIsChanged);
          },
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (userProvider.status != 'success') {
            return Center(
                child: Text(
              'Error: ${userProvider.message}',
              textAlign: TextAlign.center,
            ));
          } else if (_user == null) {
            return const Center(child: Text('No data available'));
          } else {
            return GestureDetector(
              onTap: _unFocus,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        borderOnForeground: true,
                        borderRadius: BorderRadius.circular(80),
                        elevation: 25,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailProfilePicturePage(
                                  imageUrl: _user?.photoURL ?? '',
                                  heroTag: _heroTag),
                            ),
                          ),
                          child: ProfileAvatar(
                            pageName: 'Profile',
                            photoURL: _user!.photoURL,
                            heroTag: _heroTag,
                            onEdit: _requestPermissions,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildTextFromListTile('Nama', _user!.displayName!,
                          isEnabled:
                              _user!.displayName!.isEmpty ? true : false),
                      _buildTextFromListTile('Email', _user!.email!,
                          isEnabled: false),
                      _buildTextFromListTile('Bagian', _user!.department!),
                      _buildTextFromListTile('Nomor Telepon',
                          formatPhoneNumber(_user!.phoneNumber!)),
                      _buildTextFromListTile('Role', _user!.role!.toUpperCase(),
                          isEnabled: false),
                      const SizedBox(
                        height: 25,
                      ),
                      /*Padding(
                        padding: const EdgeInsets.symmetric(vertical: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: Image.asset(
                                      AppImage.najwa.path,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  SizedBox(
                                    height: 70,
                                    width: 70,
                                    child: Image.asset(
                                      AppImage.najwa.path,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: Image.asset(
                                      AppImage.najwa.path,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),*/
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTextFromListTile(
    String title,
    String subtitle, {
    bool isEnabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            // style: FontTheme.size16Italic(color: Colors.grey),
          ),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _controllers[title],
              focusNode: _focusNodes[title],
              keyboardType: title == 'Nomor Telepon'
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                enabled: isEnabled,
                hintText: subtitle,
                hintStyle: TextStyle(
                  color: isEnabled ?  Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withAlpha(400),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                prefixIcon: title == 'Nomor Telepon'
                    ? Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            autofocus: true,
                            value: _selectedCountryCode,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCountryCode = newValue;
                              });
                            },
                            items: countryCodes.entries
                                .map<DropdownMenuItem<String>>((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.key),
                              );
                            }).toList()
                              ..sort((a, b) => a.child
                                  .toString()
                                  .compareTo(b.child.toString())),
                          ),
                        ),
                      )
                    : null,
                suffix: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    String infoUpdate =
                        capitalizeEachWord(_controllers[title]!.text.trim());
                    if (infoUpdate.isEmpty) {
                      DialogUtils.popUp(context,
                          content: const Center(
                              child: Text('Isian tidak boleh kosong')));
                    } else {
                      if (title == 'Nama') {
                        if (_registeredAccount.contains(infoUpdate)) {
                          DialogUtils.popUp(context,
                              content: const Center(
                                  child: Text(
                                'Nama sudah terdaftar, silahkan gunakan nama lain',
                                textAlign: TextAlign.center,
                              )));
                          return;
                        }
                      }
                      if (title == 'Nomor Telepon') {
                        infoUpdate = _selectedCountryCode! +
                            formatPhoneNumber(infoUpdate);
                      }
                      DialogUtils.showConfirmationDialog(
                        context: context,
                        title: 'Update $title',
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Yakin ingin melakukan update ${capitalizeEachWord(title)}?',
                              textAlign: TextAlign.justify,
                            ),
                            Text(
                              infoUpdate,
                              textAlign: TextAlign.justify,
                              // style: FontTheme.size18Bold(color: Colors.green),
                            ),
                          ],
                        ),
                        onConfirm: () => _updateProcess(title),
                      );
                      if (title == 'Nama') {
                        DialogUtils.popUp(
                          context,
                          content: const Center(
                            child: Text(
                              'Perubahan Nama hanya dapat dilakukan sekali ini saja, setelah anda memproses update ini anda tidak akan dapat mengubah nama anda lagi, jadi pastikan nama yang anda pilih sudah sesuai.\nTerima Kasih.',
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
