import 'package:flutter/material.dart';

class LoadingDialog {
  static void show(
    BuildContext context, {
    bool barrierDismissible = false,
    bool canPop = false,
    Function()? onPopInvoked,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, result) {
            if(!didPop) {
              if (onPopInvoked != null) onPopInvoked();
            }
          },
          child: const Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
