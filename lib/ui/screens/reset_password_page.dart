import 'package:absensitoko/core/constants/items_list.dart';
import 'package:absensitoko/core/themes/colors/colors.dart';
import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/data/providers/user_provider.dart';
import 'package:absensitoko/ui/widgets/custom_text_form_field.dart';
import 'package:absensitoko/utils/base/base_state.dart';
import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends BaseState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  bool _firstSubmit = true;

  void _resetPassword() async {
    setState(() {
      _firstSubmit = false;
    });

    _emailFocusNode.unfocus();
    LoadingDialog.show(context);
    try {
      final response = await Provider.of<UserProvider>(context, listen: false)
          .resetPassword(_emailController.text);

      if (response.status == 'success') {
        safeContext((context) {
          LoadingDialog.hide(context);
          // SnackbarUtil.showSnackbar(
          //     context: context, message: response.message ?? 'Success');
          DialogUtils.popUp(
            context,
            title: 'Berhasil',
            barrierDismissible: true,
            content: const Text(
              'Link atur ulang Kata Sandi telah dikirimkan ke email yang anda masukkan. Silahkan cek kotak masuk email anda.',
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'Mulish',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            onConfirm: () {
              Navigator.pop(context);
            },
          );
        });
      } else {
        safeContext((context) {
          LoadingDialog.hide(context);
          SnackbarUtil.showSnackbar(
              context: context, message: response.message ?? 'Error');
        });
      }
    } catch (e) {
      safeContext((context) {
        SnackbarUtil.showSnackbar(context: context, message: 'Error: $e');
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
  }

  @override
  void dispose() {
    _emailController.removeListener(() {});
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _emailFocusNode.unfocus();
        _formKey.currentState?.reset();
      },
      child: Scaffold(
        // backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: const Text('Reset Kata Sandi'),
          backgroundColor: Colors.brown,
        ),
        body: GestureDetector(
          onTap: () {
            _emailFocusNode.unfocus();
            _formKey.currentState?.reset();
          },
          child: Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    AppImage.attendanceApp.path,
                    width: 200,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Reset password akun\nAbsensi Toko',
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ), textAlign: TextAlign.center,),
                  const SizedBox(height: 20,),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _firstSubmit
                          ? AutovalidateMode.disabled
                          : AutovalidateMode.always,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: ColorsTheme.blueBD,
                                surfaceTintColor: Colors.white),
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                DialogUtils.showConfirmationDialog(
                                  context: context,
                                  title: 'Konfirmasi',
                                  content: const Text(
                                    'Link atur ulang Kata Sandi akan dikirimkan ke email yang anda masukkan.\n\nAtur ulang Kata Sandi?',
                                    textAlign: TextAlign.justify,
                                  ),
                                  onConfirm: _resetPassword,
                                );
                              } else {
                                setState(() {
                                  _firstSubmit = false;
                                });
                              }
                            },
                            child: const Text(
                              'Reset Kata Sandi',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
