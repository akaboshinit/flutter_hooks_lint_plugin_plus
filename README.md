# Flutter Hooks Lint Plugin Plus

A custom_lint plugin for Flutter Hooks that provides lint rules for hook usage best practices.

This is a custom_lint version of the original [flutter_hooks_lint_plugin](https://github.com/mj-hd/flutter_hooks_lint_plugin) by mj-hd.

## Features

This plugin provides two main lint rules:

### 1. hooks_exhaustive_deps

Checks `useEffect` calls for correct key dependencies:
- Finds "build variables" in HookWidget
- Compares references of variables used in the effect with specified keys
- Reports errors if keys are missing or unnecessary

**Example:**
```dart
// ❌ Lint error: missing 'variable1', unnecessary 'variable2'
useEffect(() {
  print(variable1);
}, [variable2]);

// ✅ Correct
useEffect(() {
  print(variable1);
}, [variable1]);
```

### 2. hooks_no_nested_usage

Prevents using hooks inside control flow statements:
- Considers nested hooks a bad practice
- Ensures hooks are called in the same order every time

**Example:**
```dart
// ❌ Lint error: avoid nested hooks
if (flag) {
  final variable = useState('hello');
}

// ✅ Correct
final variable = useState('hello');
if (flag) {
  // Use the variable here
}
```

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dev_dependencies:
  custom_lint: ^0.5.0
  flutter_hooks_lint_plugin_plus: ^1.0.0
```

Then add the plugin to your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - hooks_exhaustive_deps
    - hooks_no_nested_usage
```

## Usage

1. Run `dart pub get` to install the package
2. Run `dart run custom_lint` to analyze your code
3. The plugin will report lint errors for incorrect hook usage

## Configuration

You can configure the rules in your `analysis_options.yaml`:

```yaml
custom_lint:
  rules:
    - hooks_exhaustive_deps: true
    - hooks_no_nested_usage: false  # Disable this rule
```

## Credits

This plugin is based on the original [flutter_hooks_lint_plugin](https://github.com/mj-hd/flutter_hooks_lint_plugin) by mj-hd, which was inspired by eslint-plugin-react-hooks.

## License

This project is licensed under the MIT License - see the LICENSE file for details.