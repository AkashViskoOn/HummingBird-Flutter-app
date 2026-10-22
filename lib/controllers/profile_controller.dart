import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/user_api.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  File? profilePic;
  String removeImage = '';
  RxString profilePicPath = ''.obs;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController dobController = TextEditingController();

  UserController userController = Get.find();
  BirdController birdController = Get.find();

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    bioController.dispose();
    emailController.dispose();
    dobController.dispose();
    super.onClose();
  }

  void updateProfile() async {
    birdController.showLoading.value = true;
    try {
      Dio.FormData userData = Dio.FormData.fromMap({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'bio': bioController.text.trim(),
        'user_dob': dobController.text.trim(),
        'profile_completed': '1',
        'user_image': profilePic == null
            ? null
            : await Dio.MultipartFile.fromFile(profilePic!.path,
                filename: profilePic!.path.split('/').last),
        'remove_image': removeImage,
      });

      UserModel? data = await UserApi().updateUser(userData);

      if (data?.status ?? false) {
        update(['user-profile']);
        userController.updateUserLocally(data!.user!);
        Get.find<ChatController>().emitProfileUpdated(data.user!);
        profilePic = null;
        profilePicPath.value = '';
        birdController.updateProfileImage();
        update(['update-profile']);
        Get.back();
        Utils.showGetSnackBar('Profile Updated Successfully');
      } else {
        Utils.showGetSnackBar(
            'Something went wrong while updating profile. Try again later');
      }
    } catch (e) {
      Utils.showGetSnackBar('Failed to update profile. Please try again.');
    } finally {
      birdController.showLoading.value = false;
    }
  }

  void pickProfilePic(ImageSource source) async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      XFile? userProfile = await imagePicker.pickImage(source: source);
      if (userProfile != null) {
        File pickedImage = File(userProfile.path);
        profilePic = pickedImage;
        profilePicPath.value = pickedImage.path;
        removeImage = '';
        update(['update-profile']);
        update(['user-profile']);
      } else {
        Utils.showGetSnackBar('Profile Picture not picked');
      }
    } catch (e) {
      Utils.showGetSnackBar('Could not pick image. Please try again.');
    }
  }

  bool get hasProfileImage =>
      (userController.user?.userImage?.isNotEmpty ?? false) ||
      profilePic != null;

  void removeProfilePic() {
    profilePic = null;
    profilePicPath.value = '';
    removeImage = '1';
    update(['update-profile']);
    update(['user-profile']);
  }

  ImageProvider getProfilePic() {
    if (removeImage == '1') {
      return const AssetImage(AppAssets.defaultProfilePic);
    } else if (profilePic != null) {
      return FileImage(profilePic!);
    } else if (userController.user!.userImage?.isNotEmpty ?? false) {
      return CachedNetworkImageProvider(
          '${Endpoints.mediaBaseUrl}${userController.user!.userImage}');
    } else {
      return const AssetImage(AppAssets.defaultProfilePic);
    }
  }
}
