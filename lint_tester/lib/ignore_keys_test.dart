// Mock functions for testing
void useEffect(void Function() callback, List<dynamic> dependencies) {}
Map<String, dynamic> useState(dynamic initial) => {'value': initial};
void print(dynamic object) {}

class IgnoreKeysTestWidget {
  void build() {
    final variable1 = useState(0);
    final variable2 = useState('');
    final variable3 = useState(false);

    // ignore_keys: variable1
    useEffect(() {
      print(variable1['value']);
      print(variable2['value']);
    }, [variable2['value']]);

    // ignore_keys: variable1
    useEffect(() {
      print(variable1['value']);
    }, []);

    useEffect(() {}, []);

    // ignore_keys: variable1, variable2, variable3
    useEffect(() {
      print(variable2['value']);
      print(variable3['value']);
    }, [variable1['value']]);
  }
}
