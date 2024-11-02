/*
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:absensitoko/models/attendance_model.dart.dart';
import 'package:absensitoko/models/user_model.dart';
import 'package:absensitoko/utils/custom_drop_down_menu.dart';
import 'package:absensitoko/utils/dialog_utils.dart';
import 'package:absensitoko/utils/general_helper.dart';
import 'package:absensitoko/utils/items_list.dart';

class DialogManager {
  static void showEditDialogDropDownMenu({
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
  }

// List<UserModel> filterUsersByRole(List<UserModel> users, String role) {
//   return users.where((user) => user.role == role).toList();
// }
}
*/
