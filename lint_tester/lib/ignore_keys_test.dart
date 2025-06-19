// Mock functions for testing
void useEffect(void Function() callback, List<dynamic> dependencies) {}
Map<String, dynamic> useState(dynamic initial) => {'value': initial};
void print(dynamic object) {}

class IgnoreKeysTestWidget {
  void build() {
    final variable1 = useState(0);
    final variable2 = useState('');
    final variable3 = useState(false);

    // Test case 1: ignore_keys comment on the same line
    useEffect(() {
      print(variable1['value']);
      print(variable2['value']);
    }, [variable3['value']]); // ignore_keys: variable1, variable2

    // Test case 2: ignore_keys comment on the previous line
    // ignore_keys: variable1
    useEffect(() {
      print(variable1['value']);
    }, []);

    // Test case 3: ignore_keys with mixed spaces
    // ignore_keys: variable2, variable3
    useEffect(() {
      print(variable2['value']);
      print(variable3['value']);
    }, [variable1['value']]);
  }
}
