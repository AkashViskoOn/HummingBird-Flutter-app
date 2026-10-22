import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/user_api.dart';
import 'package:humming_bird/common/views/common_otp_screen.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/login_screen/login.dart';
import 'package:humming_bird/res/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class AppSettingsController extends GetxController {
  TextEditingController oldNumberController = TextEditingController();
  TextEditingController newNumberController = TextEditingController();
  TextEditingController deleteAccountController = TextEditingController();
  TextEditingController deleteOtpController = TextEditingController();

  /// Persisted app theme. Defaults to [ThemeMode.system] so a first-run user
  /// whose phone is in dark mode gets a dark app instead of being flashed a
  /// light one; `setThemeMode` switches the whole app via
  /// `Get.changeThemeMode` (which rebuilds GetMaterialApp natively) and saves
  /// the choice so it survives restarts/force closes.
  static const String themeStorageKey = 'app_theme_mode';
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  BirdController birdController = Get.find();
  UserController userController = Get.find();

  @override
  void onInit() {
    super.onInit();
    // Only an explicit stored choice overrides the system default. Anything
    // else (missing, unrecognised, or the older two-value format) stays system.
    switch (userController.storage.read<String>(themeStorageKey)) {
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      case 'light':
        themeMode.value = ThemeMode.light;
        break;
      default:
        themeMode.value = ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == themeMode.value) return;
    themeMode.value = mode;
    userController.storage.write(
      themeStorageKey,
      switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      },
    );
    Get.changeThemeMode(mode);
  }

  void requestChangeNumber() async {
    if (oldNumberController.text.trim().isNotEmpty &&
        newNumberController.text.trim().isNotEmpty) {
      try {
        Map<String, dynamic> data = await UserApi()
            .requestAccountChanges(oldNumberController.text.trim(), false);

        if (data['status'] ?? false) {
          Get.to(() => CommonOTPScreen(
                phoneNumber: oldNumberController.text.trim(),
                newNumber: newNumberController.text.trim(),
                otp: data['otp']?.toString() ?? '',
                forDelete: false,
              ));
        } else {
          Utils.showGetSnackBar(
              data['message'] ?? 'Something went wrong, Try again later');
        }
      } catch (e) {
        Utils.showGetSnackBar('Network error. Please try again.');
      }
    } else {
      Utils.showGetSnackBar('Please enter both old and new number');
    }
  }

  void changeNumber(String newNumber, String otp) async {
    try {
      Map<String, dynamic> data = await UserApi().changeNumber(newNumber, otp);

      if (data['status'] ?? false) {
        userController.storage.write('userToken', data['token']);
        userController.updateUserLocally(User.fromJson(data['user']));
        Get.close(2);
        oldNumberController.clear();
        newNumberController.clear();
        deleteOtpController.clear();
        Utils.showGetSnackBar('Number Successfully changed');
      } else {
        Utils.showGetSnackBar(
            data['message'] ?? 'Something went wrong. Try again later.');
      }
    } catch (e) {
      Utils.showGetSnackBar('Failed to change number. Please try again.');
    }
  }

  void requestDeleteAccount() async {
    if (deleteAccountController.text.trim().isNotEmpty) {
      try {
        Map<String, dynamic> data = await UserApi()
            .requestAccountChanges(deleteAccountController.text.trim(), true);

        if (data['status'] ?? false) {
          Get.to(() => CommonOTPScreen(
              phoneNumber: deleteAccountController.text.trim(),
              otp: data['otp']?.toString() ?? '',
              forDelete: true));
        } else {
          Utils.showGetSnackBar('Something went wrong');
        }
      } catch (e) {
        Utils.showGetSnackBar('Network error. Please try again.');
      }
    } else {
      Utils.showGetSnackBar('Please enter your mobile number');
    }
  }

  void deleteAccount() async {
    if (deleteOtpController.text.trim().length == 4) {
      birdController.showLoading.value = true;
      try {
        Map<String, dynamic> data =
            await UserApi().deleteAccount(deleteOtpController.text);

        if (data['status'] ?? false) {
          userController.purgeAccountData();
          Get.offAll(() => const LoginScreen());
        } else {
          Utils.showGetSnackBar(
              data['message'] ?? 'Something went wrong, Try again later');
        }
      } catch (e) {
        Utils.showGetSnackBar('Failed to delete account. Please try again.');
      } finally {
        birdController.showLoading.value = false;
      }
    } else {
      Utils.showGetSnackBar('Please enter 4 - digit OTP');
    }
  }

  void downloadMessages() async {
    await Permission.manageExternalStorage.request();

    try {
      List<Messages> allMessages = LocalDatabase.getAllMessages();
      String formatedMessages = allMessages.map((e) {
        if (e.mMessageType == '0') {
          return e.mMessage;
        }
      }).join('\n');
      // String formatedMessages = allMessages.join('\n');
      final Directory dir = Directory(Constants.DIR_PATH);
      const fileName = 'all-messages.txt';

      String path = '${dir.path}/Humming-Bird/Data/Messages';

      Directory(path).createSync(recursive: true);

      final File file = File('$path/$fileName');
      await file.writeAsString(formatedMessages);
      Utils.showToast(
          'All Messages downloaded in your device - Humming-Bird/Data/Messages',
          Toast.LENGTH_LONG);
    } catch (e) {
      // Silently handle
    }
  }
}
