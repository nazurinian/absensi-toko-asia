import 'package:absensitoko/models/UserModel.dart';
import 'package:absensitoko/provider/DataProvider.dart';
import 'package:absensitoko/provider/TimeProvider.dart';
import 'package:absensitoko/provider/UserProvider.dart';
import 'package:absensitoko/themes/colors/Colors.dart';
import 'package:absensitoko/themes/fonts/Fonts.dart';
import 'package:absensitoko/utils/BaseState.dart';
import 'package:absensitoko/utils/DialogUtils.dart';
import 'package:absensitoko/utils/DisplaySize.dart';
import 'package:absensitoko/utils/Helper.dart';
import 'package:absensitoko/utils/ListMenu.dart';
import 'package:absensitoko/utils/LoadingDialog.dart';
import 'package:absensitoko/utils/ThemeUtil.dart';
import 'package:absensitoko/views/LoginPage.dart';
import 'package:absensitoko/views/ProfilePage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BaseState<HomePage> {
  String? displayName = '';
  String infoAkun = '';

  UserModel? _user;

  // bool _lockAccess = false;

  void _fetchUserdata() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    UserModel? userData = userProvider.currentUser;

    if (!userProvider.userDataIsLoaded) {
      try {
        await userProvider.loadUserSession();
        final userDataSession = userProvider.currentUserSession;

        final message = await userProvider.getUser(userDataSession!.uid);

        if (message.status == 'success') {
          userData = userProvider.currentUser;
          setState(() {
            _user = userData;
            displayName = userData?.displayName ?? '';
          });
          ToastUtil.showToast('Berhasil memperoleh data', ToastStatus.success);
        } else {
          ToastUtil.showToast(message.message ?? '', ToastStatus.error);
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentTime = Provider.of<TimeProvider>(context, listen: false)
        .currentTime
        .postTime();

    LoadingDialog.show(context);
    try {
      String uid = _user!.uid;
      final message = await userProvider.updateUserProfile(uid,
          logoutTimestamp: currentTime, logout: true);

      if (message.status == 'success') {
        final message = await userProvider.signOut();

        if (message.status == 'success') {
          print('Tai kambing?');
          Future.delayed(const Duration(seconds: 1), () {
            LoadingDialog.hide(context);
            SnackbarUtil.showSnackbar(
                context: context, message: 'Anda telah logout');

            userProvider.clearAccountData();
            Provider.of<DataProvider>(context, listen: false).clearData();
            print('Data Cleared');
          }).then((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          });
          // });
        } else {
          safeContext((context) {
            LoadingDialog.hide(context);
            SnackbarUtil.showSnackbar(
                context: context, message: message.message ?? 'Error');
          });
        }
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

  @override
  void initState() {
    super.initState();
    _fetchUserdata();
  }

  @override
  void dispose() {
    super.dispose();
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
        SafeArea(
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(
                                    child: PopupMenuButton(
                                      offset: const Offset(0, 50),
                                      onSelected: (value) async {
                                        if (value == 'logout') {
                                          DialogUtils.showConfirmationDialog(
                                            context: context,
                                            title: 'Logout',
                                            content: const Text(
                                                'Keluar dari aplikasi?'),
                                            onConfirm: () => _handleLogout(),
                                          );
                                        } else if (value == 'profile') {
                                          bool updateProfile =
                                              await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ProfilePage()),
                                          );
                                          if (updateProfile) {
                                            _fetchUserdata();
                                          }
                                          // Memastikan data diperbarui setelah kembali dari halaman edit
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            Provider.of<UserProvider>(context,
                                                    listen: false)
                                                .getUser(_user!.uid);
                                          });
                                        }
                                      },
                                      itemBuilder: (context) {
                                        final imageUrl = _user?.photoURL ?? '';

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
                                                      placeholder:
                                                          (context, url) =>
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
                                  color: Theme.of(context).colorScheme.primary,
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
                                      onTap: () {
                                        Navigator.pushNamed(context, '/absensi',
                                            arguments: _user != null
                                                ? _user?.displayName
                                                    ?.toUpperCase()
                                                : 'ANONYMOUS');
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                                              alignment: Alignment.centerRight,
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
                                              alignment: Alignment.centerRight,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: FilledButton(
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                      context, '/absensi',
                                                      arguments: _user != null
                                                          ? _user?.displayName
                                                              ?.toUpperCase()
                                                          : 'ANONYMOUS');
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
                                        Center(
                                          child: Text(
                                            _user != null
                                                ? "${_user!.uid}\n${_user!.email}\n${_user!.displayName}\n${_user!.phoneNumber}\n${_user!.city}\n${_user!.institution}\n${_user!.role}\n${_user!.photoURL}\n${_user!.firstTimeLogin}\n${_user!.loginTimestamp}\n${_user!.logoutTimestamp}"
                                                : 'Kosong',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              ToastUtil.showToast(
                                                  'Fitur belum tersedia',
                                                  ToastStatus.warning);
                                              // Fluttertoast.showToast(
                                              //     msg: 'Print Akun Saat Ini');
                                              // _fetchUserdata();
                                              // setState(() {
                                              //   infoAkun = 'Akun saat ini';
                                              // });
                                            },
                                            child: const Text('Print Akun'),
                                          ),
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
      ],
    );
  }
}
