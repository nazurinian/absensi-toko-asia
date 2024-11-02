import 'package:absensitoko/models/AppVersionModel.dart';
import 'package:absensitoko/models/AttendanceInfoModel.dart';
import 'package:absensitoko/models/UserModel.dart';
import 'package:absensitoko/provider/DataProvider.dart';
import 'package:absensitoko/provider/TimeProvider.dart';
import 'package:absensitoko/provider/UserProvider.dart';
import 'package:absensitoko/themes/fonts/Fonts.dart';
import 'package:absensitoko/utils/BaseState.dart';
import 'package:absensitoko/utils/DeviceUtils.dart';
import 'package:absensitoko/utils/DialogUtils.dart';
import 'package:absensitoko/utils/DisplaySize.dart';
import 'package:absensitoko/utils/Helper.dart';
import 'package:absensitoko/utils/ListMenu.dart';
import 'package:absensitoko/utils/LoadingDialog.dart';
import 'package:absensitoko/utils/NetworkHelper.dart';
import 'package:absensitoko/utils/TimePicker.dart';
import 'package:absensitoko/views/ProfilePage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BaseState<HomePage> {
  final TextEditingController breaktimeController = TextEditingController();
  final TextEditingController nationalHolidayController =
      TextEditingController();
  final FocusNode breaktimeFocus = FocusNode();
  final FocusNode nationalHolidayFocus = FocusNode();

  UserModel? _user;
  final String _holiday = 'Libur ';
  String _displayMessage = 'Data belum diperoleh';
  AppVersionModel? thisAppVersion;
  AppVersionModel? newAppVersion;

  // String? _infoRole = '';
  // bool _lockAccess = false;

  Future<void> _fetchUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userDataIsLoaded) {
      _updateUser(userProvider.currentUser);
      return;
    }

    await _loadAndVerifyUserSession(userProvider);
  }

  Future<void> _loadAndVerifyUserSession(UserProvider userProvider) async {
    await userProvider.loadUserSession();
    final userDataSession = userProvider.currentUserSession;
    final deviceName = userProvider.deviceID;
    print('Nama Perangkat: $deviceName');

    try {
      final result = await userProvider.getUser(userDataSession!.uid);
      await _handleFetchResult(result, userProvider, deviceName!);
    } catch (e) {
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _handleFetchResult(
      result, UserProvider userProvider, String deviceName) async {
    if (result.status == 'success') {
      final userData = userProvider.currentUser;
      if (userData!.loginDevice != deviceName) {
        await _showSessionExpiredDialog();
      } else {
        _updateUser(userData);
        ToastUtil.showToast('Berhasil memperoleh data', ToastStatus.success);
      }
    } else {
      ToastUtil.showToast(result.message ?? '', ToastStatus.error);
    }
  }

  void _updateUser(UserModel? userData) {
    setState(() {
      _user = userData;
    });
  }

  Future<void> _showSessionExpiredDialog() async {
    final shouldLogout = await DialogUtils.showExpiredDialog(context, title: 'Sesi Berakhir', content: 'Sesi login telah berakhir. Silakan login kembali.');
    if (shouldLogout ?? false) {
      _handleLogout();
    }
  }

  void _showErrorSnackbar(String message) {
    safeContext((context) {
      SnackbarUtil.showSnackbar(context: context, message: message);
    });
  }

  void _handleLogout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userDataSession = userProvider.currentUserSession!.uid;
    final currentTime = Provider.of<TimeProvider>(context, listen: false)
        .currentTime
        .postTime();

    UserModel user = UserModel(
      uid: userDataSession,
      logoutTimestamp: currentTime,
    );

    LoadingDialog.show(context);
    try {
      final message = await userProvider.signOut(user);
      await _handleLogoutResult(message);
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      LoadingDialog.hide(context);
    }
  }

  Future<void> _handleLogoutResult(result) async {
    if (result.status == 'success') {
      await Future.delayed(const Duration(seconds: 1));
      SnackbarUtil.showSnackbar(context: context, message: 'Anda telah logout');
      _clearDataAndNavigate();
    } else {
      SnackbarUtil.showSnackbar(
          context: context, message: result.message ?? 'Error');
    }
  }

  void _clearDataAndNavigate() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.clearAccountData();
    Provider.of<DataProvider>(context, listen: false).clearData();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> getInfo() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final response = await dataProvider.getAttendanceInfo();

    if (response.status == 'success') {
      final data = dataProvider.attendanceInfoData;
      setState(() {
        _displayMessage =
            'Data berhasil diperoleh: Breaktime - ${data?.breakTime ?? ''}, National Holiday - ${data?.nationalHoliday ?? ''}';
        breaktimeController.text = data?.breakTime ?? '';
        nationalHolidayController.text = data?.nationalHoliday ?? '';
      });
    } else {
      setState(() {
        _displayMessage = response.message!;
      });
    }
  }

  Future<void> updateInfo() async {
    // Buat objek data dari input TextField
    AttendanceInfoModel updatedData = AttendanceInfoModel(
      breakTime: breaktimeController.text,
      nationalHoliday: nationalHolidayController.text,
    );

    final response = await Provider.of<DataProvider>(context, listen: false)
        .updateAttendanceInfo(updatedData);

    setState(() {
      _displayMessage = response.message!;
    });
  }

  Future<void> _getAppVersion() async {
    AppVersionModel thisAppVer = await DeviceUtils.getAppInfo();

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.getAppVersion();

    final newAppVer = dataProvider.appVersion;
    if (newAppVer != null) {
      print('Versi saat ini : ${thisAppVer.toString()}');
      print('Versi terbaru : ${newAppVer.toString()}');

      setState(() {
        thisAppVersion = thisAppVer;
        newAppVersion = newAppVer;
      });
      if((thisAppVersion!.version != newAppVer.version || thisAppVersion!.buildNumber != newAppVer.buildNumber) && newAppVer.mandatory!) {
        String title = 'Pembaruan Diperlukan';
        String content = 'Aplikasi Anda saat ini versi: ${thisAppVersion!.version} sudah tidak dapat digunakan, silahkan update ke versi terbaru: ${newAppVer.version} dengan mengklik tombol Perbarui';

        if(mounted){
          bool result = await DialogUtils.showExpiredDialog(context, title: title, content: content, buttonText: 'Perbarui') ?? false;
          if (result) {
            final updateLink = Uri.parse("https://flutter.dev");
            // final updateLink = Uri.parse(newAppVer.link!);
            if (!await launchUrl(updateLink)) {
              ToastUtil.showToast('Gagal membuka browser', ToastStatus.error);
              // throw Exception('Could not launch $updateLink');
            }
          }
        }
      }
    }
  }

/*  Future<void> _updateAppVersion() async {
    // AppVersionModel appInfo = await DeviceUtils.getAppInfo();
    AppVersionModel appInfo = AppVersionModel(version: '3.0.0', buildNumber: 1, mandatory: false, link: 'https://play.google.com/store/apps/details?id=com.absensitoko.absensitoko');
    Provider.of<DataProvider>(context, listen: false).updateAppVersion(appInfo);

    print(appInfo);
    setState(() {
      appVersion = appInfo.version ?? '2.0.0';
    });
  }*/

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _fetchUserData();
  }

  @override
  void dispose() {
    super.dispose();
    breaktimeController.dispose();
    nationalHolidayController.dispose();
    breaktimeFocus.dispose();
    nationalHolidayFocus.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final textTheme = Theme.of(context).textTheme;
    final dateTime = Provider.of<TimeProvider>(context).currentTime;

    return Stack(
      children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.brown,
        ),
        GestureDetector(
          onTap: () {
            breaktimeFocus.unfocus();
            nationalHolidayFocus.unfocus();
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          child: Image.asset(
                            'assets/images/atk_bottom.png',
                            width: screenWidth(context),
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${dateTime.getIdnDayName()}, ',
                                      style: FontTheme.titleMedium(
                                        context,
                                        fontSize: 36,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    SizedBox(
                                      child: PopupMenuButton(
                                        offset: const Offset(0, 50),
                                        onSelected: (value) async {
                                          if (value == 'logout') {
                                            bool isConnected =
                                                await NetworkHelper
                                                    .hasInternetConnection();
                                            if (isConnected) {
                                              DialogUtils
                                                  .showConfirmationDialog(
                                                context: context,
                                                title: 'Logout',
                                                content: const Text(
                                                    'Keluar dari aplikasi?'),
                                                onConfirm: () {
                                                  _handleLogout();
                                                },
                                              );
                                            } else {
                                              ToastUtil.showToast(
                                                  'Tidak ada koneksi internet',
                                                  ToastStatus.error);
                                            }
                                          } else if (value == 'profile') {
                                            bool updateProfile =
                                                await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ProfilePage()),
                                            );
                                            if (updateProfile) {
                                              _fetchUserData();
                                            }
                                            // Memastikan data diperbarui setelah kembali dari halaman edit
                                            WidgetsBinding.instance
                                                .addPostFrameCallback(
                                                    (_) async {
                                              await Provider.of<UserProvider>(
                                                      context,
                                                      listen: false)
                                                  .getUser(_user!.uid);
                                            });
                                          }
                                        },
                                        itemBuilder: (context) {
                                          final imageUrl =
                                              _user?.photoURL ?? '';

                                          return homeMenuItem.entries
                                              .where((item) {
                                            // Tampilkan hanya item yang sesuai dengan peran pengguna
                                            if (item.key == 'Account' &&
                                                _user?.role != 'admin') {
                                              return false; // Jangan tampilkan item 'Account' jika bukan admin
                                            }
                                            return true; // Tampilkan item lainnya
                                          }).map((item) {
                                            return PopupMenuItem<String>(
                                              value: item.key.toLowerCase(),
                                              child: Row(
                                                children: [
                                                  if (item.key == 'Profile')
                                                    CircleAvatar(
                                                      radius: 12,
                                                      child: CachedNetworkImage(
                                                        imageUrl: imageUrl,
                                                        placeholder: (context,
                                                                url) =>
                                                            Icon(item.value),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Icon(item.value),
                                                        imageBuilder: (context,
                                                                imageProvider) =>
                                                            Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            image:
                                                                DecorationImage(
                                                              image:
                                                                  imageProvider,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    Icon(item.value),
                                                  const SizedBox(width: 10),
                                                  Text(item.key),
                                                ],
                                              ),
                                            );
                                          }).toList();
                                        },
                                        iconSize: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  dateTime.getIdnDate(),
                                  style: FontTheme.titleMedium(
                                    context,
                                    fontSize: 19,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        splashColor: Colors.greenAccent,
                                        onTap: () async {
                                          bool isConnected = await NetworkHelper
                                              .hasInternetConnection();
                                          if (isConnected) {
                                            Navigator.pushNamed(
                                                context, '/absensi',
                                                arguments: _user != null
                                                    ? _user?.displayName
                                                        ?.toUpperCase()
                                                    : 'ANONYMOUS');
                                          } else {
                                            ToastUtil.showToast(
                                                'Tidak ada koneksi internet',
                                                ToastStatus.error);
                                          }
                                          // Provider.of<TimeProvider>(context, listen: false).stopUpdatingTime();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          height: 60,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_alert_sharp,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Anda belum absen hari ini',
                                                style: FontTheme.bodyLarge(
                                                    context,
                                                    color: Theme.of(context)
                                                        .indicatorColor,
                                                    fontSize: 20),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      dateTime.getIdnTime(),
                                      style: FontTheme.titleMedium(
                                        context,
                                        fontSize: 36,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          bottom: 0,
                                          child: Image.asset(
                                            'assets/images/jam.png',
                                            width: 175,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Selamat Datang 👋',
                                                style: FontTheme.bodyMedium(
                                                  context,
                                                  fontSize: 28,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Text(
                                                  _user != null
                                                      ? _user!.displayName!
                                                      : '',
                                                  style: FontTheme.bodyMedium(
                                                    context,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Container(
                                                alignment:
                                                    Alignment.centerRight,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    ToastUtil.showToast(
                                                        'Fitur belum tersedia',
                                                        ToastStatus.warning);
                                                  },
                                                  child:
                                                      const Text('Cek Absensi'),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Container(
                                                alignment:
                                                    Alignment.centerRight,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: FilledButton(
                                                  onPressed: () async {
                                                    bool isConnected =
                                                        await NetworkHelper
                                                            .hasInternetConnection();
                                                    if (isConnected) {
                                                      Navigator.pushNamed(
                                                          context, '/absensi',
                                                          arguments: _user !=
                                                                  null
                                                              ? _user
                                                                  ?.displayName
                                                                  ?.toUpperCase()
                                                              : 'ANONYMOUS');
                                                    } else {
                                                      ToastUtil.showToast(
                                                          'Tidak ada koneksi internet',
                                                          ToastStatus.error);
                                                    }
                                                  },
                                                  child:
                                                      const Text('Pergi Absen'),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),

                                  /// Dashboard Next Update
                                  /*Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Image.asset(
                                            'assets/images/daun_flipped.png',
                                            width: 175,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'DashBoard 📊',
                                                style: FontTheme.bodyMedium(
                                                  context,
                                                  fontSize: 28,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Text(
                                                  'Chart',
                                                  style: FontTheme.bodyMedium(
                                                    context,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  ToastUtil.showToast(
                                                      'Fitur belum tersedia',
                                                      ToastStatus.warning);
                                                },
                                                child: const Text('null'),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              FilledButton(
                                                onPressed: () {
                                                  ToastUtil.showToast(
                                                      'Fitur belum tersedia',
                                                      ToastStatus.warning);
                                                },
                                                child: const Text('null'),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),*/
                                  Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Informasi Absen ⏲️',
                                                style: FontTheme.bodyMedium(
                                                  context,
                                                  fontSize: 28,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                child: Text(
                                                  'Atur waktu istirahat:',
                                                  style: FontTheme.bodyMedium(
                                                    context,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      focusNode: breaktimeFocus,
                                                      controller:
                                                          breaktimeController,
                                                      keyboardType:
                                                          TextInputType.none,
                                                      readOnly: true,
                                                      onTap: () {
                                                        TimePicker.customTime(
                                                            context,
                                                            'Waktu Istirahat',
                                                            onSelecttime:
                                                                (time) {
                                                          DateTime date =
                                                              DateFormat.jm().parse(
                                                                  time.format(
                                                                      context));
                                                          breaktimeController
                                                                  .text =
                                                              DateFormat(
                                                                      'HH:mm')
                                                                  .format(date);
                                                        });
                                                        ToastUtil.showToast(
                                                            'Fitur belum tersedia',
                                                            ToastStatus
                                                                .warning);
                                                      },
                                                      style:
                                                          FontTheme.titleMedium(
                                                              context),
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: !breaktimeFocus
                                                                .hasFocus
                                                            ? 'Waktu Istirahat'
                                                            : null,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      updateInfo();
                                                    },
                                                    child: const Text('Simpan'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                child: Text(
                                                  'Atur Tangal Libur Nasional:',
                                                  style: FontTheme.bodyMedium(
                                                    context,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      focusNode:
                                                          nationalHolidayFocus,
                                                      controller:
                                                          nationalHolidayController,
                                                      style:
                                                          FontTheme.titleMedium(
                                                              context),
                                                      decoration:
                                                          InputDecoration(
                                                        prefixText:
                                                            nationalHolidayFocus
                                                                    .hasFocus
                                                                ? _holiday
                                                                : null,
                                                        hintText:
                                                            !nationalHolidayFocus
                                                                    .hasFocus
                                                                ? 'Hari Libur '
                                                                : null,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      updateInfo();
                                                    },
                                                    child: const Text('Simpan'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              const Divider(
                                                thickness: 5,
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Column(
                                                children: [
                                                  ListTile(
                                                    title: Text(
                                                      _displayMessage,
                                                    ),
                                                  ),
                                                  // Get Info Button
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      getInfo();
                                                    },
                                                    child: const Text(
                                                        'Peroleh Data'),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  // Get App Version
                                                  ListTile(
                                                    title: const Text(
                                                        'Versi Aplikasi'),
                                                    trailing: Text(
                                                      thisAppVersion?.version ?? '',
                                                      style:
                                                          FontTheme.bodyMedium(
                                                              context,
                                                              fontSize: 14),
                                                    ),
                                                  ),
                                                  // Get App Version Button
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _getAppVersion();
                                                    },
                                                    child: const Text(
                                                        'Cek Versi Aplikasi'),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  // Update App Version Button
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      // updateAppVersion();
                                                    },
                                                    child: const Text(
                                                        'Perbarui Versi Aplikasi'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      //Clear Button
                                      if (breaktimeController.text.isNotEmpty ||
                                          nationalHolidayController
                                              .text.isNotEmpty)
                                        Positioned(
                                          right: 16,
                                          top: 16,
                                          child: IconButton(
                                            onPressed: () {
                                              breaktimeFocus.unfocus();
                                              nationalHolidayFocus.unfocus();
                                              breaktimeController.clear();
                                              nationalHolidayController.clear();
                                            },
                                            icon: const Icon(Icons.clear),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Data Akun 🪪',
                                            style: FontTheme.bodyMedium(
                                              context,
                                              fontSize: 28,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(
                                              'Akun: ',
                                              style: FontTheme.bodyMedium(
                                                context,
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Column(
                                            children: [
                                              ListTile(
                                                title: const Text('Nama'),
                                                trailing: Text(
                                                  _user != null
                                                      ? _user!.displayName!
                                                      : '',
                                                  style: FontTheme.bodyMedium(
                                                      context,
                                                      fontSize: 14),
                                                ),
                                              ),
                                              ListTile(
                                                title: const Text('Email'),
                                                trailing: Text(
                                                  _user != null
                                                      ? _user!.email!
                                                      : '',
                                                  style: FontTheme.bodyMedium(
                                                      context,
                                                      fontSize: 14),
                                                ),
                                              ),
                                              ListTile(
                                                title: const Text('Bagian'),
                                                trailing: Text(
                                                  _user != null
                                                      ? _user!.department!
                                                          .toUpperCase()
                                                      : '',
                                                  style: FontTheme.bodyMedium(
                                                      context,
                                                      fontSize: 14),
                                                ),
                                              ),
                                              ListTile(
                                                title: const Text(
                                                    'Login Terakhir'),
                                                trailing: Text(
                                                  _user != null
                                                      ? _user!.loginTimestamp!
                                                              .isNotEmpty
                                                          ? _user!
                                                              .loginTimestamp!
                                                          : _user!
                                                              .firstTimeLogin!
                                                      : '',
                                                  style: FontTheme.bodyMedium(
                                                      context,
                                                      fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

// Fungsi fetchUserData dan Logout sebelum disederhanakan
/*
  Future<void> _fetchUserdata() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    UserModel? userData = userProvider.currentUser;

    if (!userProvider.userDataIsLoaded) {
      await userProvider.loadUserSession();
      final userDataSession = userProvider.currentUserSession;
      final _deviceName = userProvider.deviceID;
      print('Nama Perangkat: $_deviceName');

      try {
        final result = await userProvider.getUser(userDataSession!.uid);

        if (result.status == 'success') {
          userData = userProvider.currentUser;
          if (userData!.loginDevice != _deviceName) {
            DialogUtils.showSessionExpiredDialog(context).then((value) {
              if (value!) {
                _handleLogout();
              }
            });
          } else {
            setState(() {
              _user = userData;
            });
            ToastUtil.showToast(
                'Berhasil memperoleh data', ToastStatus.success);
          }
        } else {
          ToastUtil.showToast(result.message ?? '', ToastStatus.error);
        }
      } catch (e) {
        safeContext((context) {
          SnackbarUtil.showSnackbar(context: context, message: e.toString());
        });
      }
    } else {
      setState(() {
        _user = userData;
      });
    }
    // _lockAccess = !roleList.contains(_user?.role?.toLowerCase());
  }

  void _handleLogout() async {
    final userDataSession = Provider.of<UserProvider>(context, listen: false)
        .currentUserSession!
        .uid;
    final currentTime = Provider.of<TimeProvider>(context, listen: false)
        .currentTime
        .postTime();
    UserModel user = UserModel(
      uid: userDataSession,
      logoutTimestamp: currentTime,
      loginTimestamp: '',
      loginLat: '',
      loginLong: '',
      loginDevice: '',
    );

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    LoadingDialog.show(context);
    try {
      final message = await userProvider.signOut(user);

      if (message.status == 'success') {
        Future.delayed(const Duration(seconds: 1), () {
          LoadingDialog.hide(context);
          SnackbarUtil.showSnackbar(
              context: context, message: 'Anda telah logout');
          userProvider.clearAccountData();
          Provider.of<DataProvider>(context, listen: false).clearData();
          print('Data Cleared');
        }).then((_) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        });
        // });
      } else {
        safeContext((context) {
          LoadingDialog.hide(context);
          SnackbarUtil.showSnackbar(
              context: context, message: message.message ?? 'Error');
        });
      }
    } catch (e) {
      safeContext((context) {
        LoadingDialog.hide(context);
        SnackbarUtil.showSnackbar(context: context, message: e.toString());
      });
    }
  }
 */
}
