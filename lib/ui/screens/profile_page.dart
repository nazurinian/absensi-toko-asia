import 'dart:io';
import 'package:absensitoko/data/providers/connection_provider.dart';
import 'package:absensitoko/utils/helpers/general_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:absensitoko/data/models/user_model.dart';
import 'package:absensitoko/data/providers/storage_provider.dart';
import 'package:absensitoko/data/providers/user_provider.dart';
import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/utils/base/base_state.dart';
import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:absensitoko/ui/widgets/profile_avatar.dart';
import 'package:absensitoko/ui/screens/detail_image_page.dart';
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
  bool _hasShownDialog = false;
  bool _lastConnectionStatus = true;

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

  void _updateProcess(String title) {
    String dataUpdate = capitalizeEachWord(_controllers[title]!.text).trim();

    if (dataUpdate == '') {
      ToastUtil.showToast('Tidak boleh kosong', ToastStatus.error);
      return;
    }

    LoadingDialog.show(context);
    if (title == 'Nama' && _user!.displayName!.isEmpty) {
      _updateUserProfileData(title, displayName: dataUpdate);
    } else if (title == 'Bagian') {
      _updateUserProfileData(title, department: dataUpdate);
    } else if (title == 'Nomor Telepon') {
      String hpPenerima;
      if (_selectedCountryCode == '+62') {
        hpPenerima = _selectedCountryCode! + formatPhoneNumber(dataUpdate);
      } else {
        hpPenerima = _selectedCountryCode! + dataUpdate;
      }
      _updateUserProfileData(title, phoneNumber: hpPenerima);
    }

    _dataIsChanged = true;
    _controllers[title]!.clear();
    _focusNodes[title]!.unfocus();
  }

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
                ToastUtil.showToast(
                    'Berhasil mengupload gambar', ToastStatus.success);
                await _updateUserProfileData("Foto Profil", photoURL: imageUrl);
              } else {
                safeContext(
                  (context) => LoadingDialog.hide(context),
                );
                ToastUtil.showToast(
                    'Gagal mengupload gambar', ToastStatus.error);
              }
            },
          );
        } else {
          ToastUtil.showToast('UID tidak ditemukan', ToastStatus.error);
        }
      } else {
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
        ToastUtil.showToast(
            'Berhasil memperoleh list user', ToastStatus.success);
      } else {
        ToastUtil.showToast('Gagal memperoleh list user', ToastStatus.error);
      }
    } catch (e) {
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

  void _showConnectionStatusDialog(bool isConnected) {
    if (isConnected && _hasShownDialog) {
      // Tampilkan popup ketika koneksi normal
      ToastUtil.showToast('Kembali terhubung ke internet', ToastStatus.success);
    } else if (!isConnected && _lastConnectionStatus) {
      // Tampilkan popup ketika koneksi terputus
      _hasShownDialog = true; // Tandai bahwa popup telah ditampilkan
      ToastUtil.showToast('Koneksi internet terputus', ToastStatus.error);
    }

    _lastConnectionStatus = isConnected; // Update status koneksi terakhir
  }

  @override
  void initState() {
    super.initState();

    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    _lastConnectionStatus = connectionProvider.isConnected;
    _showConnectionStatusDialog(_lastConnectionStatus); // Tampilkan dialog saat awal

    _userProvider = Provider.of<UserProvider>(context, listen: false);
    _fetchUserData();

    _focusNodes.forEach((title, focusNode) {
      focusNode.addListener(() {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controllers.forEach((key, controller) {
      controller.dispose();
    });

    _focusNodes.forEach((key, focusNode) {
      focusNode.removeListener(() {});
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
      body: Consumer<ConnectionProvider>(
          builder: (context, connectionProvider, child) {
            // Jika status koneksi berubah, tampilkan popup sesuai status
            if (connectionProvider.isConnected != _lastConnectionStatus) {
              _showConnectionStatusDialog(connectionProvider.isConnected);
            }

          return Consumer<UserProvider>(
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
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    width: double.infinity,
                    height: double.infinity,
                    child: SingleChildScrollView(
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
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          );
        }
      ),
    );
  }

  Widget _buildTextFromListTile(
    String title,
    String subtitle, {
    bool isEnabled = true,
  }) {
    // Pastikan FocusNode sudah ada atau buat baru jika belum
    if (_focusNodes[title] == null) {
      _focusNodes[title] = FocusNode();
    }
    // Ambil FocusNode dari map yang sudah pasti terinisialisasi
    FocusNode focusNode = _focusNodes[title]!;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
          ),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _controllers[title],
              focusNode: focusNode,
              keyboardType: title == 'Nomor Telepon'
                  ? TextInputType.number
                  : TextInputType.text,
              style: FontTheme.titleMedium(
                context,
                color: isEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withAlpha(400),
              ),
              decoration: InputDecoration(
                enabled: isEnabled,
                hintText: subtitle,
                hintStyle: TextStyle(
                  color: isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withAlpha(400),
                ),
                prefixIcon: title == 'Nomor Telepon'
                    ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: focusNode.hasFocus ? 6.0 : 7.0),
                  // Jarak antara prefix dan input
                  child: Text(
                    _selectedCountryCode ?? '',
                    style: FontTheme.titleMedium(
                        context,
                        color: Theme.of(context).colorScheme.primary
                    ),
                  ),
                )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                // Tampilkan suffixIcon hanya saat TextField fokus
                suffixIcon: focusNode.hasFocus && _lastConnectionStatus
                    ? IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          String infoUpdate = capitalizeEachWord(
                              _controllers[title]!.text.trim());
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
                      )
                    : null, // Jika tidak fokus, suffixIcon null
              ),
            ),
          ),
        ],
      ),
    );
  }
}
