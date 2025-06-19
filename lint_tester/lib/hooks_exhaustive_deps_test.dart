// Mock hooks functions for testing
T useState<T>(T initialValue) => initialValue;
void useEffect(void Function() effect, [List<dynamic>? deps]) {}

// Mock constant hooks
T useRef<T>(T initialValue) => initialValue;
bool useIsMounted() => true;
dynamic useFocusNode() => null;
dynamic useContext() => null;
dynamic useConstantValue() => null;

// Mock non-constant hook (not in constant_hooks config)
dynamic useCustomHook() => null;

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

void testConstantHooks() {
  final variable1 = useState('test1');
  final ref = useRef('test_ref');
  final isMounted = useIsMounted();
  final focusNode = useFocusNode();
  final context = useContext();
  final constantValue = useConstantValue();
  final customValue = useCustomHook(); // Not a constant hook

  // Correct usage - constant hooks should not be in dependencies (no lint expected)
  useEffect(() {
    print(variable1);
    print(ref);
    print(isMounted);
    print(focusNode);
    print(context);
  }, [variable1]);

  // expect_lint: hooks_exhaustive_deps
  useEffect(() {
    print(variable1);
    print(ref);
  }, [variable1, ref]); // ref is a constant hook and should not be in deps

  // Correct usage - constant hooks only (no lint expected)
  useEffect(() {
    print(ref);
    print(isMounted);
  }, []); // Should not require constant hooks in deps

  // expect_lint: hooks_exhaustive_deps
  useEffect(() {
    print(customValue); // customValue from useCustomHook is not a constant hook
  }, []); // Missing dependency: customValue should be in deps
}
