import 'package:flutter/material.dart';

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  // Safe setState
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // Safe context usage, e.g., Navigator, Snackbar
  void safeContext(VoidCallbackWithContext fn) {
    if (mounted) {
      fn(context);
    }
  }
}

typedef VoidCallbackWithContext = void Function(BuildContext context);
