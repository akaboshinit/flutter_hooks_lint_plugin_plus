import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart' hide LintCode;
import 'package:custom_lint_core/custom_lint_core.dart' show LintCode;

class HooksExhaustiveDeps extends DartLintRule {
  const HooksExhaustiveDeps() : super(code: _code);

  static const _code = LintCode(
    name: 'hooks_exhaustive_deps',
    problemMessage:
        'Missing or unnecessary dependencies in useEffect hook.',
    correctionMessage: 'Add missing dependencies or remove unnecessary ones.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      _checkUseEffect(node, reporter);
    });
  }

  void _checkUseEffect(MethodInvocation node, ErrorReporter reporter) {
    if (node.methodName.name != 'useEffect') return;

    final arguments = node.argumentList.arguments;
    if (arguments.length < 2) return;

    final callback = arguments[0];
    final dependencies = arguments[1];

    final usedVariables = <String>{};
    final declaredDependencies = <String>{};

    callback.accept(_VariableVisitor(usedVariables));

    if (dependencies is ListLiteral) {
      for (final element in dependencies.elements) {
        if (element is SimpleIdentifier) {
          declaredDependencies.add(element.name);
        }
      }
    }

    final missingDeps = usedVariables.difference(declaredDependencies);
    final unnecessaryDeps = declaredDependencies.difference(usedVariables);

    if (missingDeps.isNotEmpty || unnecessaryDeps.isNotEmpty) {
      final message = StringBuffer();
      if (missingDeps.isNotEmpty) {
        message.write('Missing dependencies: ${missingDeps.join(', ')}');
      }
      if (unnecessaryDeps.isNotEmpty) {
        if (message.isNotEmpty) message.write('. ');
        message.write('Unnecessary dependencies: ${unnecessaryDeps.join(', ')}');
      }

      reporter.atNode(
        node,
        _code,
        arguments: [message.toString()],
      );
    }
  }
}

class _VariableVisitor extends RecursiveAstVisitor<void> {
  final Set<String> variables;

  _VariableVisitor(this.variables);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;
    
    // 関数呼び出しの関数名は除外
    if (node.parent is MethodInvocation && 
        (node.parent as MethodInvocation).methodName == node) {
      return;
    }
    
    // useState関数自体は除外
    if (name == 'useState' || name == 'useEffect') {
      return;
    }
    
    // 基本的な関数名やキーワードは除外
    if (['print', 'toString', 'length', 'isEmpty', 'isNotEmpty'].contains(name)) {
      return;
    }
    
    // それ以外は変数として検出
    variables.add(name);
    super.visitSimpleIdentifier(node);
  }
}