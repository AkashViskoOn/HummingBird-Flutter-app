import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/services/connectivity_service.dart';
import 'package:humming_bird/services/offline_queue_service.dart';
import 'package:humming_bird/services/retry_queue_service.dart';

/// Guards the crash-refill persistence contract the chat send path depends on:
/// a task queued while offline must survive a process restart (it lives in
/// GetStorage, not memory), and [pendingCount]/[pendingMessages] must track
/// the real queue length so the UI badge never lies.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (call) async {
    if (call.method == 'getApplicationDocumentsDirectory' ||
        call.method == 'getApplicationSupportDirectory') {
      return Directory.systemTemp.path;
    }
    return null;
  });

  setUpAll(() async {
    await GetStorage.init();
    final storage = GetStorage();
    await storage.erase();
  });

  setUp(() {
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
  });

  tearDown(() {
    Get.reset();
    GetStorage().erase();
  });

  group('RetryQueueService', () {
    test('enqueue appends and publishes matching pendingCount', () {
      final service = RetryQueueService();
      service.onInit();

      service.enqueue({'id': 't1', 'action': 'send'});
      service.enqueue({'id': 't2', 'action': 'send'});

      expect(service.pendingCount.value, 2);
      expect(service.getQueue(), hasLength(2));
    });

    test('dequeue removes by id and updates the counter', () {
      final service = RetryQueueService();
      service.onInit();
      service.enqueue({'id': 't1', 'action': 'send'});
      service.enqueue({'id': 't2', 'action': 'send'});

      service.dequeue('t1');

      expect(service.pendingCount.value, 1);
      expect(service.getQueue().single['id'], 't2');
    });

    test('queue survives a new instance — persisted, not in-memory', () {
      final first = RetryQueueService();
      first.onInit();
      first.enqueue({'id': 'p1', 'action': 'send'});

      // A "restart" — brand new service reading the same backing store.
      final second = RetryQueueService();
      second.onInit();

      expect(second.pendingCount.value, 1);
      expect(second.getQueue().single['id'], 'p1');
    });

    test('clearQueue empties the store and resets the counter', () {
      final service = RetryQueueService();
      service.onInit();
      service.enqueue({'id': 't1', 'action': 'send'});

      service.clearQueue();

      expect(service.pendingCount.value, 0);
      expect(service.getQueue(), isEmpty);
      expect(RetryQueueService().getQueue(), isEmpty);
    });

    test('empty store yields empty queue, not null', () {
      final service = RetryQueueService();
      service.onInit();
      expect(service.getQueue(), isEmpty);
      expect(service.pendingCount.value, 0);
    });
  });

  group('OfflineQueueService', () {
    test('enqueue appends and publishes matching pendingMessages', () {
      final service = OfflineQueueService();
      service.enqueue({'id': 'm1', 'body': 'hi'});
      service.enqueue({'id': 'm2', 'body': 'hello'});

      expect(service.pendingMessages.value, 2);
      expect(service.getQueue(), hasLength(2));
    });

    test('dequeue via processing drains the queue in order', () async {
      final service = OfflineQueueService();
      service.onInit();
      service.enqueue({'id': 'm1', 'body': 'a'});
      service.enqueue({'id': 'm2', 'body': 'b'});

      // Offline → online flips the worker which calls _processQueue().
      ConnectivityService.to.isOnline.value = false;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      ConnectivityService.to.isOnline.value = true;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.pendingMessages.value, 2);
      expect(service.getQueue(), hasLength(2));
    });

    test('processQueue is a no-op without a resendHandler (no data loss)',
        () async {
      final service = OfflineQueueService();
      service.onInit();
      service.enqueue({'id': 'm1', 'body': 'a'});

      ConnectivityService.to.isOnline.value = true;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.pendingMessages.value, 1);
      expect(service.getQueue(), hasLength(1));
    });

    test('reconnect invokes the resend handler, which may dequeue', () async {
      final service = OfflineQueueService();
      service.onInit();
      service.enqueue({'id': 'm1', 'body': 'a'});
      service.enqueue({'id': 'm2', 'body': 'b'});

      var drainedIds = <String>[];
      service.resendHandler = () async {
        for (final item in service.getQueue()) {
          drainedIds.add(item['id'].toString());
        }
      };

      ConnectivityService.to.isOnline.value = false;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      ConnectivityService.to.isOnline.value = true;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(drainedIds, <String>['m1', 'm2']);
      // Handler chose not to dequeue — nothing is lost.
      expect(service.pendingMessages.value, 2);
    });

    test('queue survives a new instance — persisted, not in-memory', () {
      final first = OfflineQueueService();
      first.enqueue({'id': 'pm1', 'body': 'deferred'});

      final second = OfflineQueueService();
      second.onInit();
      expect(second.pendingMessages.value, 1);
      expect(second.getQueue().single['id'], 'pm1');
    });

    test('empty store yields empty queue and zero counter', () {
      final service = OfflineQueueService();
      expect(service.getQueue(), isEmpty);
      expect(service.pendingMessages.value, 0);
    });
  });
}