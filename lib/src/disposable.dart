import 'dart:async';

/// Interface for objects that can be disposed.
///
/// Implementing classes should clean up resources in the [dispose] method.
/// The disposal process should be idempotent and safe to call multiple times.
///
/// **Contract:**
/// - [dispose] must be idempotent (safe to call multiple times)
/// - After disposal, the object should be in a clean, unusable state
/// - Resources should be properly released to prevent memory leaks
///
/// **Example:**
/// ```dart
/// class MyResource implements Disposable {
///   Timer? _timer;
///
///   MyResource() {
///     _timer = Timer.periodic(Duration(seconds: 1), (_) {});
///   }
///
///   @override
///   Future<void> dispose() async {
///     _timer?.cancel();
///     _timer = null;
///   }
/// }
/// ```
abstract interface class Disposable {
  /// Dispose this object and clean up its resources.
  ///
  /// This method should be idempotent - calling it multiple times
  /// should be safe and not cause errors. After disposal, the object
  /// should not be used for any operations.
  ///
  /// **Returns:**
  /// A [Future] that completes when cleanup is finished, or completes
  /// synchronously if no async operations are needed.
  ///
  /// **Implementation Guidelines:**
  /// - Always check if already disposed before doing work
  /// - Clean up in reverse order of initialization when possible
  /// - Handle exceptions gracefully to prevent partial cleanup
  /// - Set disposed flag to prevent further use
  FutureOr<void> dispose();
}

/// A disposable object that supports chained disposal operations.
///
/// [ChainedDisposable] extends the basic [Disposable] interface to provide
/// a mechanism for chaining multiple disposal operations together. The key
/// design principle is to avoid the complexity of directly overriding [dispose]
/// while maintaining idempotency. Instead, the framework handles the disposal
/// logic internally and calls [onDispose] for custom cleanup operations.
///
/// **Key Features:**
/// - Maintains idempotent disposal contract automatically
/// - Provides [onDispose] hook for custom cleanup logic
/// - Avoids the complexity of overriding [dispose] directly
/// - Supports both synchronous and asynchronous disposal operations
///
/// **Design Philosophy:**
/// The [dispose] method needs to maintain idempotency, which makes direct
/// overriding complex and error-prone. Instead, the framework handles the
/// disposal logic internally with the following general flow:
/// 1. Check if already disposed (idempotency)
/// 2. Set disposed flag
/// 3. Call [onDispose] for custom cleanup
/// 4. Perform additional cleanup as needed
/// This allows subclasses to focus on their specific cleanup logic without
/// worrying about idempotency concerns.
///
/// **Usage Pattern:**
/// ```dart
/// class MyChainedResource implements ChainedDisposable {
///   final List<Disposable> _resources = [];
///
///   void addResource(Disposable resource) {
///     _resources.add(resource);
///   }
///
///   @override
///   Future<void> onDispose() async {
///     // Custom cleanup logic - no need to worry about idempotency
///     for (final resource in _resources.reversed) {
///       await resource.dispose();
///     }
///     _resources.clear();
///     print('Chained resource disposed');
///   }
/// }
/// ```
///
/// **Implementation Guidelines:**
/// - Override [onDispose] to add custom cleanup logic
/// - Don't override [dispose] directly - let the framework handle it
/// - Focus on your specific cleanup requirements in [onDispose]
/// - The framework ensures idempotency automatically
abstract interface class ChainedDisposable implements Disposable {
  /// Called during the disposal process to perform custom cleanup.
  ///
  /// This method is automatically invoked by the framework's disposal mechanism
  /// as part of the disposal flow. It's called after the disposed flag is set
  /// but before attached resources are disposed and pending values are cleared.
  /// This provides a clean way to add custom cleanup logic without worrying about
  /// idempotency concerns, as the framework handles the complexity of ensuring
  /// [dispose] is idempotent.
  ///
  /// **Key Benefits:**
  /// - No need to worry about idempotency - the framework handles it
  /// - Can be safely overridden multiple times in inheritance chains
  /// - Focus purely on cleanup logic without disposal state management
  /// - Automatic integration with the disposal framework
  ///
  /// **Execution Flow:**
  /// The disposal process follows this general pattern:
  /// ```dart
  /// @override
  /// @mustCallSuper
  /// void dispose() {
  ///   if (isDisposed) return;        // 1. Idempotency check
  ///   isDisposed = true;             // 2. Set disposed flag
  ///   onDispose();                   // 3. Custom cleanup (this method)
  ///   ...                            // 4. Additional cleanup as needed
  /// }
  /// ```
  ///
  /// **Implementation Notes:**
  /// - This method is optional and has a default empty implementation
  /// - Can be either synchronous or asynchronous
  /// - Called automatically by the framework - don't call directly
  /// - Exceptions should be handled gracefully to not break the disposal chain
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// Future<void> onDispose() async {
  ///   // Focus on cleanup logic only - no idempotency concerns
  ///   await _cleanupCustomResources();
  ///   _notifyDisposalListeners();
  ///   _closeConnections();
  /// }
  /// ```
  FutureOr<void> onDispose() {}
}

/// A function that performs cleanup operations.
///
/// Can be either synchronous (returning `void`) or asynchronous
/// (returning `Future<void>`). This flexibility allows disposers to
/// handle both simple cleanup tasks and complex async operations.
///
/// **Example:**
/// ```dart
/// // Synchronous disposer
/// Disposer syncDisposer = () => print('cleaned up');
///
/// // Asynchronous disposer
/// Disposer asyncDisposer = () async {
///   await someAsyncCleanup();
/// };
/// ```
typedef Disposer = FutureOr<void> Function();
