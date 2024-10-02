/*
import 'package:flutter/material.dart';
import 'package:absensitoko/themes/fonts/Fonts.dart';
import 'package:absensitoko/utils/DialogUtils.dart';

class CustomDropdownMenu extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialSelection;
  final String? hintText;
  final String? title;
  final String? label;
  final TextStyle? textStyle;
  final List<DropdownMenuEntry<String>>? dropdownMenuEntries;
  final void Function(String?)? onSelected;
  final double menuHeight;
  final InputDecorationTheme? inputDecorationTheme;
  final EdgeInsets expandedInsets;
  final MenuStyle? menuStyle;
  final String? errorText;
  final bool enableFilter;

  const CustomDropdownMenu({
    super.key,
    this.controller,
    this.focusNode,
    this.initialSelection,
    this.hintText,
    this.title,
    this.label,
    this.textStyle,
    this.dropdownMenuEntries,
    this.onSelected,
    this.menuHeight = 200,
    this.inputDecorationTheme,
    this.expandedInsets = EdgeInsets.zero,
    this.menuStyle,
    this.errorText,
    this.enableFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      initialSelection: initialSelection,
      controller: controller,
      focusNode: focusNode,
      errorText: errorText,
      enableFilter: enableFilter,
      label: label == null ? null : Text(label!, style: FontTheme.mulishSize16Bold(color: Colors.white)),
      hintText: hintText,
      textStyle: textStyle ?? FontTheme.mulishSize16Bold(),
      expandedInsets: expandedInsets,
      inputDecorationTheme: inputDecorationTheme ??
          const InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(horizontal: 20),
            errorStyle: TextStyle(height: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
            ),
          ),
      menuHeight: menuHeight,
      menuStyle: menuStyle ??
          MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.blueGrey[50]),
            elevation: WidgetStateProperty.all(8),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
      dropdownMenuEntries: dropdownMenuEntries ?? [],
      onSelected: onSelected,
    );
  }
}
*/
