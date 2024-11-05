import 'package:absensitoko/data/models/version_model.dart';
import 'package:absensitoko/data/models/attendance_info_model.dart';
import 'package:absensitoko/data/models/user_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/data/providers/time_provider.dart';
import 'package:absensitoko/data/providers/user_provider.dart';
import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/locator.dart';
import 'package:absensitoko/ui/widgets/breaktime_field.dart';
import 'package:absensitoko/ui/widgets/short_attendance_info.dart';
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
  final TextEditingController _breaktimeController = TextEditingController();
  final TextEditingController _nationalHolidayController =
      TextEditingController();
  final FocusNode _breaktimeFocus = FocusNode();
  final FocusNode _nationalHolidayFocus = FocusNode();
  final GlobalKey<FormState> _breaktimeFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _nationalHolidayFormKey = GlobalKey<FormState>();

  UserModel? _user;
  String _userName = "";
  final String _holiday = 'Libur ';
  String _displayMessage = 'Data belum diperoleh';
  bool _isLoadingGetInfo = false;

  // String? _infoRole = '';
  // bool _lockAccess = false;

  Future<void> _fetchUserData({bool isRefresh = false}) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userDataIsLoaded && !isRefresh) {
      _updateUser(userProvider.currentUser);
      return;
    }

    await _loadAndVerifyUserSession(userProvider, isRefresh);
  }

  Future<void> _loadAndVerifyUserSession(
      UserProvider userProvider, bool isRefresh) async {
    await userProvider.loadUserSession();
    final userDataSession = userProvider.currentUserSession;
    final deviceName = userProvider.deviceID;
    print('Nama Perangkat: $deviceName');

    safeContext((context) => LoadingDialog.show(context));
    try {
      final result = await userProvider.getUser(userDataSession!.uid,
          isRefresh: isRefresh);
      await _handleFetchResult(result, userProvider, deviceName!);
    } catch (e) {
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _handleFetchResult(
      result, UserProvider userProvider, String deviceName) async {
    if (result.status != 'success') {
      ToastUtil.showToast(result.message ?? '', ToastStatus.error);
      LoadingDialog.hide(context);
      return;
    }

    final userData = userProvider.currentUser;
    if (userData!.loginDevice != deviceName) {
      await _showSessionExpiredDialog();
    }
    _updateUser(userData);
    ToastUtil.showToast('Berhasil memperoleh data profil', ToastStatus.success);

    if (mounted) LoadingDialog.hide(context);
  }

  Future<void> _updateUser(UserModel? userData) async {
    setState(() {
      _user = userData;
      _userName = _user?.displayName?.toUpperCase() ?? '';
    });
  }

  Future<void> _showSessionExpiredDialog() async {
    final shouldLogout = await DialogUtils.showExpiredDialog(context,
        title: 'Sesi Berakhir',
        content: 'Sesi login telah berakhir. Silakan login kembali.');
    if (shouldLogout ?? false) {
      _handleLogout(sessionExpired: true);
    }
  }

  void _showErrorSnackbar(String message) {
    SnackbarUtil.showSnackbar(context: context, message: message);
    LoadingDialog.hide(context);
  }

  void _handleLogout({bool sessionExpired = false}) async {
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
      final message = await userProvider.signOut(user, sessionExpired);
      await _handleLogoutResult(message);
    } catch (e) {
      _showErrorSnackbar(e.toString());
      safeContext((context) => LoadingDialog.hide(context));
    }
  }

  Future<void> _handleLogoutResult(result) async {
    if (result.status == 'success') {
      await Future.delayed(const Duration(seconds: 1));
      safeContext((context) => SnackbarUtil.showSnackbar(
          context: context, message: 'Anda telah logout'));
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
            'Data berhasil diperoleh:\nBreaktime > ${data?.breakTime ?? ''}\nNational Holiday > ${data?.nationalHoliday ?? ''}';
        _breaktimeController.text = data?.breakTime ?? '';
        _nationalHolidayController.text = data?.nationalHoliday ?? '';
        _isLoadingGetInfo = false;
      });
    } else {
      setState(() {
        _displayMessage = response.message!;
      });
    }
  }

  Future<void> updateInfo() async {
    AttendanceInfoModel updatedData = AttendanceInfoModel(
      breakTime: _breaktimeController.text,
      nationalHoliday: _nationalHolidayController.text,
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

    final permission = await locationService.cekIzinLokasi();
    if (!permission.isGranted) {
      ToastUtil.showToast(permission.statusMessage, ToastStatus.error);
    }
  }

  Future<void> _initAndGetAttendanceHistory({bool isRefresh = false}) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final currentTime = Provider.of<TimeProvider>(context, listen: false)
        .currentTime
        .postHistory();

    if (!isRefresh) {
      await dataProvider.initializeHistory(_userName, currentTime);
    }

    if (dataProvider.isSelectedDateHistoryAvailable && !isRefresh) {
      print('Data absensi sudah ada');
      ToastUtil.showToast('Data absensi sudah ada', ToastStatus.success);
      return;
    }

    String action = isRefresh ? 'Memperbarui' : 'Mendapatkan';
    print('$action data absensi');

    final result = await dataProvider.getThisDayHistory(_userName, currentTime,
        isRefresh: isRefresh);
    if (result.status == 'success') {
      ToastUtil.showToast('Berhasil $action data absensi', ToastStatus.success);
    } else {
      print('Gagal $action data absensi');
      ToastUtil.showToast(
          'Gagal $action data absensi' ?? '', ToastStatus.error);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _getAppVersion();
    _permissionCheck();
    _fetchUserData().then((_) async => await _initAndGetAttendanceHistory());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _breaktimeController.dispose();
    _nationalHolidayController.dispose();
    _breaktimeFocus.dispose();
    _nationalHolidayFocus.dispose();
    unFocusAllField();
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
          onTap: () => unFocusAllField(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Scaffold(
                  body: RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 3));
                      await _fetchUserData(isRefresh: true);
                      await _initAndGetAttendanceHistory(isRefresh: true);
                    },
                    child: SingleChildScrollView(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          onSelected: (value) async =>
                                              _popupMenuAction(context, value),
                                          itemBuilder: _popupMenuItem,
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
                                    // _shortAttendanceInfo(dateTime),
                                    ShortAttendanceInfo(
                                      currentTime: dateTime,
                                      userName: _userName,
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0),
                                                  child: Text(
                                                    _userName,
                                                    style: FontTheme.bodyMedium(
                                                      context,
                                                      fontSize: 36,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8.0),
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pushNamed(
                                                          context,
                                                          '/attendance_history',
                                                          arguments: _userName);
                                                    },
                                                    child: const Text(
                                                        'Cek Absensi'),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Container(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8.0),
                                                  child: FilledButton(
                                                    onPressed: () async {
                                                      bool isConnected =
                                                          await NetworkHelper
                                                              .hasInternetConnection();
                                                      if (isConnected) {
                                                        Navigator.pushNamed(
                                                            context,
                                                            '/attendance',
                                                            arguments:
                                                                _userName);
                                                      } else {
                                                        ToastUtil.showToast(
                                                            'Tidak ada koneksi internet',
                                                            ToastStatus.error);
                                                      }
                                                    },
                                                    child: const Text(
                                                        'Pergi Absen'),
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 8.0,
                                                  ),
                                                  child: Text(
                                                    'Atur waktu mulai istirahat:',
                                                    style: FontTheme.bodyMedium(
                                                      context,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                                BreaktimeField(
                                                  focusNode: _breaktimeFocus,
                                                  controller:
                                                      _breaktimeController,
                                                  formKey: _breaktimeFormKey,
                                                  labelText: 'breaktime',
                                                  hintText:
                                                      !_breaktimeFocus.hasFocus
                                                          ? 'Waktu Istirahat'
                                                          : null,
                                                  errorMessage:
                                                      'Waktu istirahat tidak boleh kosong',
                                                  readonly: true,
                                                  onCancel: unFocusAllField,
                                                  onConfirm: () => updateInfo(),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 8.0,
                                                  ),
                                                  child: Text(
                                                    'Atur Libur Nasional:',
                                                    style: FontTheme.bodyMedium(
                                                      context,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                                BreaktimeField(
                                                  focusNode:
                                                      _nationalHolidayFocus,
                                                  controller:
                                                      _nationalHolidayController,
                                                  formKey:
                                                      _nationalHolidayFormKey,
                                                  errorMessage:
                                                      'Hari libur tidak boleh kosong',
                                                  prefixText:
                                                      _nationalHolidayFocus
                                                              .hasFocus
                                                          ? _holiday
                                                          : null,
                                                  hintText:
                                                      !_nationalHolidayFocus
                                                              .hasFocus
                                                          ? 'Hari Libur '
                                                          : null,
                                                  onConfirm: () => updateInfo(),
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
                                                    if (_displayMessage
                                                        .isNotEmpty)
                                                      ListTile(
                                                        title: _isLoadingGetInfo
                                                            ? const Center(
                                                                child:
                                                                    CircularProgressIndicator())
                                                            : Text(
                                                                _displayMessage,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                      ),
                                                    // Get Info Button
                                                    Center(
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          setState(() =>
                                                              _isLoadingGetInfo =
                                                                  true);
                                                          getInfo();
                                                        },
                                                        child: const Text(
                                                          'Peroleh Data',
                                                        ),
                                                      ),
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
                                                    SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton(
                                                            onPressed: () =>
                                                                ToastUtil.showToast(
                                                                    'Masih dalam pengembangan',
                                                                    ToastStatus
                                                                        .warning),
                                                            child: const Text(
                                                                'Buat Sheet Baru'))),
                                                    // Get App Version Button
                                                    /*ElevatedButton(
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
                                                    ),*/
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
                                        if (_breaktimeController
                                                .text.isNotEmpty ||
                                            _nationalHolidayController
                                                .text.isNotEmpty)
                                          Positioned(
                                            right: 16,
                                            top: 16,
                                            child: IconButton(
                                              onPressed: () {
                                                _breaktimeController.clear();
                                                _nationalHolidayController
                                                    .clear();
                                                setState(
                                                    () => _displayMessage = '');
                                                unFocusAllField();
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
                                                    _userName,
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
        ),
      ],
    );
  }

  Future<void> _popupMenuAction(BuildContext context, String value) async {
    if (value == 'logout') {
      bool isConnected = await NetworkHelper.hasInternetConnection();
      if (isConnected && context.mounted) {
        DialogUtils.showConfirmationDialog(
          context: context,
          title: 'Logout',
          content: const Text('Keluar dari aplikasi?'),
          onConfirm: () {
            _handleLogout();
          },
        );
      } else {
        ToastUtil.showToast('Tidak ada koneksi internet', ToastStatus.error);
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Provider.of<UserProvider>(context, listen: false)
            .getUser(_user!.uid);
      });
    } else if (value == 'information') {
      Navigator.pushNamed(context, '/information');
    }
  }

  List<PopupMenuItem> _popupMenuItem(BuildContext context) {
    final imageUrl = _user?.photoURL ?? '';
    return homeMenuItem.entries.where((item) {
      // Tampilkan hanya item yang sesuai dengan peran pengguna
      if (item.key == 'Account' && _user?.role != 'admin') {
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
                  placeholder: (context, url) => Icon(item.value),
                  errorWidget: (context, url, error) => Icon(item.value),
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
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
  }

  void unFocusAllField() {
    _breaktimeFocus.unfocus();
    _nationalHolidayFocus.unfocus();
  }

// Widget Fungsi ShortAttendanceInfo setelah disederhanakan, dan disempurnakan menggunakan kelas widget khusus
/*Widget _shortAttendanceInfo(CustomTime currentTime) {
  return Container(
    height: 60,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Theme.of(context).colorScheme.tertiaryContainer,
    ),
    child: Consumer<DataProvider>(builder: (context, dataProvider, child) {
      final historyData = dataProvider.selectedDateHistory;

      if (!dataProvider.isSelectedDateHistoryAvailable && dataProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final bool historyAvailable = historyData != null;
      final String morningHistoryStatus = historyAvailable
          ? (historyData.tLPagi?.isNotEmpty ?? false) ? 'Anda sudah absen pagi' : 'Anda belum absen pagi'
          : '(Cek koneksi internet)';

      final String afternoonHistoryStatus = historyAvailable
          ? (historyData.tLSiang?.isNotEmpty ?? false) ? 'Anda sudah absen siang' : 'Anda belum absen siang'
          : '(Cek koneksi internet)';

      // Cek apakah saat ini berada dalam rentang waktu pagi atau siang
      final bool isMorningTime = isCurrentTimeWithinRange(
        currentTime.getDefaultDateTime(),
        '$morningStartHour:$morningStartMinute',
        '12:00',
      );

      final bool isAfternoonTime = isCurrentTimeWithinRange(
        currentTime.getDefaultDateTime(),
        '12:00',
        '$storeClosedHour:$storeClosedMinute',
      );

      // Tentukan status yang akan ditampilkan berdasarkan rentang waktu
      final String? historyStatus = isMorningTime
          ? morningHistoryStatus
          : isAfternoonTime
          ? afternoonHistoryStatus
          : null;

      // Sembunyikan widget jika di luar rentang waktu yang ditentukan
      if (historyStatus == null) return const SizedBox.shrink();

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.greenAccent,
          onTap: () async {
            bool isConnected = await NetworkHelper.hasInternetConnection();
            if (isConnected) {
              Navigator.pushNamed(context, '/attendance',
                  arguments: userName);
            } else {
              ToastUtil.showToast(
                  'Tidak ada koneksi internet', ToastStatus.error);
            }
            // Provider.of<TimeProvider>(context, listen: false).stopUpdatingTime();
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_alert_sharp,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                Text(
                  historyStatus,
                  style: FontTheme.bodyLarge(context,
                      color: Theme.of(context).indicatorColor, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}*/

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
