import 'package:flutter/services.dart';

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lower = newValue.text.toLowerCase();
    return TextEditingValue(
      text: lower,
      selection: TextSelection.collapsed(offset: lower.length),
      composing: TextRange.empty,
    );
  }
}
