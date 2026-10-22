import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/authentication_api.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/main_humming_screen.dart';
import 'package:humming_bird/pages/login_screen/otp_validate.dart';
import 'package:humming_bird/pages/login_screen/profile_details.dart';

class AuthenticationController extends GetxController {
  RxBool isPageReady = true.obs;
  RxBool showLoading = false.obs;
  RxInt timer = 59.obs;
  RxString otpCode = ''.obs;

  TextEditingController otpController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  UserController userController = Get.find();

  void submitLogin() async {
    showLoading.value = true;
    try {
      if (phoneNumberController.text.length == 10) {
        final res =
            await AuthenticationApi().userLogin(phoneNumberController.text, '');

        if (res['status'] ?? false) {
          otpCode.value = res['otp'].toString();
          userController.storage.write('tempToken', res['tempToken']);
          userController.userId = res['user_id'].toString();

          timer(59);
          startTimer();
          Get.to(
            () => const OTPValidate(),
          );
        } else {
          Utils.showGetSnackBar(
              res['message'] ?? 'Something went wrong, Try again later.');
        }
      } else {
        Utils.showGetSnackBar('Please enter valid phone number.');
      }
    } catch (e) {
      Utils.showGetSnackBar(
          'Network error. Please check your connection and try again.');
    } finally {
      showLoading.value = false;
    }
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);

    Timer.periodic(oneSec, (Timer tm) {
      if (timer.value == 0) {
        tm.cancel();
        timer.refresh();
      } else {
        timer(timer.value - 1);
        timer.refresh();
      }
    });
  }

  void validateOTP() async {
    if (otpController.text.length != 4) {
      Utils.showGetSnackBar('Please enter 4 digit OTP');
    } else {
      showLoading.value = true;
      try {
        String tempToken = userController.storage.read('tempToken') ?? '';
        final UserModel? userModel = await AuthenticationApi()
            .userOTPValidation(otpController.text, tempToken);

        if (userModel?.status ?? false) {
          User user = userModel!.user!;

          // Wipe any leftover account from a previous session in the same
          // process BEFORE persisting the new one, so the home screen never
          // flashes the old number's chats.
          userController.purgeAccountData();
          userController.setUserLoggedIn(user, userModel.token ?? '');
          otpController.clear();

          if (user.userProfileComplete == '1') {
            Get.offAll(() => const MainHummingScreen());
          } else {
            Get.offAll(() => const ProfileCreate());
          }
        } else {
          Utils.showGetSnackBar('Verification failed. Please try again.');
        }
      } catch (e) {
        Utils.showGetSnackBar(
            'Network error during verification. Please try again.');
      } finally {
        showLoading.value = false;
      }
    }
  }

  // submitOTP() async {
  //   if (phoneNumberController.text.length == 4) {
  //     final res = await AuthenticationApi().userOTP();
  //     if (res['status']) {
  //       Get.to(() => OTPValidate());
  //     } else {
  //       Get.showSnackbar(const GetSnackBar(
  //         title: 'Error',
  //         message: 'Please enter valid OTP',
  //       duration: Duration(seconds: 2),
  //     ));
  //   }
  // }
}
