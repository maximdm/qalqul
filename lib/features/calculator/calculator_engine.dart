import 'package:qalqul/core/utils/expression.dart';

String? evaluateExpression(String expr, {bool degrees = false}) {
  final val = evaluateExpr(expr, degrees: degrees);
  if (val == null) return null;
  if (val == val.roundToDouble()) return val.toInt().toString();
  final fixed = val.toStringAsFixed(10);
  return fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}
