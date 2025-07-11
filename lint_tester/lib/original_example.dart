// Original example from user
import 'dart:async';

class Unit {
  const Unit();
}

const unit = Unit();

// Mock hooks
void useEffect(dynamic Function()? callback, List<dynamic> dependencies) {}
StreamController<T> useStreamController<T>() => StreamController<T>();
StreamSink<Unit> useDelayedAutoHide({
  required ValueNotifier<bool> visible,
  required bool isPlaying,
}) =>
    StreamController<Unit>().sink;
dynamic useContext() => null;
dynamic useStreamController2<T>() => StreamController<T>();

class ValueNotifier<T> {
  T value;
  ValueNotifier(this.value);
}

class MediaQuery {
  static bool accessibleNavigationOf(dynamic context) => false;
}

// Extension for testing
extension StreamExtensions<T> on Stream<T> {
  Stream<T> debounceTime(Duration duration) => this;
}

// Original code from user
StreamSink<Unit> useDelayedAutoHide2({
  required ValueNotifier<bool> visible,
  required bool isPlaying,
}) {
  final context = useContext();
  final accessibleNavigation = MediaQuery.accessibleNavigationOf(context);
  final streamController = useStreamController<Unit>();
  useEffect(
    () {
      if (visible.value) {
        streamController.sink.add(unit);
      }
      return null;
    },
    [visible.value], // ERROR: Missing streamController dependency
  );
  useEffect(
    () {
      final subscription = streamController.stream
          .debounceTime(
        const Duration(seconds: 3),
      )
          .listen(
        (_) {
          if (!accessibleNavigation && isPlaying) {
            visible.value = false;
          }
        },
      );
      streamController.sink.add(unit);
      return () => subscription.cancel();
    },
    [
      accessibleNavigation,
      isPlaying,
      visible.value
    ], // ERROR: Missing streamController dependency
  );
  return streamController.sink;
}
