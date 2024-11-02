import 'package:absensitoko/data/models/version_model.dart';
import 'package:absensitoko/data/models/attendance_info_model.dart';
import 'package:absensitoko/data/models/user_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/data/providers/time_provider.dart';
import 'package:absensitoko/data/providers/user_provider.dart';
import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/locator.dart';
import 'package:absensitoko/utils/base/base_state.dart';
import 'package:absensitoko/utils/base/location_service.dart';
import 'package:absensitoko/utils/base/version_checker.dart';
import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:absensitoko/utils/display_size_util.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:absensitoko/core/constants/options_menu.dart';
import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:absensitoko/utils/helpers/network_helper.dart';
import 'package:absensitoko/utils/time_picker_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BaseState<HomePage> with WidgetsBindingObserver {
  final TextEditingController breaktimeController = TextEditingController();
  final TextEditingController nationalHolidayController =
      TextEditingController();
  final FocusNode breaktimeFocus = FocusNode();
  final FocusNode nationalHolidayFocus = FocusNode();

  UserModel? _user;
  final String _holiday = 'Libur ';
  String _displayMessage = 'Data belum diperoleh';
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
    final shouldLogout = await DialogUtils.showExpiredDialog(context,
        title: 'Sesi Berakhir',
        content: 'Sesi login telah berakhir. Silakan login kembali.');
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
      loginTimestamp: '',
      loginLat: '',
      loginLong: '',
      loginDevice: '',
    );

    LoadingDialog.show(context);
    try {
      final message = await userProvider.signOut(user);
      await _handleLogoutResult(message);
    } catch (e) {
      _showErrorSnackbar(e.toString());
      safeContext((context) => LoadingDialog.hide(context));
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
    LoadingDialog.hide(context);
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
    await VersionChecker.checkForUpdates();
  }

/*  Future<void> _updateAppVersion() async {
    AppVersionModel appVersion = AppVersionModel(version: '3.0.0', buildNumber: 1, mandatory: false, link: 'https://play.google.com/store/apps/details?id=com.absensitoko.absensitoko');
    VersionChecker.setAppVersion(appVersion);
  }*/

  Future<void> _permissionCheck() async {
    final locationService = locator<LocationService>();

    await locationService.cekIzinLokasi();
    await locationService.cekLokasiSekali();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _getAppVersion();
    _fetchUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    breaktimeController.dispose();
    nationalHolidayController.dispose();
    breaktimeFocus.dispose();
    nationalHolidayFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getAppVersion();
    }
    super.didChangeAppLifecycleState(state);
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
                                            bool updateProfile = await Navigator.pushNamed(
                                              context,
                                              '/profile',
                                            ) as bool;
                                            if (updateProfile) {
                                              _fetchUserData();
                                              print('Memperbarui data user');
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
                                          } else if (value == 'information') {
                                            Navigator.pushNamed(context, '/information');
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
                                                  'Atur waktu mulai istirahat:',
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
                                                            onSelectedTime:
                                                                (time) {
                                                          if (time.isNotEmpty) {
                                                            breaktimeController
                                                                .text = time;
                                                          } else {
                                                            breaktimeFocus
                                                                .unfocus();
                                                          }
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
                                                  'Atur Libur Nasional:',
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
                                                  // Get App Version Button
                                                  // ElevatedButton(
                                                  //   onPressed: () {
                                                  //     _getAppVersion();
                                                  //   },
                                                  //   child: const Text(
                                                  //       'Cek Versi Aplikasi'),
                                                  // ),
                                                  // const SizedBox(
                                                  //   height: 10,
                                                  // ),
                                                  // // Update App Version Button
                                                  // ElevatedButton(
                                                  //   onPressed: () {
                                                  //     // updateAppVersion();
                                                  //   },
                                                  //   child: const Text(
                                                  //       'Perbarui Versi Aplikasi'),
                                                  // ),
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
