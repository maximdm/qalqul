import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/app.dart';
import 'package:qalqul/features/finance/reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderService.init();
  runApp(const ProviderScope(child: QalqulApp()));
  unawaited(ReminderService.scheduleDueSoon());
}
