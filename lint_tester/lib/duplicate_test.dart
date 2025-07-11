// Test for duplicate reports
void useEffect(void Function() callback, List<dynamic> dependencies) {}
Map<String, dynamic> useState(dynamic initial) => {'value': initial};
void print(dynamic object) {}

void testDuplicateReports() {
  final state1 = useState(0);
  final state2 = useState('test');

  // This should generate exactly one lint error
  useEffect(() {
    print(state1);
    print(state2);
  }, [state1]); // Missing: state2
}
