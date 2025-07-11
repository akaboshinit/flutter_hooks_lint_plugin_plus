// Test for useStreamController hook dependency checking
import 'dart:async';

void useEffect(dynamic Function()? callback, List<dynamic> dependencies) {}
StreamController<T> useStreamController<T>() => StreamController<T>();

class Unit {
  const Unit();
}

const unit = Unit();

class StreamControllerTestWidget {
  void build() {
    final streamController = useStreamController<Unit>();
    final visible = ValueNotifier(true);
    final isPlaying = true;

    // Test 1: Missing streamController dependency when using sink
    // Expected: Hook deps: Missing: streamController, unit
    // expect_lint: hooks_exhaustive_deps
    useEffect(
      () {
        if (visible.value) {
          streamController.sink.add(unit);
        }
      },
      [visible.value], // Missing: streamController, unit
    );
    // Test 2: Correct dependency with streamController
    // Expected: Hook deps: Missing: unit
    // expect_lint: hooks_exhaustive_deps
    useEffect(
      () {
        streamController.sink.add(unit);
      },
      [streamController], // Missing: unit (streamController is included)
    );

    // Test 3: Using stream property
    // Expected: Hook deps: Missing: streamController
    // expect_lint: hooks_exhaustive_deps
    useEffect(
      () {
        final subscription = streamController.stream
            .debounceTime(const Duration(seconds: 3))
            .listen((_) {
          visible.value = false;
        });
        return () => subscription.cancel();
      },
      [visible.value], // Missing: streamController
    );

    // Test 4: Correct with both dependencies
    // Expected: No errors (all dependencies included)
    useEffect(
      () {
        final subscription = streamController.stream.listen((_) {
          if (isPlaying) {
            visible.value = false;
          }
        });
        return () => subscription.cancel();
      },
      [streamController, isPlaying, visible.value], // All dependencies included
    );

    // Test 5: Using multiple properties
    // Expected: Hook deps: Missing: streamController, unit
    // expect_lint: hooks_exhaustive_deps
    useEffect(
      () {
        streamController.sink.add(unit);
        streamController.stream.listen((_) {});
        streamController.close();
      },
      [], // Missing: streamController, unit
    );

    // Test 6: With ignore_keys comment
    // Expected: Hook deps: Missing: unit (streamController is ignored)
    // ignore_keys: streamController
    // expect_lint: hooks_exhaustive_deps
    useEffect(
      () {
        streamController.sink.add(unit);
      },
      [], // Missing: unit only (streamController is ignored)
    );
  }
}

// Extension for testing
extension StreamExtensions<T> on Stream<T> {
  Stream<T> debounceTime(Duration duration) => this;
}

class ValueNotifier<T> {
  T value;
  ValueNotifier(this.value);
}
