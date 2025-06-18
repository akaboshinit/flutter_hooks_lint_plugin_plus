import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/hooks_exhaustive_deps.dart';
import 'src/rules/hooks_no_nested_usage.dart';

PluginBase createPlugin() => _FlutterHooksLintPlugin();

class _FlutterHooksLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        HooksExhaustiveDeps(),
        HooksNoNestedUsage(),
      ];
}