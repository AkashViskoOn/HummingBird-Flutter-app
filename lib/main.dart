import 'dart:async';

import 'package:animations/animations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:humming_bird/components/Models/custom_contacts_model.dart';
import 'package:humming_bird/components/Models/media_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/common/connectivity_banner.dart';
import 'package:humming_bird/components/loading/app_skeleton.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_customization_controller.dart';
import 'package:humming_bird/controllers/reminder_controller.dart';
import 'package:humming_bird/controllers/settings_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/main_humming_screen.dart';
import 'package:humming_bird/pages/onboarding/onboarding_screen.dart';
import 'package:humming_bird/services/background_service.dart';
import 'package:humming_bird/services/connectivity_service.dart';
import 'package:humming_bird/services/offline_queue_service.dart';
import 'package:humming_bird/services/retry_queue_service.dart';
import 'package:humming_bird/theme/app_theme.dart';
import 'components/Models/room_messages_model.dart';
import 'components/Models/rooms_model.dart';
import 'controllers/user_controller.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future _firebaseBackgroundMessaging(RemoteMessage message) async {}

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        debugPrint(details.toString());
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (kDebugMode) {
        debugPrint('Platform error: $error\n$stack');
      }
      return true;
    };

    try {
      BackgroundService().initializeBackgroundService();
    } catch (_) {}
    try {
      await Hive.initFlutter();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Hive init error: $e');
      }
    }
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessaging);
      }
    } catch (_) {}
    try {
      Hive.registerAdapter(UserAdapter());
      Hive.registerAdapter(CustomContactsModelAdapter());
      Hive.registerAdapter(RoomsAdapter());
      Hive.registerAdapter(MessagesAdapter());
      Hive.registerAdapter(MediaModelAdapter());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Hive adapter registration error: $e');
      }
    }
    try {
      await LocalDatabase.openLocalDb();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Local DB open error: $e');
      }
    }
    try {
      await GetStorage.init();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GetStorage init error: $e');
      }
    }
    try {
      Get.put(UserController());
    } catch (_) {}
    try {
      Get.put(BirdController());
    } catch (_) {}
    try {
      Get.put(AppSettingsController());
    } catch (_) {}
    try {
      Get.put(ConnectivityService());
    } catch (_) {}
    try {
      Get.put(RetryQueueService());
    } catch (_) {}
    try {
      Get.put(OfflineQueueService());
    } catch (_) {}
    try {
      Get.put(ChatCustomizationController());
    } catch (_) {}
    try {
      final reminderController = Get.put(ReminderController());
      unawaited(reminderController.respawnActiveReminders());
    } catch (_) {}
    try {
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      var initialNotification = await flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();
      if (initialNotification?.didNotificationLaunchApp == true) {
        Future.delayed(const Duration(seconds: 1), () {});
      }
    } catch (_) {}

    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('Unhandled error: $error\n$stack');
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _shellAnim;

  @override
  void initState() {
    super.initState();
    _shellAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
    );
    _shellAnim.forward();
  }

  @override
  void dispose() {
    _shellAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      LocalDatabase.closeLocalDb();
    }
  }

  UserController get userController => Get.find<UserController>();
  BirdController get birdController => Get.find<BirdController>();
  AppSettingsController get settingsController =>
      Get.find<AppSettingsController>();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      useInheritedMediaQuery: true,
      builder: (_, __) {
        // Read once. This used to be called twice for the same decision.
        final isLoggedIn = birdController.checkLogin();

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Humming Bird',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settingsController.themeMode.value,
          smartManagement: SmartManagement.keepFactory,
          defaultTransition: Transition.rightToLeftWithFade,
          transitionDuration: const Duration(milliseconds: 300),
          builder: (context, widget) {
            // NOTE: do NOT call CallController.setOverlayContext() here — this
            // builder context sits ABOVE the Navigator and has no Overlay
            // ancestor, so Overlay.of() would throw "No Overlay widget found".
            // The overlay context is set from the call screens instead.

            // Accessibility text scaling is honoured, but clamped. The app uses
            // many fixed-height rows and toolbars (and screen_util's .sp), so
            // an uncapped 2.0+ system scale overflows and clips them. Clamping
            // keeps text readable for low-vision users without breaking layout.
            return MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.3,
              child: Stack(
                children: [
                  widget ?? const SizedBox.shrink(),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(child: ConnectivityBanner()),
                  ),
                ],
              ),
            );
          },
          home: AppInitGate(
            homeScreen: isLoggedIn,
            child: FadeThroughTransition(
              animation: _shellAnim,
              secondaryAnimation: kAlwaysDismissedAnimation,
              fillColor: Colors.transparent,
              child: isLoggedIn
                  ? const MainHummingScreen()
                  : const OnboardingScreen(),
            ),
          ),
        );
      },
      // No `child:` here on purpose — the builder above ignores it, so passing
      // one only built a second, permanently unmounted copy of the home tree.
    );
  }
}
