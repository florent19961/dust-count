import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Retries a Firestore [Future] up to [maxRetries] times on permission-denied.
///
/// Useful right after joining a household, where Firestore security rules
/// may race against the membership write.
Future<T> retryOnPermissionDenied<T>(
  Future<T> Function() fn, {
  int maxRetries = 2,
}) async {
  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' && attempt < maxRetries) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }
      rethrow;
    }
  }
  throw StateError('Unreachable');
}

/// Wraps a Firestore [Stream] factory with retry on permission-denied.
///
/// If the stream emits a permission-denied error within the first
/// [maxRetries] attempts, it cancels the subscription and retries after 1 s.
Stream<T> retryStreamOnPermissionDenied<T>(
  Stream<T> Function() streamFactory, {
  int maxRetries = 2,
}) {
  int retries = 0;
  late StreamController<T> controller;
  StreamSubscription<T>? subscription;

  void listen() {
    subscription = streamFactory().listen(
      controller.add,
      onError: (Object error) {
        if (error is FirebaseException &&
            error.code == 'permission-denied' &&
            retries < maxRetries) {
          retries++;
          subscription?.cancel();
          Future.delayed(const Duration(seconds: 1), listen);
        } else {
          controller.addError(error);
        }
      },
      onDone: controller.close,
    );
  }

  controller = StreamController<T>(
    onListen: listen,
    onCancel: () => subscription?.cancel(),
  );

  return controller.stream;
}
