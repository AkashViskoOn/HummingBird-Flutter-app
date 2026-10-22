import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/room_api.dart';
import 'package:humming_bird/components/Models/group_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/main_humming_screen.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/services/group_system_message_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;

class GroupController extends GetxController {
  /// Set to the room id right before a deliberate self-exit so the socket-driven
  /// group update handler knows not to show the "you were removed" snackbar on
  /// the leaving user's own device.
  String? selfLeftRoomId;
  RxInt groupMembers = 0.obs;
  RxBool showLoading = false.obs;
  RxBool isUpdateGroup = false.obs;
  RxBool isDeletingGroup = false.obs;
  RxList<Rooms> groupsList = <Rooms>[].obs;
  GroupModel? groupData;
  File? groupImage;
  String? groupImageRoomId;
  RxString groupImagePath = ''.obs;
  UserController userController = Get.find();
  ContactController contactController = Get.find();
  HomeController homeController = Get.find();

  TextEditingController groupNameController = TextEditingController();
  late ChatController chatController;

  @override
  void onReady() {
    chatController = Get.find();
    super.onReady();
  }

  void addGroupMembers(roomId) async {
    if (contactController.groupParticipants.isNotEmpty) {
      contactController.getContactNumber();

      final addedUserIds = contactController.groupParticipants
          .map((u) => u.userId ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      GroupModel groupModel = await RoomApi()
          .addGroupMembers(roomId, contactController.contactNumbers);

      List<String> userIds = [];
      for (var user in contactController.groupParticipants) {
        userIds.add(user.userId!);
      }
      chatController.emitNewGroup(jsonEncode(userIds));
      chatController.emitGroupUpdate(roomId, userIds);
      contactController.groupParticipants.clear();
      groupMembers.value = groupModel.members!.length;
      groupData = groupModel;

      if ((groupModel.status ?? false) && addedUserIds.isNotEmpty) {
        GroupSystemMessageService.postEvent(
          roomId: roomId,
          event: 'member_added',
          targetIds: addedUserIds,
        );
      }
      update();
      Get.back();
      Utils.showGetSnackBar('New Group Members Added');
    } else {
      Utils.showGetSnackBar('Select Contacts first');
    }
  }

  Future<bool> updateGroup(String roomId, {bool showLoading = true}) async {
    if (showLoading) {
      isUpdateGroup.value = true;
    } else {
      this.showLoading.value = true;
    }
    try {
      // Snapshot the pre-update state so we can persist accurate system events
      // after the backend confirms the change.
      final prior = getUpdatedGroup(roomId);
      final prevName = prior.rName ?? '';
      final prevAvatar = prior.rAvatar ?? '';
      final changedIcon = groupImage != null;

      dio.FormData formData = dio.FormData.fromMap({
        'room_id': roomId,
        'room_name': groupNameController.text.trim(),
        'group_image': groupImage == null
            ? null
            : await dio.MultipartFile.fromFile(groupImage!.path,
                filename: groupImage!.path.split('/').last),
      });

      RoomsModel? data = await RoomApi().updateRoom(formData);

      if (data.status ?? false) {
        contactController.updateGroup(data.room!);
        final newName = data.room?.rName ?? '';
        groupData?.room?.rName = data.room?.rName;
        groupData?.room?.rAvatar = data.room?.rAvatar;
        groupImage = null;
        groupImageRoomId = null;
        groupImagePath.value = '';
        chatController.emitGroupUpdate(roomId);
        update(['Update Group', 'Update Group State']);

        // Persisted system events (fire-and-forget).
        if (newName != prevName) {
          GroupSystemMessageService.postEvent(
            roomId: roomId,
            event: 'group_name_changed',
            prevName: prevName,
            newName: newName,
          );
        }
        if (changedIcon && (data.room?.rAvatar ?? '') != prevAvatar) {
          GroupSystemMessageService.postEvent(
            roomId: roomId,
            event: 'group_icon_changed',
          );
        }
        return true;
      } else {
        Utils.showGetSnackBar(
            data.message ?? 'Something went wrong. Try again later');
        return false;
      }
    } finally {
      if (showLoading) {
        isUpdateGroup.value = false;
      } else {
        this.showLoading.value = false;
      }
    }
  }

  void makeUserAdmin(roomId, userId) async {
    RoomsModel? roomModel = await RoomApi().makeUserAdmin(roomId, userId);

    if (roomModel?.status ?? false) {
      groupData!.room = roomModel!.room;
      chatController.emitGroupUpdate(roomId, [userId]);
      GroupSystemMessageService.postEvent(
        roomId: roomId,
        event: 'member_promoted',
        targetIds: [userId.toString()],
      );
      update();
      Get.back();
    }
  }

  void removeUserAsAdmin(roomId, userId) async {
    RoomsModel? roomModel = await RoomApi().removeAdmin(roomId, userId);

    if (roomModel?.status ?? false) {
      groupData!.room = roomModel!.room;
      chatController.emitGroupUpdate(roomId, [userId]);
      GroupSystemMessageService.postEvent(
        roomId: roomId,
        event: 'member_demoted',
        targetIds: [userId.toString()],
      );
      update();
      Get.back();
    }
  }

  bool checkIfItsMe(userId) {
    User? user = LocalDatabase.getUser(userId);

    if (userId == user?.userId) {
      return true;
    } else {
      return false;
    }
  }

  /// Whether the signed-in user is still a member of [roomId]. Looks at the
  /// freshest room copy (group info > contact list > home list). Non-member
  /// users keep reading history but lose the composer (see ChatScreen).
  bool isCurrentUserMember(String roomId) {
    Rooms? room;
    if (groupData?.room?.rId == roomId) {
      room = groupData!.room;
    } else {
      room = contactController.groupsList
              .firstWhereOrNull((r) => r.rId == roomId) ??
          homeController.groupsList.firstWhereOrNull((r) => r.rId == roomId);
    }
    if (room == null || (room.rUsers ?? '').trim().isEmpty) return true;
    final myId = userController.user?.userId?.toString() ??
        userController.storage.read('userId')?.toString() ??
        '';
    if (myId.isEmpty) return true;
    try {
      final decoded = jsonDecode(room.rUsers!);
      if (decoded is List) return decoded.contains(myId);
    } catch (_) {}
    return true;
  }

  void leaveGroup(String roomId, {User? user}) async {
    String userId = userController.storage.read('userId');
    User? currentUser = LocalDatabase.getUser(userId);

    final isSelfLeave = user == null;
    final leavingUserId = user?.userId ?? currentUser?.userId ?? '';

    // Self exit only: if the last admin is leaving, auto-promote the next
    // member to admin first (WhatsApp behaviour) so the group never ends up
    // admin-less, then leave normally — no more blocking "solo admin" popup.
    if (isSelfLeave && leavingUserId.isNotEmpty) {
      final members = groupData?.members ?? const <User>[];
      if (!canLeaveGroup(currentUser!) && members.length > 1) {
        final nextAdmin =
            members.firstWhereOrNull((m) => m.userId != leavingUserId);
        if (nextAdmin != null) {
          final promoted =
              await RoomApi().makeUserAdmin(roomId, nextAdmin.userId);
          if (!(promoted?.status ?? false)) {
            Utils.showGetSnackBar(
                'Could not transfer admin before leaving. Try again.');
            return;
          }
          GroupSystemMessageService.postEvent(
            roomId: roomId,
            event: 'member_promoted',
            targetIds: [nextAdmin.userId!.toString()],
          );
        }
      }
    }

    // Persist the departure/removal event FIRST so it exists in history even
    // if the membership mutation immediately drops the user from the room.
    if (isSelfLeave) {
      GroupSystemMessageService.postEvent(
        roomId: roomId,
        event: 'member_left',
        actorId: leavingUserId,
      );
    } else {
      GroupSystemMessageService.postEvent(
        roomId: roomId,
        event: 'member_removed',
        targetIds: [leavingUserId],
      );
    }

    GroupModel groupModel = await RoomApi().leaveGroup(roomId, leavingUserId);

    if (groupModel.status ?? false) {
      groupData = groupModel;
      groupMembers.value = groupModel.members?.length ?? 0;
      update();
      List<String>? memberIds =
          groupModel.members?.map((m) => m.userId!).toList();
      chatController.emitGroupUpdate(roomId, memberIds);

      if (isSelfLeave) {
        selfLeftRoomId = roomId;
        LocalDatabase.deleteRoom(roomId);
        LocalDatabase.deleteRoomMessages(roomId);
        Get.offAll(() => const MainHummingScreen());
        Utils.showGetSnackBar('You left the group');
      } else {
        Get.back();
        Utils.showGetSnackBar(
            '${user.userFirstName ?? 'Member'} removed from group');
      }
      contactController.fetchGroups();
    } else {
      Utils.showGetSnackBar('Could not leave the group. Try again later.');
    }
  }

  Future<void> deleteGroup(String roomId) async {
    isDeletingGroup.value = true;
    try {
      final res = await RoomApi().deleteRoom(roomId);

      if (res['status'] ?? false) {
        chatController.emitGroupUpdate(roomId, _allMemberIds());
        contactController.groupsList
            .removeWhere((element) => element.rId == roomId);
        contactController.groupData
            .removeWhere((element) => element.rId == roomId);
        homeController.groupsList
            .removeWhere((element) => element.rId == roomId);

        LocalDatabase.deleteRoom(roomId);
        LocalDatabase.deleteRoomMessages(roomId);

        contactController.groupsList.refresh();
        homeController.groupsList.refresh();
        contactController.update(['group-search-update', 'Update Group']);
        homeController.update(['update-card']);
        homeController.update();

        Get.offAll(() => const MainHummingScreen());
        Utils.showGetSnackBar('Group deleted successfully');
      } else {
        Utils.showGetSnackBar(
            res['message'] ?? 'Something went wrong, Try again later.');
      }
    } finally {
      isDeletingGroup.value = false;
    }
  }

  bool canLeaveGroup(User user) {
    List admins;
    try {
      final decoded = jsonDecode(groupData?.room?.rAdmins ?? '[]');
      admins = decoded is List ? decoded : [];
    } catch (_) {
      admins = [];
    }
    if (admins.contains(user.userId) && admins.length == 1) {
      return false;
    } else {
      return true;
    }
  }

  void fetchGroupInfo(String roomId) async {
    // Silent background refresh when we already have data so remote
    // group-updated events don't flash a full-screen spinner.
    final hasData = groupData != null;
    showLoading.value = !hasData;
    GroupModel data = await RoomApi().fetchGroup(roomId);
    if (data.status ?? false) {
      groupData = data;
      groupMembers.value = data.members?.length ?? 0;
      update();
    }
    showLoading.value = false;
  }

  /// Mute/unmute the group and reflect the new state locally so the Group
  /// Info screen and chat list update instantly. Returns true on success.
  Future<bool> toggleGroupMute(String roomId) async {
    final newStatus = await homeController.toggleMute(roomId);
    if (newStatus == null) {
      Utils.showGetSnackBar('Could not update mute settings. Try again.');
      return false;
    }
    groupData?.room?.rStatus = newStatus;
    update();
    Utils.showGetSnackBar(
      newStatus == '0' ? 'Group muted' : 'Group unmuted',
    );
    return true;
  }

  List<String> _allMemberIds() {
    return groupData?.members?.map((m) => m.userId!).toList() ?? [];
  }

  /// Check for App User
  bool checkIfUserAdmin() {
    if (groupData?.room == null) return false;
    String userId = userController.storage.read('userId');
    User? user = LocalDatabase.getUser(userId);

    List groupAdmins;
    try {
      final decoded = jsonDecode(groupData!.room!.rAdmins ?? '[]');
      groupAdmins = decoded is List ? decoded : [];
    } catch (_) {
      groupAdmins = [];
    }

    if (groupAdmins.contains(user?.userId)) {
      return true;
    } else {
      return false;
    }
  }

  /// Check for All Group Members
  bool checkIfAdmin({User? user}) {
    if (groupData?.room == null) return false;
    String userId = userController.storage.read('userId');
    User? savedUser = LocalDatabase.getUser(userId);
    List admins;
    try {
      final decoded = jsonDecode(groupData!.room!.rAdmins ?? '[]');
      admins = decoded is List ? decoded : [];
    } catch (_) {
      admins = [];
    }

    if (admins.contains(user?.userId ?? savedUser?.userId)) {
      return true;
    } else {
      return false;
    }
  }

  void pickGroupImage(ImageSource source, String roomId) async {
    final ImagePicker imagePicker = ImagePicker();

    XFile? userProfile = await imagePicker.pickImage(source: source);

    if (userProfile != null) {
      File pickedImage = File(userProfile.path);
      groupImage = pickedImage;
      groupImageRoomId = roomId;
      groupImagePath.value = groupImage!.path;
      if (groupNameController.text.trim().isEmpty) {
        groupNameController.text = getUpdatedGroup(roomId).rName ?? 'Group';
      }
      await updateGroup(roomId);
    } else {
      Utils.showGetSnackBar('Group Image not selected');
    }
  }

  Rooms getUpdatedGroup(String groupId) {
    Rooms group = contactController.groupsList.firstWhere(
      (element) => element.rId == groupId,
      orElse: () => Rooms(),
    );
    return group;
  }

  ImageProvider getGroupImage(String groupId) {
    Rooms group = contactController.groupsList.firstWhere(
      (element) => element.rId == groupId,
      orElse: () => Rooms(),
    );
    if (groupImage != null && groupImageRoomId == groupId) {
      return FileImage(groupImage!);
    } else if (group.rAvatar?.isNotEmpty ?? false) {
      return CachedNetworkImageProvider(
          '${Endpoints.mediaBaseUrl}${group.rAvatar!}');
    } else {
      return const AssetImage(AppAssets.defaultProfilePic);
    }
  }
}
