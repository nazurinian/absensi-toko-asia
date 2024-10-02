import 'package:flutter/material.dart';
import 'package:absensitoko/models/SessionModel.dart';
import 'package:absensitoko/provider/TimeProvider.dart';
import 'package:absensitoko/utils/BaseState.dart';
import 'package:absensitoko/utils/CustomTextFormField.dart';
import 'package:absensitoko/utils/Helper.dart';
import 'package:absensitoko/utils/ListItem.dart';
import 'package:absensitoko/utils/LoadingDialog.dart';
import 'package:absensitoko/views/HomePage.dart';
import 'package:absensitoko/provider/UserProvider.dart';
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

  void _unFocus() {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
  }

  Future<void> _login() async {
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
    try {
      final message = await userProvider.loginUser(
        _emailController.text,
        _passwordController.text,
        currentTime,
      );

      if (message.status == 'success') {
        final userData = userProvider.currentUser!;

        if (userProvider.currentUser != null) {
          final user = SessionModel(
            uid: userData.uid,
            email: userData.email,
            role: userData.role,
            loginTimestamp: userData.loginTimestamp,
            isLogin: true,
          );

          await userProvider.saveSession(user);

          safeContext((context) {
            LoadingDialog.hide(context);
            SnackbarUtil.showSnackbar(
                context: context, message: message.message ?? '');

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
              (route) => false,
            );
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    // child: Image.asset(AppImage.kamus.path, fit: BoxFit.cover),
                    child: const Icon(
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
                              onPressed: _login,
                              child: const Text(
                                'Login',
                                style:
                                    TextStyle(color: Colors.blue, fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Padding(
                        //       padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        //       child: Row(
                        //         children: [
                        //           SizedBox(
                        //             height: 40,
                        //             width: 40,
                        //             child: Image.asset(
                        //               AppImage.najwa.path,
                        //               fit: BoxFit.cover,
                        //             ),
                        //           ),
                        //           const SizedBox(
                        //             width: 5,
                        //           ),
                        //           SizedBox(
                        //             height: 70,
                        //             width: 70,
                        //             child: Image.asset(
                        //               AppImage.najwa.path,
                        //               fit: BoxFit.cover,
                        //             ),
                        //           ),
                        //           const SizedBox(
                        //             width: 5,
                        //           ),
                        //           SizedBox(
                        //             height: 40,
                        //             width: 40,
                        //             child: Image.asset(
                        //               AppImage.najwa.path,
                        //               fit: BoxFit.cover,
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
