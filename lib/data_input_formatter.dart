import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedText = '';

    if (text.length > 0) {
      formattedText += text.substring(0, text.length > 2 ? 2 : text.length);
      if (text.length > 2) {
        formattedText += '/';
        formattedText += text.substring(2, text.length > 4 ? 4 : text.length);
      }
      if (text.length > 4) {
        formattedText += '/';
        formattedText += text.substring(4, text.length > 8 ? 8 : text.length);
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
