import 'dart:async';

import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:absensitoko/core/themes/colors/colors.dart';
import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/utils/display_size_util.dart';

class DialogUtils {
  static Future<void> loading(
      BuildContext context, GlobalKey key, String text) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: SimpleDialog(
            key: key,
            backgroundColor: Colors.black54,
            children: <Widget>[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      text,
                      style: const TextStyle(color: Colors.white),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  static Future<void> popUp(
    BuildContext context, {
    String? title,
    bool barrierDismissible = false,
    required Widget content,
    String? confirmButton,
    VoidCallback? onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title ?? 'Informasi',
            // style: FontTheme.size20Bold(color: Colors.black),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: content,
          ),
          actions: [
            Center(
              child: SizedBox(
                width: 120,
                child: FilledButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsTheme.blueBD,
                  ),
                  onPressed: () {
                    if (onConfirm != null) onConfirm();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    confirmButton ?? 'Ok',
                    style: FontTheme.bodySmall(context, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> showExpiredDialog(
    BuildContext context, {
    required String title,
    required String content,
    String buttonText = 'Ok',
    bool barrierDismissible = false,
    bool canPop = false,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: canPop,
          child: AlertDialog(
            title: Text(
              title,
              textAlign: TextAlign.center,
            ),
            content: Text(
              content,
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              Center(
                child: SizedBox(
                  width: 120,
                  child: FilledButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsTheme.blueBD,
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    child: Text(
                      buttonText,
                      style: FontTheme.bodySmall(context, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    String? confirm,
    String? cancel,
    bool withPop = true,
    bool barrierDismissible = false,
    required Widget content,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        final width = screenWidth(context);
        return AlertDialog(
          title: Text(
            title,
            textAlign: TextAlign.center,
          ),
          content: content,
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: width * 0.30,
                  child: FilledButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsTheme.grayBD,
                    ),
                    onPressed: () {
                      if (onCancel != null) onCancel();
                      if (withPop) {
                        Navigator.of(context)
                            .pop(false); // Kembalikan false saat dibatalkan
                      }
                    },
                    child: Center(
                      child: Text(
                        cancel ?? 'Tidak',
                        style:
                            FontTheme.bodyMedium(context, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: width * 0.30,
                  child: FilledButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsTheme.blueBD,
                    ),
                    onPressed: () {
                      if (withPop) {
                        Navigator.of(context)
                            .pop(true); // Kembalikan true saat dikonfirmasi
                      }
                      if (onConfirm != null) onConfirm();
                    },
                    child: Center(
                      child: Text(
                        confirm ?? 'Ya',
                        style:
                            FontTheme.bodyMedium(context, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> showAttendanceDialog({
    required BuildContext context,
    required String title,
    required ValueNotifier<int> remainingSecondsNotifier,
    String? confirm,
    String? cancel,
    bool withPop = true,
    bool barrierDismissible = false,
    required Widget content,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        final width = screenWidth(context);
        return AlertDialog(
          title: Text(
            title,
            textAlign: TextAlign.center,
          ),
          content: content,
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: width * 0.30,
                  child: FilledButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsTheme.grayBD,
                    ),
                    onPressed: () {
                      if (onCancel != null) onCancel();
                      if (withPop) {
                        Navigator.of(context)
                            .pop(false); // Kembalikan false saat dibatalkan
                      }
                    },
                    child: Center(
                      child: Text(
                        cancel ?? 'Tidak',
                        style:
                        FontTheme.bodyMedium(context, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: width * 0.30,
                  child: FilledButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsTheme.blueBD,
                    ),
                    onPressed: () {
                      if (withPop) {
                        Navigator.of(context)
                            .pop(true); // Kembalikan true saat dikonfirmasi
                      }
                      if (onConfirm != null) onConfirm();
                    },
                    child: Center(
                      child: Text(
                        confirm ?? 'Ya',
                        style:
                        FontTheme.bodyMedium(context, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Belum di cek, nanti ada lagi dialog khusus untuk ketika absen (late ada textField keterangan)
/*  static void showEditDialogDropDownMenu({
    required BuildContext context,
    String? title,
    String? subtitle,
    List<UserModel>? listAllUser,
    UserModel? dataUser,
    Pembukuan? editedData,
    required Future<void> Function(
        Pembukuan? updatedData, UserModel? updatedUser)
    onUpdate,
  }) {
    String selectedValue = '';
    UserModel? selectedUser;
    List<String> menuEntries = [];
    List<UserModel> filteredUser = [];

    // Logika untuk menyiapkan menuEntries dan filteredUser
    if (title == 'Status Pesanan') {
      menuEntries = statusList;
    } else if (title == 'Nama Agen' || title == 'Nama Pengirim') {
      filteredUser = listAllUser?.where((user) {
        if (title == 'Nama Agen') {
          return user.role == 'agent' || user.role == 'admin';
        } else {
          return user.role == 'sender' || user.role == 'admin';
        }
      }).toList() ??
          [];
      menuEntries = filteredUser.map((user) {
        if (user.role == 'admin') {
          return '${user.displayName!} (admin)';
        } else {
          return user.displayName!;
        }
      }).toList();
    } else if (title == 'Role') {
      menuEntries = roleList.where((role) => role != 'admin').toList();
      selectedUser = dataUser;
    }

    TextEditingController editFieldController =
    TextEditingController(text: subtitle);

    DialogUtils.showConfirmationDialog(
      context: context,
      title: 'Edit $title',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomDropdownMenu(
            title: title ?? '',
            controller: editFieldController,
            hintText: subtitle,
            dropdownMenuEntries: menuEntries.map((value) {
              return DropdownMenuEntry<String>(
                label: value,
                value: value,
                style: MenuItemButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                ),
              );
            }).toList(),
            onSelected: (value) {
              selectedValue = value!;
              print('Selected Value: $selectedValue');
              if (title != 'Role') {
                if (title != 'Status Pesanan') {
                  selectedUser = filteredUser.firstWhere((user) =>
                  user.displayName == value ||
                      '${user.displayName} (admin)' == value);
                }
                if (title == 'Status Pesanan' && value == 'New Order') {
                  DialogUtils.popUp(
                    context,
                    content: const Text(
                      'Mengembalikan Status Pesanan ke New Order akan menghapus data pengirim yang sudah ada.',
                      textAlign: TextAlign.justify,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      withPop: false,
      onCancel: () {
        Navigator.pop(context);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          editFieldController.dispose();
          print('Berhasil dispose');
        });
      },
      onConfirm: () async {
        if (selectedValue.isEmpty) {
          Navigator.pop(context);
          SchedulerBinding.instance.addPostFrameCallback((_) {
            editFieldController.dispose();
            SnackbarUtil.showSnackbar(
                context: context, message: 'Tidak ada perubahan');
            print('Berhasil dispose');
          });
        } else {
          if (title == 'Role') {
            if (selectedUser != null) {
              selectedUser!.role = selectedValue;
            }
          } else {
            if (title == 'Status Pesanan') {
              editedData?.statusPesanan = selectedValue;
              if (editedData?.statusPesanan == 'New Order') {
                SnackbarUtil.showSnackbar(
                    context: context,
                    message:
                    'Mengganti $title \nDari: ${editedData?.namaPengirim} Ke: $selectedValue');
                editedData?.namaPengirim = ' ';
                editedData?.hpPengirim = ' ';
              }
            } else if (title == 'Nama Agen') {
              SnackbarUtil.showSnackbar(
                  context: context,
                  message:
                  'Mengganti $title \nDari: ${editedData?.namaAgen} Ke: $selectedValue');
              editedData?.namaAgen = selectedValue;
              editedData?.kota = selectedUser?.city;
              editedData?.instansi = selectedUser?.department;
            } else if (title == 'Nama Pengirim') {
              SnackbarUtil.showSnackbar(
                  context: context,
                  message:
                  'Mengganti $title \nDari: ${editedData?.namaPengirim} Ke: $selectedValue');
              editedData?.namaPengirim = selectedValue;
              editedData?.hpPengirim = selectedUser?.phoneNumber;
            }
          }

          // Pop Dulu biar bisa push replacement di callback
          Navigator.pop(context);

          // Panggil callback dengan data yang sudah di-update setelah dialog di tutup
          await onUpdate(editedData, selectedUser);

          SchedulerBinding.instance.addPostFrameCallback((_) {
            editFieldController.dispose();
            print('Berhasil dispose');
          });
        }
      },
    );
  }*/

// List<UserModel> filterUsersByRole(List<UserModel> users, String role) {
//   return users.where((user) => user.role == role).toList();
// }
}
