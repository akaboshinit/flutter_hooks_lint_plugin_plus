// Test for edge cases and unusual patterns
void useEffect(void Function() callback, List<dynamic> dependencies) {}
Map<String, dynamic> useState(dynamic initial) => {'value': initial};
void print(dynamic object) {}

// Mock classes and functions
class MyClass {
  static void staticMethod() {}
  static int staticValue = 42;
  void instanceMethod() {}
}

enum MyEnum { value1, value2, value3 }

void globalFunction() {}
int globalVariable = 10;

class EdgeCasesWidget {
  void build() {
    final state1 = useState(0);
    final state2 = useState('');
    final myObject = MyClass();
    
    // Test 1: Enum values
    useEffect(() {
      print(MyEnum.value1);
      print(MyEnum.value2.name);
    }, []);
    
    // Test 2: Static class members
    // ignore_keys: MyClass
    useEffect(() {
      MyClass.staticMethod();
      print(MyClass.staticValue);
    }, []);
    
    // Test 3: Method references (not invocations)
    // ignore_keys: myObject
    useEffect(() {
      final method = myObject.instanceMethod;
      print(method);
    }, []);
    
    // Test 4: Complex property access chains
    useEffect(() {
      print(state1['value'].toString());
      print(state1['value']?.hashCode);
    }, [state1]);
    
    // Test 5: Cascade notation
    useEffect(() {
      final list = <int>[]
        ..add(state1['value'])
        ..add(42);
      print(list);
    }, [state1]);
    
    // Test 6: Collection literals with expressions
    useEffect(() {
      final map = {
        'key': state1['value'],
        'global': globalVariable,
      };
      final list = [state1['value'], globalVariable];
      final set = {state1['value'], state2['value']};
    }, [state1, state2, globalVariable]);
    
    // Test 7: Type parameters and generics
    useEffect(() {
      final list = <String>[];
      final map = <String, int>{};
      list.add(state2['value']);
    }, [state2]);
    
    // Test 8: Extension methods
    useEffect(() {
      print('hello'.padLeft(10));
      print([1, 2, 3].map((e) => e * state1['value']));
    }, [state1]);
    
    // Test 9: Null-aware operators
    useEffect(() {
      print(state1['value'] ?? 0);
      print(state2['value']?.length);
      state1['value']?.toString();
    }, [state1, state2]);
    
    // Test 10: Anonymous functions with captures
    useEffect(() {
      final multiplier = state1['value'];
      final transform = (int x) => x * multiplier;
      print(transform(5));
    }, [state1]);
    
    // Test 11: Switch expressions (if supported)
    useEffect(() {
      final result = switch (state1['value']) {
        0 => 'zero',
        1 => 'one',
        _ => 'other',
      };
      print(result);
    }, [state1]);
    
    // Test 12: Pattern matching (if supported)
    useEffect(() {
      final obj = [1, 2, 3];
      if (obj case [var a, var b, ...]) {
        print(a + b + state1['value']);
      }
    }, [state1]);
    
    // Test 13: Record types (if supported)
    useEffect(() {
      final record = (x: state1['value'], y: state2['value']);
      print(record.x);
      print(record.y);
    }, [state1, state2]);
    
    // Test 14: Constructor tear-offs
    useEffect(() {
      final listConstructor = List<int>.filled;
      final result = listConstructor(state1['value'], 0);
    }, [state1]);
    
    // Test 15: Platform specific code
    useEffect(() {
      if (identical(0, 0.0)) {
        print(state1['value']);
      }
      print(DateTime.now().millisecondsSinceEpoch);
    }, [state1]);
  }
}