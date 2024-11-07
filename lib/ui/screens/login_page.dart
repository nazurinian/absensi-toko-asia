import 'package:absensitoko/api/api_result.dart';
import 'package:absensitoko/locator.dart';
import 'package:absensitoko/utils/base/location_service.dart';
import 'package:absensitoko/utils/base/version_checker.dart';
import 'package:absensitoko/utils/device_util.dart';
import 'package:absensitoko/core/constants/items_list.dart';
import 'package:absensitoko/utils/helpers/network_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:absensitoko/data/models/session_model.dart';
import 'package:absensitoko/data/providers/time_provider.dart';
import 'package:absensitoko/utils/base/base_state.dart';
import 'package:absensitoko/ui/widgets/custom_text_form_field.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:absensitoko/data/providers/user_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends BaseState<LoginPage> with WidgetsBindingObserver {
  final locationService = locator<LocationService>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _firstSubmit = true;
  bool isCancelled = false;

  // String _attendanceLocationStatus = 'Get Location Permission';
  LatLng? _attendanceLocation;
  String _deviceName = '';

  // Minta izin akses lokasi
  Future<void> _cekIzinLokasi() async {
    PermissionStatusResult permissionResult = await locationService.cekIzinLokasi();
    if(!permissionResult.isGranted) {
      ToastUtil.showToast(permissionResult.statusMessage, ToastStatus.error);
    }
  }

  // Cek apakah pengguna berada dalam radius absensi
  Future<void> _cekLokasiSekali() async {
    LocationCheckResult locationCheckResult = await locationService.cekLokasiSekali();
    // _attendanceLocationStatus = locationCheckResult.statusMessage;
    if(locationCheckResult.isMocked && mounted) {
      SnackbarUtil.showSnackbar(context: context, message: 'Gagal login, gps bermasalah!');
      return;
    }

    _attendanceLocation = LatLng(locationCheckResult.position?.latitude ?? 0.0, locationCheckResult.position?.longitude ?? 0.0);
  }

  Future<void> _login() async {
    bool isCancelled = false;
    _cekIzinLokasi();

    // Set state untuk first submit dan validasi form
    _firstSubmit = false;
    if (!_validateForm()) return;

    _unFocus();
    LoadingDialog.show(context, onPopInvoked: () {
      isCancelled = true;
    });

    // Cek lokasi dan ambil nama perangkat
    try {
      await _cekLokasiSekali();
      await _fetchDeviceName();
    } catch (e) {
      _showError(e.toString());
    }

    // Lakukan proses login
    try {
      if(isCancelled) {
        final FirebaseAuth auth = FirebaseAuth.instance;
        if(auth.currentUser != null) {
          await auth.signOut();
        }
        throw 'Login dibatalkan';
      }
      final message = await _loginProcess();

      _handleLoginResult(message);
    } catch (e) {
      _showError(e.toString());
    }
  }

  bool _validateForm() {
    setState(() {});
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _fetchDeviceName() async {
    if (mounted) {
      final deviceName = await DeviceUtils.getDeviceName(context);
      setState(() => _deviceName = deviceName);
    }
  }

  Future<ApiResult> _loginProcess() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentTime = Provider.of<TimeProvider>(context, listen: false)
        .currentTime
        .postTime();

    return await userProvider.loginUser(
      context,
      _emailController.text,
      _passwordController.text,
      currentTime,
      _deviceName,
      _attendanceLocation!,
    );
  }

  void _handleLoginResult(ApiResult result) {
    LoadingDialog.hide(context);
    SnackbarUtil.showSnackbar(context: context, message: result.message ?? '');

    if (result.status == 'success') {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.currentUser!;
      final userSession = SessionModel(
        uid: userData.uid,
        email: userData.email,
        role: userData.role,
        loginTimestamp: userData.loginTimestamp,
        loginDevice: _deviceName,
        isLogin: true,
      );

      userProvider.saveSession(userSession, _deviceName);
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  void _showError(String errorMessage) {
    LoadingDialog.hide(context);
    SnackbarUtil.showSnackbar(context: context, message: errorMessage);
  }

  void _unFocus() {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
  }

  Future<void> _getAppVersion() async {
    await VersionChecker.checkForUpdates();
  }

/*  Future<void> _updateAppVersion() async {
    AppVersionModel appVersion = AppVersionModel(version: '3.0.0', buildNumber: 1, mandatory: false, link: 'https://play.google.com/store/apps/details?id=com.absensitoko.absensitoko');
    VersionChecker.setAppVersion(appVersion);
  }*/

  void _controllerListener() {
    _emailController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        safeSetState(() {
          if (!_firstSubmit) {
            _formKey.currentState?.validate();
          }
        });
      });
    });
    _passwordController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        safeSetState(() {
          if (!_firstSubmit) {
            _formKey.currentState?.validate();
          }
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cekIzinLokasi();
    _controllerListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _emailController.removeListener(() {});
    _passwordController.removeListener(() {});
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          _unFocus();
          _formKey.currentState?.reset();
        },
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 50.0, bottom: 20),
                  child: Center(
                    child: SizedBox(
                        height: 120,
                        child: Image.asset(AppImage.attendanceApp.path, fit: BoxFit.fill)
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _firstSubmit
                          ? AutovalidateMode.disabled
                          : AutovalidateMode.always,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: CustomTextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              hintText: 'Email',
                              labelText: 'Email',
                              prefixIcon: Icons.email,
                              autoValidate: _firstSubmit ? true : false,
                              onChanged: (value) {
                                setState(() {
                                  if (!_firstSubmit) {
                                    _formKey.currentState?.validate();
                                  }
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: CustomTextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              hintText: 'Password',
                              labelText: 'Password',
                              prefixIcon: Icons.key,
                              autoValidate: _firstSubmit ? true : false,
                              onChanged: (value) {
                                setState(() {
                                  if (!_firstSubmit) {
                                    _formKey.currentState?.validate();
                                  }
                                });
                              },
                              iconColor: Colors.green,
                              isPassword: true,
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                            child: TextButton(
                              style: ButtonStyle(
                                overlayColor:
                                WidgetStateProperty.all(Colors.transparent),
                                splashFactory: NoSplash
                                    .splashFactory, // Menghilangkan efek splash
                              ),
                              onPressed: () => SnackbarUtil.showSnackbar(
                                context: context,
                                message: 'Hubungi admin ya...',
                              ),
                              child: const Text('Forget Password!'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.blue,
                              ),
                              width: MediaQuery.of(context).size.width,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  bool isConnected = await NetworkHelper
                                      .hasInternetConnection();
                                  if (isConnected) {
                                    _login();
                                  } else {
                                    if(context.mounted) {
                                      SnackbarUtil.showSnackbar(
                                        context: context,
                                        message: 'Tidak ada koneksi internet',
                                      );
                                    }
                                  }
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 22),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: Image.asset(
                                        AppImage.leaf.path,
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
                                        AppImage.stopwatch.path,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: Image.asset(
                                        AppImage.leafFlipped.path,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
