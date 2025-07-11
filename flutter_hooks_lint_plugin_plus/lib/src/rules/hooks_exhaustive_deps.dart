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
    problemMessage: 'Hook deps: {0}',
    correctionMessage: 'Update the dependency array.',
  );

  LintCode get code => _code;

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
        } else if (element is IndexExpression) {
          final target = element.target;
          if (target is SimpleIdentifier) {
            declaredDependencies.add(target.name);
          }
        } else if (element is PrefixedIdentifier) {
          declaredDependencies.add(element.prefix.name);
        } else if (element is PropertyAccess) {
          final target = element.target;
          if (target is SimpleIdentifier) {
            declaredDependencies.add(target.name);
          }
        }
      }
    }

    final ignoredKeys = _getIgnoredKeys(node);
    final constantHookVariables = _findConstantHookVariables(node);

    final actualUsedVariables = usedVariables.difference(constantHookVariables);
    final missingDeps = actualUsedVariables.difference(declaredDependencies);

    final declaredConstantHooks =
        declaredDependencies.intersection(constantHookVariables);
    final unusedDeps = declaredDependencies.difference(usedVariables);
    final unnecessaryDeps = unusedDeps.union(declaredConstantHooks);

    final filteredMissingDeps = missingDeps.difference(ignoredKeys);
    final filteredUnnecessaryDeps = unnecessaryDeps.difference(ignoredKeys);

    if (filteredMissingDeps.isNotEmpty || filteredUnnecessaryDeps.isNotEmpty) {
      final parts = <String>[];

      if (filteredMissingDeps.isNotEmpty) {
        parts.add('Missing: ${filteredMissingDeps.join(', ')}');
      }

      if (filteredUnnecessaryDeps.isNotEmpty) {
        parts.add('Unnecessary: ${filteredUnnecessaryDeps.join(', ')}');
      }

      final message = parts.join(', ');

      reporter.atNode(
        node,
        _code,
        arguments: [message],
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

  Set<String> _getIgnoredKeys(MethodInvocation node) {
    final ignoredKeys = <String>{};

    AstNode? current = node;
    while (current != null && current is! CompilationUnit) {
      current = current.parent;
    }

    if (current is CompilationUnit) {
      final lineInfo = current.lineInfo;
      final nodeStartLine = lineInfo.getLocation(node.offset).lineNumber;
      final nodeEndLine = lineInfo.getLocation(node.end).lineNumber;

      final source = current.declaredElement?.source.contents.data;
      if (source != null) {
        final lines = source.split('\n');

        final linesToCheck = [
          nodeStartLine - 1,
          nodeEndLine,
        ];

        for (final lineNumber in linesToCheck) {
          final lineIdx = lineNumber - 1;
          if (lineIdx >= 0 && lineIdx < lines.length) {
            final line = lines[lineIdx];
            final match = RegExp(r'//\s*ignore_keys:\s*(.+)').firstMatch(line);
            if (match != null) {
              final keysString = match.group(1)!;
              final keys = keysString
                  .split(',')
                  .map((key) => key.trim())
                  .where((key) => key.isNotEmpty);
              ignoredKeys.addAll(keys);
            }
          }
        }
      }
    }

    return ignoredKeys;
  }
}

class _VariableVisitor extends RecursiveAstVisitor<void> {
  final Set<String> variables;
  final Set<String> constantHookNames;
  final Set<String> localVariables = <String>{};
  final Set<String> globalIdentifiers = <String>{};

  _VariableVisitor(this.variables, this.constantHookNames);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    localVariables.add(node.name.lexeme);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    localVariables.add(node.name!.lexeme);
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    if (node.exceptionParameter != null) {
      localVariables.add(node.exceptionParameter!.name.lexeme);
    }
    if (node.stackTraceParameter != null) {
      localVariables.add(node.stackTraceParameter!.name.lexeme);
    }
    super.visitCatchClause(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    localVariables.add(node.name.lexeme);
    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;

    // Skip if this is a method name in a method invocation
    if (node.parent is MethodInvocation &&
        (node.parent as MethodInvocation).methodName == node) {
      return;
    }

    // Skip if this is an index in an index expression
    if (node.parent is IndexExpression &&
        (node.parent as IndexExpression).index == node) {
      return;
    }

    // Skip if this is a property name in a property access
    if (node.parent is PropertyAccess &&
        (node.parent as PropertyAccess).propertyName == node) {
      return;
    }

    // Skip if this is an identifier in a prefixed identifier
    if (node.parent is PrefixedIdentifier &&
        (node.parent as PrefixedIdentifier).identifier == node) {
      return;
    }

    // Skip if this is a type name (used as a prefix for static members)
    if (node.parent is PrefixedIdentifier &&
        (node.parent as PrefixedIdentifier).prefix == node) {
      // This identifier is used as a type prefix - always skip it
      return;
    }

    // Skip if this is a type name in a named type (e.g., Duration in "const Duration()")
    if (node.parent is NamedType) {
      return;
    }

    // Skip if this is a named parameter label (e.g., "seconds" in "Duration(seconds: 1)")
    if (node.parent is Label) {
      return;
    }

    // Skip if this is a constructor name in an instance creation
    if (node.parent is ConstructorName) {
      return;
    }

    // Skip if this is a local variable (declared within the callback)
    if (localVariables.contains(name)) {
      return;
    }

    variables.add(name);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // For expressions like streamController.sink, we need to track streamController
    final target = node.target;
    if (target is SimpleIdentifier && !localVariables.contains(target.name)) {
      variables.add(target.name);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // For expressions like streamController.sink, we need to track streamController
    final prefix = node.prefix;
    if (!localVariables.contains(prefix.name)) {
      variables.add(prefix.name);
    }
    super.visitPrefixedIdentifier(node);
  }
}
