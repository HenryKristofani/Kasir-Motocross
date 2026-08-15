import 'package:flutter/material.dart';

Future<DateTime?> showPosDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required String helpText,
}) {
  return showDatePicker(
    context: context,
    locale: const Locale('id', 'ID'),
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100, 12, 31),
    helpText: helpText,
    cancelText: 'Batal',
    confirmText: 'Pilih',
  );
}

Future<DateTimeRange?> showPosDateRangePicker({
  required BuildContext context,
  required DateTimeRange initialDateRange,
  required String helpText,
}) {
  return showDateRangePicker(
    context: context,
    locale: const Locale('id', 'ID'),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100, 12, 31),
    initialDateRange: initialDateRange,
    helpText: helpText,
    cancelText: 'Batal',
    saveText: 'Pilih',
  );
}
