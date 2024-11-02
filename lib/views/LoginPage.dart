import 'package:absensitoko/api/ApiResult.dart';
import 'package:absensitoko/utils/DeviceUtils.dart';
import 'package:absensitoko/utils/ListItem.dart';
import 'package:absensitoko/utils/NetworkHelper.dart';
import 'package:flutter/material.dart';
import 'package:absensitoko/models/SessionModel.dart';
import 'package:absensitoko/provider/TimeProvider.dart';
import 'package:absensitoko/utils/BaseState.dart';
import 'package:absensitoko/utils/CustomTextFormField.dart';
import 'package:absensitoko/utils/Helper.dart';
import 'package:absensitoko/utils/LoadingDialog.dart';
import 'package:absensitoko/provider/UserProvider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends BaseState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _firstSubmit = true;

  String _attendanceLocationStatus = 'Get Location Permission';
  LatLng? _attendanceLocation;
  String _deviceName = '';

  // Minta izin akses lokasi
  Future<void> _cekIzinLokasi() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _attendanceLocationStatus = 'Izin lokasi belum diberikan';
      });
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _attendanceLocationStatus =
              'Izin lokasi ditolak, harap berikan izin lokasi';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _attendanceLocationStatus =
            'Izin lokasi ditolak permanen, harap berikan izin lokasi di pengaturan';
      });
      openAppSettings();
      return;
    }
  }

  // Cek apakah pengguna berada dalam radius absensi
  Future<void> _cekLokasiSekali() async {
    try {
      Position posisiPengguna = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _attendanceLocation = LatLng(
          posisiPengguna.latitude,
          posisiPengguna.longitude,
        );
      });
    } catch (e) {
      setState(() {
        _attendanceLocationStatus = 'Terjadi kesalahan: $e';
      });
      safeContext((context) => LoadingDialog.hide(context));
    }

  }

  Future<void> _login() async {
    _cekIzinLokasi();

    // Set state untuk first submit dan validasi form
    _firstSubmit = false;
    if (!_validateForm()) return;

    _unFocus();
    LoadingDialog.show(context);

    // Cek lokasi dan ambil nama perangkat
    await _cekLokasiSekali();
    await _fetchDeviceName();

    // Lakukan proses login
    try {
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

    _cekIzinLokasi();
    _controllerListener();
  }

  @override
  void dispose() {
    _emailController.removeListener(() {});
    _passwordController.removeListener(() {});
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
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
                const Padding(
                  padding: EdgeInsets.only(top: 50.0, bottom: 20),
                  child: Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      // child: Image.asset(AppImage.kamus.path, fit: BoxFit.cover),
                      child: Icon(
                        Icons.account_circle,
                        size: 120,
                      ),
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
                                    SnackbarUtil.showSnackbar(
                                      context: context,
                                      message: 'Tidak ada koneksi internet',
                                    );
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
                                        AppImage.leaf_flipped.path,
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

// Fungsi login sebelum disederhanakan
/*  Future<void> _login() async {
    _cekIzinLokasi();

    setState(() {
      _firstSubmit = false;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _unFocus();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentTime = Provider.of<TimeProvider>(context, listen: false)
        .currentTime
        .postTime();

    LoadingDialog.show(context);
    await _cekLokasiSekali();

    if(mounted) {
      String deviceName = await DeviceUtils.getDeviceName(context);
      setState(() {
        _deviceName = deviceName;
      });
    }

    print('device: $_deviceName');
    try {
      safeContext((context) async {
        final message = await userProvider.loginUser(
          context,
          _emailController.text,
          _passwordController.text,
          currentTime,
          _deviceName,
          _attendanceLocation!,
        );

        if (message.status == 'success') {
          final userData = userProvider.currentUser!;

          if (userProvider.currentUser != null) {
            final user = SessionModel(
              uid: userData.uid,
              email: userData.email,
              role: userData.role,
              loginTimestamp: userData.loginTimestamp,
              loginDevice: _deviceName,
              isLogin: true,
            );

            await userProvider.saveSession(user, _deviceName);

            safeContext((context) {
              LoadingDialog.hide(context);
              SnackbarUtil.showSnackbar(
                  context: context, message: message.message ?? '');

              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            });
          } else {
            safeContext((context) {
              LoadingDialog.hide(context);
              SnackbarUtil.showSnackbar(
                  context: context, message: message.message ?? '');
            });
          }
        } else {
          safeContext((context) {
            LoadingDialog.hide(context);
            SnackbarUtil.showSnackbar(
                context: context, message: message.message ?? '');
          });
        }
      });
    } catch (e) {
      safeContext((context) {
        LoadingDialog.hide(context);
        SnackbarUtil.showSnackbar(context: context, message: e.toString());
      });
    }
  }*/
}
