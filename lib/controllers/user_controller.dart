import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/apis/user_api.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/scheduled_moment_controller.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/main_humming_screen.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as Dio;

class UserController extends GetxController {
  GetStorage storage = GetStorage();
  RxBool isLoggedIn = false.obs;
  Rx<CroppedFile?> croppedFile = CroppedFile('').obs;
  bool inHomeScreen = true;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  RxBool isUpdatingUser = false.obs;
  User? user;
  String userId = '';

  @override
  void onReady() {
    getUser();
    super.onReady();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  /// Clears ALL persisted + in-memory account data so a different number can
  /// log in with a pristine state. Called on logout and on the 401 expiry
  /// path. Without this, Hive boxes and GetX controllers keep the previous
  /// account's chats, so a new login briefly showed the old number's data.
  void purgeAccountData() {
    try {
      LocalDatabase.deleteLocalDatabase();
    } catch (_) {}
    // Reset this controller's own account fields.
    userId = '';
    user = null;
    isLoggedIn.value = false;
    try {
      firstNameController.clear();
      lastNameController.clear();
      emailController.clear();
    } catch (_) {}
    try {
      croppedFile.value = CroppedFile('');
    } catch (_) {}
    try {
      storage.erase();
    } catch (_) {}
    _resetDataControllers();
  }

  /// GetX reuses already-registered controller instances (a plain `Get.put`
  /// does NOT rebuild them), so on account switch every data controller must
  /// be wiped explicitly to stop the previous number's data from rendering.
  void _resetDataControllers() {
    void reset<T extends GetxController>(void Function(T c) resetFn) {
      try {
        final c = Get.find<T>();
        resetFn(c);
      } catch (_) {}
    }

    reset<HomeController>((c) => c.resetAccountData());
    reset<ContactController>((c) => c.resetAccountData());
    reset<ChatController>((c) => c.resetAccountData());
    reset<BirdController>((c) => c.resetAccountData());
    reset<StatusController>((c) => c.resetAccountData());
    reset<ScheduledMomentController>((c) => c.resetAccountData());
  }

  void setUserLoggedIn(User user, String token) {
    isLoggedIn.value = true;
    userId = user.userId ?? '';
    storage.write('isLoggedIn', true);
    storage.write('userId', user.userId);
    storage.write('userToken', token);
    LocalDatabase.saveUser(user);
  }

  void getUser() {
    String storedUserId = storage.read('userId') ?? '';
    userId = storedUserId;
    User? user = LocalDatabase.getUser(storedUserId);
    this.user = user;
    if (storedUserId.isNotEmpty) {
      getUpdatedUser(storedUserId);
    }
  }

  void updateUserLocally(User updatedUser) {
    user = updatedUser;
    LocalDatabase.saveUser(updatedUser);
  }

  void getUpdatedUser(userId) async {
    try {
      UserModel? userModel = await UserApi().getUserData(userId);

      if (userModel?.status ?? false) {
        User user = userModel!.user!;
        LocalDatabase.saveUser(user);
        this.user = user;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getUpdatedUser error: $e');
      }
    }
  }

  void updateProfile() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty) {
      Utils.showGetSnackBar('Please fill all the details.');
      return;
    }

    isUpdatingUser.value = true;
    try {
      Dio.FormData userData = Dio.FormData.fromMap({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'profile_completed': '1',
        'user_image': (croppedFile.value?.path ?? '').isEmpty
            ? null
            : await Dio.MultipartFile.fromFile(croppedFile.value!.path,
                filename: croppedFile.value?.path.split('/').last),
      });

      final UserModel? updatedUser = await UserApi().updateUser(userData);

      if (updatedUser?.status ?? false) {
        User user = updatedUser!.user!;
        LocalDatabase.saveUser(user);
        Get.offAll(() => const MainHummingScreen());
      } else {
        Utils.showGetSnackBar('Failed to update profile.');
      }
    } catch (e) {
      Utils.showGetSnackBar('Network error. Please try again.');
    } finally {
      isUpdatingUser.value = false;
    }
  }

  Future<void> selectProfilePhoto(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker imagePicker = ImagePicker();

      XFile? pickedFile = await imagePicker.pickImage(source: source);

      if (pickedFile != null) {
        croppedFile.value =
            await ImageCropper().cropImage(sourcePath: pickedFile.path);
        croppedFile.refresh();
      }
    } catch (e) {
      if (kDebugMode) {}
    }
  }
}
