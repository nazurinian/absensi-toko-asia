import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ToastStatus { success, error, warning }

class ToastUtil {
  static void showToast(String message, ToastStatus status) {
    Color backgroundColor;
    Color textColor;
    switch (status) {
      case ToastStatus.success:
        backgroundColor = Colors.green;
        textColor = Colors.white70;
        break;
      case ToastStatus.error:
        backgroundColor = Colors.red;
        textColor = Colors.white70;
        break;
      case ToastStatus.warning:
        backgroundColor = Colors.yellow;
        textColor = Colors.black87;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}

class SnackbarUtil {
  static void showSnackbar({
    required BuildContext context,
    required String message,
    // Color backgroundColor = Colors.black87,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // backgroundColor: backgroundColor,
      ),
    );
  }
}
