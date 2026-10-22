# Flutter App — Development Plan

## Quick Fixes (Immediate)

- **Fix Hive field collision** in `room_messages_model.dart`: `mSeenBy` (@HiveField 22) conflicts with `showTyping` (@HiveField 22). Assign unique indices: `mSeenBy` → 23, `mTimeStamp` → 24.
- **Fix filename with space**: `pages/chats/chat_screens/widgets/image_viewer _widget.dart` → `image_viewer_widget.dart`. Update all imports.
- **Fix typo in directory name**: `services/backgroung_*.dart` → `services/background_*.dart`, `api_error_haldler.dart` → `api_error_handler.dart`. Update all imports.
- **Fix case-sensitive import**: `sidebar_drawer_menu.dart` imports `Login_Screen/login.dart` but directory is `login_screen/`. Fix case.
- **Uncomment `deleteLocalDatabase()`** in `settings_controller.dart` line 92 so account deletion clears local data.
- **Remove or implement empty callbacks** in `user_profile_details.dart` (share/mute buttons).
- **Delete stub file**: `components/common/home_child_container.dart` (2 bytes, empty).

## Refactoring (Short-Term)

- **Centralize route table**: Move all `Get.to()` calls into a single router file to replace imperative navigation with named routes.
- **Standardize model approach**: Migrate hand-written `fromJson`/`toJson` to `json_serializable` (already using `build_runner` for Hive).
- **Extract hardcoded strings** into `res/app_strings.dart` for future i18n.
- **Extract encryption keys** from source into environment or config.
- **Remove redundant RoomMessages model** — it mirrors `Rooms` with a `messages` list instead of `rLastMessage`. Consolidate.

## Features & Improvements (Medium-Term)

- **Add server-side logout**: Invalidate JWT token on the backend when user logs out.
- **Implement background connectivity monitoring** in `background_service.dart` (currently commented out).
- **Add Firebase Analytics** or Sentry for crash/usage monitoring.
- **Make OpenAI API key configurable** at runtime (not just compile-time `--dart-define`).
- **Replace hardcoded Android storage path** (`storage/emulated/0`) with `path_provider`.
- **Support Flutter web** by making socket transport configurable (currently websocket-only).

## Architecture (Long-Term)

- **Add test coverage**: Only `widget_test.dart` exists. Add unit tests for controllers, services, and widget tests for key screens.
- **Add internationalization (i18n)**: Extract all strings into `.arb` files.
- **Consider moving from GetX to Riverpod/Bloc** for better testability and type safety (optional, high effort).
- **Add CI/CD**: GitHub Actions for `flutter analyze`, `flutter test`, and `flutter build` on PR.
