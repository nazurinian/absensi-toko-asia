import 'package:absensitoko/utils/time_picker_util.dart';
import 'package:flutter/material.dart';

class BreaktimeField extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final GlobalKey<FormState>? formKey;
  final String? labelText;
  final String? prefixText;
  final String? hintText;
  final String? errorMessage;
  final bool readonly;
  final void Function()? onTap;
  final void Function()? onConfirm;
  final void Function(String)? onChanged;
  final void Function()? onCancel;

  const BreaktimeField({
    super.key,
    required this.focusNode,
    required this.controller,
    this.formKey,
    this.labelText,
    this.prefixText,
    this.hintText,
    this.errorMessage,
    this.readonly = false,
    this.onTap,
    this.onConfirm,
    this.onChanged,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              focusNode: focusNode,
              controller: controller,
              keyboardType: TextInputType.none,
              readOnly: readonly,
              onTap: labelText == 'breaktime'
                  ? () {
                      TimePicker.customTime(context, 'Waktu Istirahat',
                          onSelectedTime: (time) {
                        if (time.isNotEmpty) {
                          controller.text = time;
                          formKey?.currentState?.validate();
                        } else {
                          if (onCancel != null) {
                            onCancel!();
                            // formKey?.currentState?.validate();
                          }
                        }
                      });
                    }
                  : onTap,
              style: Theme.of(context).textTheme.titleMedium,
              decoration: InputDecoration(
                prefixText: prefixText,
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                // if (onChanged != null) {
                //   onChanged!(value);
                // }
                if(value.isNotEmpty) {
                  formKey?.currentState?.validate();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return errorMessage;
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              if (formKey?.currentState?.validate() ?? false) {
                if(onConfirm != null) {
                  focusNode.unfocus();
                  onConfirm!();
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
