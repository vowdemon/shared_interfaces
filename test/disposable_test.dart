import 'dart:async';
import 'package:shared_interfaces/shared_interfaces.dart';
import 'package:test/test.dart';

void main() {
  group('Disposable Interface', () {
    test('basic disposal works', () async {
      final resource = TestResource();
      expect(resource.isDisposed, false);

      await resource.dispose();
      expect(resource.isDisposed, true);
    });

    test('disposal is idempotent', () async {
      final resource = TestResource();

      await resource.dispose();
      expect(resource.disposeCount, 1);

      await resource.dispose();
      expect(resource.disposeCount, 1); // Should not increment
    });
  });

  group('ChainedDisposable Interface', () {
    test('chained disposal works', () async {
      final chainedResource = TestChainedResource();
      expect(chainedResource.isDisposed, false);

      await chainedResource.dispose();
      expect(chainedResource.isDisposed, true);
      expect(chainedResource.onDisposeCalled, true);
    });

    test('chained disposal is idempotent', () async {
      final chainedResource = TestChainedResource();

      await chainedResource.dispose();
      expect(chainedResource.onDisposeCallCount, 1);

      await chainedResource.dispose();
      expect(chainedResource.onDisposeCallCount, 1); // Should not increment
    });
  });

  group('Disposer typedef', () {
    test('synchronous disposer works', () {
      bool cleanedUp = false;
      FutureOr<void> syncDisposer() {
        cleanedUp = true;
      }

      syncDisposer();
      expect(cleanedUp, true);
    });

    test('asynchronous disposer works', () async {
      bool cleanedUp = false;
      FutureOr<void> asyncDisposer() async {
        await Future.delayed(Duration(milliseconds: 10));
        cleanedUp = true;
      }

      await asyncDisposer();
      expect(cleanedUp, true);
    });
  });
}

// Test implementations

class TestResource implements Disposable {
  bool _isDisposed = false;
  int _disposeCount = 0;

  bool get isDisposed => _isDisposed;
  int get disposeCount => _disposeCount;

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _disposeCount++;
  }
}

class TestChainedResource implements ChainedDisposable {
  bool _isDisposed = false;
  bool _onDisposeCalled = false;
  int _onDisposeCallCount = 0;

  bool get isDisposed => _isDisposed;
  bool get onDisposeCalled => _onDisposeCalled;
  int get onDisposeCallCount => _onDisposeCallCount;

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await onDispose();
  }

  @override
  Future<void> onDispose() async {
    _onDisposeCalled = true;
    _onDisposeCallCount++;
  }
}
