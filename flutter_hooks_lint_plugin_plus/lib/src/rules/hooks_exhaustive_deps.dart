import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart' hide LintCode;
import 'package:custom_lint_core/custom_lint_core.dart' show LintCode;

class HooksExhaustiveDeps extends DartLintRule {
  HooksExhaustiveDeps({CustomLintConfigs? configs})
      : constantHooks = _parseConstantHooks(configs),
        super(code: _code);

  final Set<String> constantHooks;

  static const _code = LintCode(
    name: 'hooks_exhaustive_deps',
    problemMessage: 'Missing or unnecessary dependencies in useEffect hook.',
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

  static Set<String> _parseConstantHooks(CustomLintConfigs? configs) {
    // Default constant hooks based on flutter_hooks
    const defaultConstantHooks = {
      'useRef',
      'useIsMounted',
      'useFocusNode',
      'useContext',
    };

    if (configs == null) return defaultConstantHooks;

    // Parse constant_hooks from analysis_options.yaml using the same structure as the original plugin
    // flutter_hooks_lint_plugin:
    //   exhaustive_keys:
    //     constant_hooks:
    //       - useRef
    //       - useIsMounted
    //       - useFocusNode
    //       - useContext
    // Parse constant_hooks from custom_lint rules configuration
    // Rules is Map<String, LintOptions> where LintOptions contains the rule config
    try {
      final rules = configs.rules;
      final lintOptions = rules['hooks_exhaustive_deps'];
      if (lintOptions != null) {
        // Access the configuration data from LintOptions
        final ruleConfig = lintOptions.json;
        final constantHooksList = ruleConfig['constant_hooks'];
        if (constantHooksList is List) {
          final configuredHooks = constantHooksList.whereType<String>().toSet();
          if (configuredHooks.isNotEmpty) {
            // Use configured hooks in addition to defaults
            return {...defaultConstantHooks, ...configuredHooks};
          }
        }
      }
    } catch (e) {
      // If config parsing fails, fall back to defaults
      print('Warning: Failed to parse constant_hooks config: $e');
    }

    return defaultConstantHooks;
  }

  void _checkUseEffect(MethodInvocation node, ErrorReporter reporter) {
    if (node.methodName.name != 'useEffect') return;

    final arguments = node.argumentList.arguments;
    if (arguments.length < 2) return;

    final callback = arguments[0];
    final dependencies = arguments[1];

    final usedVariables = <String>{};
    final declaredDependencies = <String>{};

    callback.accept(_VariableVisitor(usedVariables, constantHooks));

    if (dependencies is ListLiteral) {
      for (final element in dependencies.elements) {
        if (element is SimpleIdentifier) {
          declaredDependencies.add(element.name);
        }
      }
    }

    // Find constant hook variables by scanning the containing function
    final constantHookVariables = _findConstantHookVariables(node);

    // Exclude constant hook variables from missing dependencies
    final actualUsedVariables = usedVariables.difference(constantHookVariables);
    final missingDeps = actualUsedVariables.difference(declaredDependencies);

    // For unnecessary deps, check both unused deps and constant hooks in deps
    final declaredConstantHooks =
        declaredDependencies.intersection(constantHookVariables);
    final unusedDeps = declaredDependencies.difference(usedVariables);
    final unnecessaryDeps = unusedDeps.union(declaredConstantHooks);

    if (missingDeps.isNotEmpty || unnecessaryDeps.isNotEmpty) {
      final message = StringBuffer();
      if (missingDeps.isNotEmpty) {
        message.write('Missing dependencies: ${missingDeps.join(', ')}');
      }
      if (unnecessaryDeps.isNotEmpty) {
        if (message.isNotEmpty) message.write('. ');
        message
            .write('Unnecessary dependencies: ${unnecessaryDeps.join(', ')}');
      }

      reporter.atNode(
        node,
        _code,
        arguments: [message.toString()],
      );
    }
  }

  Set<String> _findConstantHookVariables(MethodInvocation useEffectNode) {
    final constantHookVariables = <String>{};

    // Find the containing function
    AstNode? current = useEffectNode;
    while (current != null) {
      if (current is FunctionDeclaration) {
        final body = current.functionExpression.body;
        if (body is BlockFunctionBody) {
          _scanBlockForConstantHooks(body.block, constantHookVariables);
        }
        break;
      } else if (current is MethodDeclaration) {
        final body = current.body;
        if (body is BlockFunctionBody) {
          _scanBlockForConstantHooks(body.block, constantHookVariables);
        }
        break;
      }
      current = current.parent;
    }

    return constantHookVariables;
  }

  void _scanBlockForConstantHooks(
      Block block, Set<String> constantHookVariables) {
    for (final statement in block.statements) {
      if (statement is VariableDeclarationStatement) {
        for (final variable in statement.variables.variables) {
          final init = variable.initializer;
          if (init is MethodInvocation &&
              constantHooks.contains(init.methodName.name)) {
            constantHookVariables.add(variable.name.lexeme);
          }
        }
      }
    }
  }
}

class _VariableVisitor extends RecursiveAstVisitor<void> {
  final Set<String> variables;
  final Set<String> constantHookNames;

  _VariableVisitor(this.variables, this.constantHookNames);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;

    // 関数呼び出しの関数名は除外
    if (node.parent is MethodInvocation &&
        (node.parent as MethodInvocation).methodName == node) {
      return;
    }

    // それ以外は変数として検出
    variables.add(name);
    super.visitSimpleIdentifier(node);
  }
}
