import 'package:qalqul/core/utils/expression.dart';

/// Inline math evaluation for notes.
///
/// Recognises `name = expression` definitions anywhere in the note text and
/// substitutes those variables when evaluating a target expression, so a line
/// like `width * height` can use values defined on earlier lines.
class NoteExpression {
  const NoteExpression._();

  /// Evaluate [target] using variables collected from [fullText].
  /// Returns the numeric result, or `null` if it cannot be evaluated.
  static double? evaluate(String fullText, String target) {
    final vars = _collectVars(fullText);
    return evaluateExpr(target, variables: vars);
  }

  /// Evaluate a standalone arithmetic [expr] (no cross-line variables).
  /// Returns the numeric result, or `null` if it cannot be evaluated.
  static double? compute(String expr) => evaluateExpr(expr);

  static Map<String, double> _collectVars(String text) {
    final vars = <String, double>{};
    // A definition is a line that begins with `identifier = expression`.
    final re = RegExp(r'^([a-zA-Z_]\w*)\s*=\s*([^=\n;]+)', multiLine: true);
    for (final m in re.allMatches(text)) {
      final name = m.group(1)!;
      final rhs = m.group(2)!.trim();
      final v = evaluateExpr(rhs, variables: vars);
      if (v != null) vars[name] = v;
    }
    return vars;
  }
}
