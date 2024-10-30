import 'dart:async';

import 'package:flutter/material.dart';
import 'package:absensitoko/themes/colors/Colors.dart';
import 'package:absensitoko/themes/fonts/Fonts.dart';
import 'package:absensitoko/utils/DisplaySize.dart';

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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(63, 82, 119, 1.0),
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
                      if (withPop ?? true)
                        Navigator.of(context)
                            .pop(false); // Kembalikan false saat dibatalkan
                    },
                    child: Center(
                      child: Text(
                        cancel ?? 'Tidak',
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
                      if (withPop ?? true) {
                        Navigator.of(context)
                            .pop(true); // Kembalikan true saat dikonfirmasi
                      }
                      if (onConfirm != null) onConfirm();
                    },
                    child: Center(
                      child: Text(
                        confirm ?? 'Ya',
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
}

/*  static showConfirmationDialog({
    required BuildContext context,
    required String title,
    String? confirm,
    String? cancel,
    bool? withPop = true,
    required Widget content,
    required VoidCallback
        onConfirm, // required FutureOr<dynamic> Function()? onConfirm,
    VoidCallback? onCancel, // FutureOr<dynamic> Function()? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final width = screenWidth(context);
        return AlertDialog(
          title: Text(
            title,
            textAlign: TextAlign.center,
            // style: FontTheme.size20Bold(color: Colors.black),
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
                      if (onCancel != null) onCancel(); // await onCancel();
                      if (withPop ?? true) Navigator.of(context).pop();
                    },
                    child: Center(
                      child: Text(
                        cancel ?? 'Tidak',
                        // style: FontTheme.size14Bold(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                SizedBox(
                  width: width * 0.30,
                  child: FilledButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsTheme.blueBD,
                    ),
                    onPressed: () {
                      if (withPop ?? true) Navigator.of(context).pop();
                      onConfirm(); // if (onConfirm != null) await onConfirm();
                    },
                    child: Center(
                      child: Text(
                        confirm ?? 'Ya',
                        // style: FontTheme.size14Bold(color: Colors.white),
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
}*/
