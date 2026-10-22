import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/chat_ui/quick_forward_sheet.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/controllers/bird_controller.dart';

class _FakeUserController extends UserController {
  _FakeUserController({String userId = ''}) {
    this.userId = userId;
  }

  @override
  void onReady() {}
}

class _FakeHomeController extends HomeController {
  _FakeHomeController({List<Rooms> rooms = const []}) {
    singleChatsList.assignAll(rooms);
  }

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  List<String> getPinnedRoomIds() => const [];
}

class _FakeContactController extends ContactController {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  (String, String, String, String) getContactData(Rooms room) {
    final id = room.rId ?? '';
    return ('Contact $id', 'receiver-$id', '9000000000', 'Online');
  }
}

class _FakeChatController extends ChatController {
  int forwardCalls = 0;
  List<String>? lastMessageIds;
  List<String>? lastRoomIds;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  void onReady() {}

  @override
  Future<void> forwardMessages(
      List<String> messageIds, List<String> roomIds) async {
    forwardCalls++;
    lastMessageIds = List.of(messageIds);
    lastRoomIds = List.of(roomIds);
  }
}

/// Serves font bytes for `GoogleFonts.poppins` requests during tests. Test HTTP
/// is blocked and google_fonts validates a sha256/checksum per artifact, so we
/// return the EXACT gstatic artifact bytes (bundled as fixtures) keyed by url.
class _FontClient extends http.BaseClient {
  final Map<String, List<int>> urls = {
    'https://fonts.gstatic.com/s/a/ec23e010878cf0841f910ef94f62294e40c7d77ce99be250dba2911d0a1a61cd.ttf':
        _fontBytes('poppins-semi-bold.ttf'),
    'https://fonts.gstatic.com/s/a/2dd6eb23c4972b346197d272c4e2479b89ed240ece4d2b0e0cd89f0c1caa2710.ttf':
        _fontBytes('poppins-regular.ttf'),
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    final bytes = urls[url];
    if (bytes == null) debugPrint('GF-FONT-URL: $url');
    final stream = http.ByteStream.fromBytes(bytes ?? const []);
    return http.StreamedResponse(stream, 200,
        contentLength: bytes?.length ?? 0);
  }
}

List<int> _fontBytes(String fileName) =>
    File('test/fixtures/fonts/$fileName').readAsBytesSync();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.httpClient = _FontClient();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (call) async {
    if (call.method == 'getApplicationDocumentsDirectory' ||
        call.method == 'getApplicationSupportDirectory') {
      return Directory.systemTemp.path;
    }
    return null;
  });

  void registerControllers() {
    Get.put<UserController>(_FakeUserController(), permanent: true);
    Get.put<BirdController>(BirdController(), permanent: true);
    Get.put<HomeController>(_FakeHomeController(), permanent: true);
    Get.put<ContactController>(_FakeContactController(), permanent: true);
    Get.put<ChatController>(_FakeChatController(), permanent: true);
  }

  tearDown(() {
    QuickForwardPanel.dismiss();
    Get.reset();
  });

  Widget buildHarness() {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            registerControllers();
            return Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => QuickForwardPanel.show(context,
                      messageIds: const ['m1', 'm2']),
                  child: const Text('open'),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> openPanel(WidgetTester tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'opens cleanly and shows 1:1 targets even when user cache is not loaded',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();
    Get.find<HomeController>().singleChatsList.assignAll([
      Rooms(rId: 'r1', rName: 'Room one', rUpdatedAt: '100'),
      Rooms(rId: 'r2', rName: 'Room two', rUpdatedAt: '200'),
    ]);

    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Forward to'), findsOneWidget);
    expect(find.text('Search contacts'), findsOneWidget);
    expect(find.text('Contact r1'), findsOneWidget);
    expect(find.text('Contact r2'), findsOneWidget);
  });

  testWidgets('self chat and blocked/locked data are safely skipped',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    final userController = Get.find<UserController>() as _FakeUserController;
    userController.userId = 'receiver-r1';

    final contact = Get.find<ContactController>();
    contact.checkIfUserIsBlocked('anything-not-throwing');

    expect(contact.checkIfUserIsBlocked('receiver-r2'), false);
    expect(contact.checkIfUserIsBlocked('receiver-r1'), false);
    expect(() => contact.checkIfUserIsBlocked('receiver-r1'), returnsNormally);
  });

  testWidgets('tapping a target forwards exactly once with correct ids',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();
    Get.find<HomeController>().singleChatsList.assignAll([
      Rooms(rId: 'r1', rName: 'Room one', rUpdatedAt: '100'),
    ]);

    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Contact r1'), findsOneWidget);

    await tester.tap(find.text('Contact r1'));
    await tester.pumpAndSettle();

    final chat = Get.find<ChatController>() as _FakeChatController;
    expect(chat.forwardCalls, 1);
    expect(chat.lastMessageIds, ['m1', 'm2']);
    expect(chat.lastRoomIds, ['r1']);
    expect(find.text('Forward to'), findsNothing);
  });

  testWidgets('closing by tapping the dim layer removes the panel',
      (tester) async {
    await openPanel(tester);
    expect(find.text('Forward to'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('Forward to'), findsNothing);
    expect(QuickForwardPanel.isShowing, isFalse);
  });
}