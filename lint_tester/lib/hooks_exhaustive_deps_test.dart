// Mock hooks functions for testing
T useState<T>(T initialValue) => initialValue;
void useEffect(void Function() effect, [List<dynamic>? deps]) {}

void testMissingDependencies() {
  final variable1 = useState('test1');
  final variable2 = useState('test2');

  // expect_lint: hooks_exhaustive_deps
  useEffect(() {
    print(variable1);
    print(variable2); // variable2 is used but not in deps
  }, [variable1]);
}

void testUnnecessaryDependencies() {
  final variable1 = useState('test1');
  final variable2 = useState('test2');

  // expect_lint: hooks_exhaustive_deps
  useEffect(() {
    print(variable1); // only variable1 is used
  }, [variable1, variable2]); // variable2 is unnecessary
}

void testMixedIssues() {
  final variable1 = useState('test1');
  final variable2 = useState('test2');
  final variable3 = useState('test3');

  // expect_lint: hooks_exhaustive_deps
  useEffect(() {
    print(variable1);
    print(variable3); // variable3 is used but not in deps
  }, [variable1, variable2]); // variable2 is in deps but not used
}

void testEmptyDependencies() {
  final variable1 = useState('test1');

  // expect_lint: hooks_exhaustive_deps
  useEffect(() {
    print(variable1); // variable1 is used but deps is empty
  }, []);
}

void testCorrectUsage() {
  final variable1 = useState('test1');
  final variable2 = useState('test2');

  // Correct usage - all dependencies match (no lint expected)
  useEffect(() {
    print(variable1);
    print(variable2);
  }, [variable1, variable2]);

  // Correct usage - no dependencies needed (no lint expected)
  useEffect(() {
    print('static message');
  }, []);
}
