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

  static Future<void> popUp(BuildContext context,
      {String? title, required Widget content, String? confirmButton}) async {
    return showDialog<void>(
      context: context, barrierDismissible: false, // user must tap button!
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

  static void showConfirmationDialog({
    required BuildContext context,
    required String title,
    String? confirm,
    String? cancel,
    bool? withPop = true,
    required Widget content,
    required FutureOr<dynamic> Function()? onConfirm,
    FutureOr<dynamic> Function()? onCancel,
  }) {
    showDialog(
      context: context,
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
                    onPressed: () async {
                      if (onCancel != null) await onCancel();
                      if (withPop ?? true) Navigator.of(context).pop();
                    },
                    child: Center(
                      child: Text(
                        cancel ?? 'Tidak',
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
                    onPressed: () async {
                      if (withPop ?? true) Navigator.of(context).pop();
                      if (onConfirm != null) await onConfirm();
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
