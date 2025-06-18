import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart' hide LintCode;
import 'package:custom_lint_core/custom_lint_core.dart' show LintCode;

class HooksNoNestedUsage extends DartLintRule {
  const HooksNoNestedUsage() : super(code: _code);

  static const _code = LintCode(
    name: 'hooks_no_nested_usage',
    problemMessage:
        'React Hook "{0}" is called conditionally. React Hooks must be called in the same order every single time.',
    correctionMessage: 'Move the hook outside of the conditional statement.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      _checkHookUsage(node, reporter);
    });
  }

  void _checkHookUsage(MethodInvocation node, ErrorReporter reporter) {
    if (!_isHookMethod(node.methodName.name)) return;

    AstNode? current = node;
    while (current != null) {
      if (_isControlFlowStatement(current)) {
        reporter.atNode(
          node,
          _code,
          arguments: [node.methodName.name],
        );
        break;
      }
      current = current.parent;
    }
  }

  bool _isHookMethod(String methodName) {
    return methodName.startsWith('use') && methodName.length > 3;
  }

  bool _isControlFlowStatement(AstNode node) {
    return node is IfStatement ||
        node is WhileStatement ||
        node is ForStatement ||
        node is DoStatement ||
        node is SwitchStatement ||
        node is TryStatement ||
        node is ConditionalExpression;
  }
}