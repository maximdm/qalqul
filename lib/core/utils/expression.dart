import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';

/// Shared math expression evaluator used by the calculator and the notes
/// inline-math engine, so `× ÷ − π` handling and trig/deg logic stay in one
/// place.
///
/// Returns the numeric result, or `null` if the expression cannot be evaluated
/// (parse error, NaN or Infinity). [variables] lets callers inject named values
/// (e.g. note variables or memory).
double? evaluateExpr(
  String expr, {
  Map<String, double>? variables,
  bool degrees = false,
}) {
  try {
    var prepared = expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi');

    // `√` opens the root call, so an explicit `√(` just supplies the paren.
    prepared = prepared.replaceAll('√(', 'sqrt(').replaceAll('√', 'sqrt(');

    if (degrees) {
      // Inverse trig names end with `sin(`/`cos(`/`tan(`, so the forward
      // replacements below would corrupt them. Park them behind markers
      // first, then restore them: the argument is converted to radians and
      // the result is converted back, since the answer is an angle.
      prepared = prepared
          .replaceAll('arcsin(', 'QQASIN(')
          .replaceAll('arccos(', 'QQACOS(')
          .replaceAll('arctan(', 'QQATAN(')
          .replaceAll('sin(', 'sin((pi/180)*')
          .replaceAll('cos(', 'cos((pi/180)*')
          .replaceAll('tan(', 'tan((pi/180)*')
          .replaceAll('QQASIN(', '180/pi*arcsin((pi/180)*')
          .replaceAll('QQACOS(', '180/pi*arccos((pi/180)*')
          .replaceAll('QQATAN(', '180/pi*arctan((pi/180)*');
    }

    final ast = ShuntingYardParser().parse(prepared);
    final ctx = ContextModel();
    ctx.bindVariable(Variable('pi'), Number(math.pi));
    ctx.bindVariable(Variable('E'), Number(math.e));
    for (final e in (variables ?? const {}).entries) {
      ctx.bindVariable(Variable(e.key), Number(e.value));
    }
    final val = RealEvaluator(ctx).evaluate(ast);
    if (val is! double || val.isNaN || val.isInfinite) return null;
    return val;
  } catch (_) {
    return null;
  }
}
