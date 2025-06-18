// Mock hooks functions for testing
// ignore_for_file: dead_code

T useState<T>(T initialValue) => initialValue;
void useEffect(void Function() effect, [List<dynamic>? deps]) {}

void testHooksInIfStatement() {
  final condition = true;

  if (condition) {
    // expect_lint: hooks_no_nested_usage
    final state = useState('nested in if');
  }
}

void testHooksInForLoop() {
  for (int i = 0; i < 5; i++) {
    // expect_lint: hooks_no_nested_usage
    final counter = useState(i);
  }
}

void testHooksInWhileLoop() {
  final condition = true;

  while (condition) {
    // expect_lint: hooks_no_nested_usage
    final state = useState('while loop');
    break;
  }
}

void testHooksInTryCatch() {
  try {
    // expect_lint: hooks_no_nested_usage
    final state = useState('in try block');
  } catch (e) {
    // Error handling
  }
}

void testHooksInConditionalExpression() {
  final condition = true;

  // expect_lint: hooks_no_nested_usage
  final result = condition ? useState('true case') : useState('false case');
}

void testHooksInSwitchStatement() {
  final value = 1;

  switch (value) {
    case 1:
      // expect_lint: hooks_no_nested_usage
      final state = useState('case 1');
      break;
    default:
      break;
  }
}

void testCorrectHookUsage() {
  // Correct usage - all hooks at top level (no lint expected)
  final state1 = useState('state1');
  final state2 = useState('state2');
  // Using hook results in conditions is OK
  final condition = state1 == 'active';
  if (condition) {
    print('State is active: $state2');
  }
}
