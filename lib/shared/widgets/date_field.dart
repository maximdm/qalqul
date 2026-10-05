import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) onPick(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(DateFormat.yMMMd().format(value)),
        ),
      ),
    );
  }
}
