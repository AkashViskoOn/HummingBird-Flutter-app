import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/contact_api.dart';
import 'package:humming_bird/apis/room_api.dart';
import 'package:humming_bird/apis/user_api.dart';
import 'package:humming_bird/components/Models/all_contacts_model.dart';
import 'package:humming_bird/components/Models/custom_contacts_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/app_strings.dart';
import 'package:humming_bird/services/group_system_message_service.dart';
import 'package:humming_bird/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bird_controller.dart';

class ContactController extends GetxController {
  RxBool isPageReady = true.obs;

  RxMap<String, dynamic> contact = <String, dynamic>{}.obs;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController numberController;
  late TextEditingController reportController;

  UserController userController = Get.find();
  RxBool isAddingContact = false.obs;
  TextEditingController groupNameController = TextEditingController();
  BirdController birdController = Get.find();
  late HomeController homeController;

  late List<Contacts> contactsData;
  RxList<Contacts> allContacts = <Contacts>[].obs;
  RxList<Contact> phoneContacts = <Contact>[].obs;
  RxList<User> hummingContacts = <User>[].obs;
  RxBool isFetchingContacts = false.obs;
  RxList<Rooms> groupsList = <Rooms>[].obs;
  List<Rooms> groupData = [];
  RxList<User> groupParticipants = <User>[].obs;
  List<String> contactNumbers = [];
  RxBool showLoading = false.obs;
  List<Contact> phoneData = [];
  bool phoneDataSaved = false;
  List<User> hummingContactsData = [];
  List<Contact> phoneContactsData = [];
  Timer? _debouncer;
  bool _contactListenerRegistered = false;

  RxString checkedUserStatus = 'idle'.obs;
  Rx<User?> checkedUser = Rx<User?>(null);
  Timer? _checkUserDebouncer;

  late TextEditingController emailController;
  late TextEditingController companyController;
  late TextEditingController notesController;

  @override
  void onInit() {
    emailController = TextEditingController();
    companyController = TextEditingController();
    notesController = TextEditingController();
    homeController = Get.find();
    groupsList = RxList.from(LocalDatabase.getGroupRooms());
    groupData = List.from(LocalDatabase.getGroupRooms());
    homeController.fetchSingleChats();
    homeController.fetchGroupChats();
    requestContactsPermission();
    super.onInit();
  }

  @override
  void onClose() {
    _checkUserDebouncer?.cancel();
    _debouncer?.cancel();
    emailController.dispose();
    companyController.dispose();
    notesController.dispose();
    super.onClose();
  }

  /// Wipes the previous account's contacts / groups / phone data from memory
  /// on logout & account switch (the registered controller instance is reused
  /// by GetX, so it must be reset explicitly to avoid showing the old account).
  void resetAccountData() {
    hummingContacts.clear();
    hummingContactsData = [];
    allContacts.clear();
    phoneContacts.clear();
    phoneData = [];
    phoneContactsData = [];
    contactNumbers = [];
    groupsList.clear();
    groupData = [];
    contact.clear();
    isAddingContact.value = false;
    checkedUser.value = null;
    checkedUserStatus.value = 'idle';
    isFetchingContacts.value = false;
  }

  void requestContactsPermission() async {
    final statuses = await [
      Permission.contacts,
      Permission.manageExternalStorage,
    ].request();

    if (statuses[Permission.contacts]?.isGranted ?? false) {
      _registerContactChangeListener();
    }

    getPhoneContacts();
    try {
      NotificationService().startIfNeeded();
    } catch (_) {}
  }

  void _registerContactChangeListener() {
    if (_contactListenerRegistered) return;
    _contactListenerRegistered = true;

    FlutterContacts.addListener(
      () => userController.storage.write('contact_db_changed', true),
    );
  }

  Future<void> refreshContacts({bool silent = false}) async {
    phoneDataSaved = false;
    await getPhoneContacts(silent: silent);
  }

  Future<void> syncContactsOnOpen() async {
    final contactsChanged =
        userController.storage.read('contact_db_changed') == true;
    final hasNoContacts =
        hummingContactsData.isEmpty && phoneContactsData.isEmpty;
    await getPhoneContacts(silent: !contactsChanged && !hasNoContacts);
  }

  Future<void> getPhoneContacts({bool silent = false}) async {
    List<User> savedUsers = LocalDatabase.getHummingContacts() ?? [];
    if (savedUsers.isNotEmpty) {
      hummingContacts.assignAll(savedUsers);
      homeController.contactLoading = false;
      homeController.update();
    }
    if (!silent) {
      isFetchingContacts.value = true;
    }
    try {
      List<Contact> contacts = await FlutterContacts.getContacts(
          withProperties: true, withPhoto: true);
      phoneContacts = RxList.from(contacts);
      await getHummingContacts(silent: silent);
    } finally {
      isFetchingContacts.value = false;
    }
  }

  Future<void> getHummingContacts({bool silent = false}) async {
    final deviceContacts = List<Contact>.from(phoneContacts);
    final uniqueNumbers = deviceContacts
        .map((contact) => contact.phones.isNotEmpty
            ? _normalizePhoneNumber(contact.phones[0].number)
            : '')
        .where((number) => number.isNotEmpty)
        .toSet();

    UserModel contactsData =
        await ContactApi().getHummingContacts(uniqueNumbers.toList());

    if (contactsData.status ?? false) {
      hummingContacts.clear();
      hummingContacts.assignAll(contactsData.data ?? []);
      hummingContactsData = List.from(hummingContacts);

      final hummingUsers = hummingContacts
          .map((element) => element.userMobileNum ?? '')
          .where((number) => number.isNotEmpty)
          .toSet();
      final currentUserNumber = userController.user?.userMobileNum ?? '';

      phoneData = deviceContacts.where((contact) {
        if (contact.phones.isEmpty) return false;
        final number = _normalizePhoneNumber(contact.phones[0].number);
        return hummingUsers.contains(number);
      }).toList();

      phoneContacts = RxList.from(deviceContacts.where((contact) {
        if (contact.phones.isEmpty) return false;
        final number = _normalizePhoneNumber(contact.phones[0].number);
        return !hummingUsers.contains(number) && number != currentUserNumber;
      }).toList());

      phoneContactsData = List.from(phoneContacts);

      for (var user in hummingContacts) {
        String userDisplayName = getAllContactsName(user);
        LocalDatabase.saveCustomContacts(CustomContactsModel(
            id: user.userId,
            displayName: userDisplayName,
            number: user.userMobileNum));
      }

      if (contactsData.data!.isNotEmpty) {
        LocalDatabase.saveHummingContacts(hummingContacts);
      }

      update(['update-contacts-search']);
      phoneDataSaved = true;
      homeController.contactLoading = false;
      homeController.update();
      if (!silent) {
        Utils.showGetSnackBar('Contacts refreshed successfully');
      }
    } else {
      Utils.showGetSnackBar('Something went wrong');
    }
    userController.storage.write('contacts', true);
    userController.storage.write('contact_db_changed', false);
  }

  String _normalizePhoneNumber(String value) {
    final cleaned = value.replaceAllMapped(RegExp(r'\D'), (_) => '');
    if (cleaned.length > 10 && cleaned.startsWith('91')) {
      return cleaned.substring(cleaned.length - 10);
    }
    return cleaned;
  }

  String getAllContactsName(User user) {
    String displayName = '';
    for (var element in phoneData) {
      String number = element.phones[0].number;
      if (number[0] == '+') {
        number = number.substring(3).replaceAllMapped(RegExp(r'\D'), (_) => '');
      } else {
        number = number.replaceAllMapped(RegExp(r'\D'), (_) => '');
      }

      if (number == user.userMobileNum) {
        displayName = element.displayName;
      }
    }
    return displayName;
  }

  (String, String, String, String) getContactData(Rooms room) {
    List roomUsers;
    try {
      final decoded = jsonDecode(room.rUsers ?? '[]');
      roomUsers = decoded is List ? decoded : [];
    } catch (_) {
      roomUsers = [];
    }
    String myId = userController.user?.userId ?? '';
    String displayUserId =
        roomUsers.where((element) => element != myId).toString();
    displayUserId = displayUserId.replaceAll(RegExp(r'[()]'), '').trim();

    User? displayUser = hummingContacts.where((element) {
      return element.userId == displayUserId;
    }).firstOrNull;

    String displayName = '';
    List<CustomContactsModel> customContacts =
        LocalDatabase.getAllCustomContacts();

    for (var element in customContacts) {
      String number = element.number.toString();
      if (number.isEmpty) continue;
      if (number[0] == '+') {
        if (number.length < 4) continue;
        number = number.substring(3).replaceAllMapped(RegExp(r'\D'), (_) => '');
      } else {
        number = number.replaceAllMapped(RegExp(r'\D'), (_) => '');
      }

      if (number.isEmpty) continue;
      if (number == displayUser?.userMobileNum) {
        displayName = element.displayName.toString();
      }
    }

    return (
      displayName,
      displayUserId,
      displayUser?.userMobileNum ?? '',
      displayUser?.userBio ?? ''
    );
  }

  (String, String) getUserBioAndProfile(String userId) {
    User? displayUser = hummingContacts.firstWhereOrNull((element) {
      return element.userId == userId;
    });

    return (displayUser?.userBio ?? '', displayUser?.userImage ?? '');
  }

  String getUserNameById(String userId) {
    User? displayUser = hummingContacts.where((element) {
      return element.userId == userId;
    }).firstOrNull;

    String displayName = '';

    for (var element in phoneData) {
      if (element.phones.isEmpty) continue;
      String number = element.phones[0].number;
      if (number[0] == '+') {
        number = number.substring(3).replaceAllMapped(RegExp(r'\D'), (_) => '');
      } else {
        number = number.replaceAllMapped(RegExp(r'\D'), (_) => '');
      }

      if (number == displayUser?.userMobileNum) {
        displayName = element.displayName;
      }
    }

    if (displayName.isNotEmpty) return displayName;
    return resolveUserNameLocal(userId);
  }

  /// True when we already have a real (non-number) name cached locally.
  bool hasLocalUserName(String userId) {
    if (userId.isEmpty) return false;
    final user = hummingContacts.firstWhereOrNull((e) => e.userId == userId) ??
        LocalDatabase.getUser(userId);
    return '${user?.userFirstName ?? ''} ${user?.userLastName ?? ''}'
        .trim()
        .isNotEmpty;
  }

  /// Best-effort name lookup across every LOCAL source (sync — safe in
  /// build): humming contacts -> Hive user cache -> custom contacts ->
  /// mobile number as last resort.
  String resolveUserNameLocal(String userId) {
    if (userId.isEmpty) return '';
    final user = hummingContacts.firstWhereOrNull((e) => e.userId == userId) ??
        LocalDatabase.getUser(userId);
    String name =
        '${user?.userFirstName ?? ''} ${user?.userLastName ?? ''}'.trim();
    if (name.isEmpty) {
      final custom = LocalDatabase.getAllCustomContacts()
          .firstWhereOrNull((c) => c.id == userId);
      name = custom?.displayName?.trim() ?? '';
    }
    if (name.isEmpty && user?.userMobileNum?.isNotEmpty == true) {
      name = user!.userMobileNum!;
    }
    return name;
  }

  /// Resolves a user id to a displayable identity, fetching from the server
  /// and caching into Hive when local sources don't know the user.
  Future<({String name, String number})> resolveUserIdentity(
      String userId) async {
    final known = hummingContacts.firstWhereOrNull((e) => e.userId == userId) ??
        LocalDatabase.getUser(userId);
    String number = known?.userMobileNum ?? '';
    String name = resolveUserNameLocal(userId);

    if (name.isEmpty || name == number) {
      try {
        final res = await UserApi().getUserData(userId);
        final fetched = res?.user;
        if (res != null && (res.status ?? false) && fetched != null) {
          LocalDatabase.saveUser(fetched);
          name = '${fetched.userFirstName ?? ''} ${fetched.userLastName ?? ''}'
              .trim();
          if (name.isEmpty) name = fetched.userMobileNum ?? '';
          number = fetched.userMobileNum ?? number;
          update(['block-unblock']);
        }
      } catch (_) {}
    }
    return (name: name, number: number);
  }

  String getGroupSenderLabel(String senderId) {
    if (senderId == userController.user?.userId) return 'You';
    final name = getUserNameById(senderId);
    if (name.isNotEmpty) return name.split(' ')[0];
    final user = hummingContacts.firstWhereOrNull((e) => e.userId == senderId);
    return user?.userMobileNum ?? '';
  }

  String getUserIdByNumber(String number) {
    User? user = hummingContacts.firstWhereOrNull((e) {
      return e.userMobileNum == number;
    });

    return user?.userId ?? '';
  }

  String getUserProfilePic(String userId) {
    User? user = hummingContacts.where((element) {
      return element.userId == userId;
    }).firstOrNull;
    return user?.userImage ?? '';
  }

  Future<String> getUserNumberById(Rooms room) async {
    String senderNumber = '';
    if (room.rUsers == null || room.rUsers!.isEmpty) return senderNumber;

    List allIds;
    try {
      final decoded = jsonDecode(room.rUsers!);
      if (decoded is! List || decoded.isEmpty) return senderNumber;
      allIds = decoded;
    } catch (_) {
      return senderNumber;
    }

    String userId = allIds
        .where((element) => element.toString() != userController.user!.userId!)
        .toString();

    userId = userId.replaceAll(RegExp(r'[()]'), '').trim();

    UserModel? sender = await UserApi().getUserData(userId.toString());
    if (sender?.status ?? false) {
      senderNumber = sender!.user!.userMobileNum!;
    }
    return senderNumber;
  }

  (bool, Rooms?) checkIfRoomExists(User user) {
    bool isRoomExists = false;
    Rooms? room;
    User? deviceUser = userController.user;
    for (var element in homeController.singleChatsList) {
      List users;
      try {
        final decoded = jsonDecode(element.rUsers ?? '[]');
        users = decoded is List ? decoded : [];
      } catch (_) {
        users = [];
      }
      if (users.contains(user.userId) && users.contains(deviceUser!.userId)) {
        room = element;
        isRoomExists = true;
      }
    }
    return (isRoomExists, room);
  }

  void fetchGroups() async {
    isFetchingContacts.value = true;
    try {
      RoomsModel? data = await RoomApi().fetchAllRooms(1);
      if (data?.status ?? false) {
        groupsList = RxList.from(data!.rooms!);
        homeController.groupsList = RxList.from(data.rooms!);
        LocalDatabase.saveRooms(data.rooms!);
        groupData = data.rooms ?? [];
        homeController.update(['update-card']);
      }
    } finally {
      isFetchingContacts.value = false;
      update(['group-search-update', 'Update Group']);
    }
  }

  void createGroup() async {
    String groupName = groupNameController.text.trim();
    final selectedMemberIds = groupParticipants
        .map((user) => user.userId)
        .whereType<String>()
        .toList();
    getContactNumber();
    RoomsModel? room = await RoomApi().createRoom(1, groupName, contactNumbers);
    groupNameController.clear();
    groupParticipants.clear();

    if (room?.status ?? false) {
      final createdRoom = room!.room!;
      groupsList.insert(0, createdRoom);
      groupData = List.from(groupsList);
      homeController.groupsList.insert(0, createdRoom);
      LocalDatabase.saveRooms([createdRoom]);
      groupsList.refresh();
      homeController.groupsList.refresh();
      homeController.update(['update-card']);
      update(['group-search-update', 'Update Group']);
      if (selectedMemberIds.isNotEmpty && Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().emitNewGroup(jsonEncode(selectedMemberIds));
      }
      // Persist "You created this group" (fire-and-forget) and open the new
      // thread so the context card + naming flow are reachable immediately.
      final createdRoomId = createdRoom.rId;
      if (createdRoomId != null && createdRoomId.isNotEmpty) {
        Get.find<ChatController>().emitGroupUpdate(createdRoomId);
        GroupSystemMessageService.postEvent(
          roomId: createdRoomId,
          event: 'group_created',
        );
      }
      Get.back();
      if (createdRoomId != null && createdRoomId.isNotEmpty) {
        Get.to(() => ChatScreen(
              name: createdRoom.rName?.trim().isNotEmpty == true
                  ? createdRoom.rName!
                  : 'Group',
              roomId: createdRoomId,
              isGroup: true,
            ));
      }
    } else {
      Get.back();
    }
  }

  void updateGroup(Rooms group) {
    int index = groupsList.indexWhere((element) => element.rId == group.rId);
    if (index >= 0) {
      groupsList[index].rName = group.rName;
      groupsList[index].rAvatar = group.rAvatar;
    } else {
      groupsList.add(group);
    }
    final homeIndex = homeController.groupsList
        .indexWhere((element) => element.rId == group.rId);
    if (homeIndex >= 0) {
      homeController.groupsList[homeIndex].rName = group.rName;
      homeController.groupsList[homeIndex].rAvatar = group.rAvatar;
      homeController.groupsList.refresh();
    }
    LocalDatabase.saveRooms([group]);
    groupsList.refresh();
    homeController.update(['update-card']);
    update(['Update Group']);
  }

  void sendInviteMessage(String number) async {
    if (Platform.isAndroid) {
      Uri smsUri = Uri.parse(
          'sms:$number?body=${AppStrings.MESSAGE_INVITE_TEXT}${AppStrings.INVITE_LINK}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        Utils.showGetSnackBar('Could not open messages');
      }
    } else if (Platform.isIOS) {
      Uri smsUri = Uri.parse(
          'sms:${AppStrings.MESSAGE_INVITE_TEXT}${AppStrings.INVITE_LINK}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        Utils.showGetSnackBar('Could not open messages');
      }
    }
  }

  void getContactNumber() {
    contactNumbers.clear();
    for (var contact in groupParticipants) {
      contactNumbers.add(contact.userMobileNum!);
    }
  }

  void searchContacts(String keyword, {bool forAllContacts = false}) {
    if (_debouncer?.isActive ?? false) _debouncer?.cancel();

    _debouncer = Timer(
      const Duration(milliseconds: 300),
      () {
        hummingContacts = RxList.from(hummingContactsData);
        if (forAllContacts) phoneContacts = RxList.from(phoneContactsData);

        if (keyword.trim().isEmpty) {
          hummingContacts = RxList.from(hummingContactsData);
          if (forAllContacts) phoneContacts = RxList.from(phoneContactsData);
        } else {
          List<User> newHummingContacts = [];

          newHummingContacts = hummingContactsData.where((element) {
            String contactName = getAllContactsName(element);
            if (contactName
                .toLowerCase()
                .contains(keyword.toLowerCase().trim())) {
              return true;
            } else {
              return false;
            }
          }).toList();

          if (forAllContacts) {
            List<Contact> newNonHummingContacts = [];

            newNonHummingContacts = phoneContactsData.where((element) {
              if (element.displayName
                  .toLowerCase()
                  .contains(keyword.toLowerCase())) {
                return true;
              } else {
                return false;
              }
            }).toList();
            phoneContacts = RxList.from(newNonHummingContacts);
          }
          hummingContacts = RxList.from(newHummingContacts);
        }
        update(['update-contacts-search']);
      },
    );
  }

  void searchInGroups(String groupName) {
    groupsList = RxList.from(groupData);

    if (groupName.trim().isEmpty) {
      groupsList = RxList.from(groupData);
    } else {
      List<Rooms> newList = groupData.where((element) {
        if (element.rName!
            .toLowerCase()
            .contains(groupName.toLowerCase().trim())) {
          return true;
        } else {
          return false;
        }
      }).toList();

      groupsList = RxList.from(newList);
    }
    update(['group-search-update']);
  }

  void updateGroupsList() {
    update();
  }

  Future<User?> searchUserByPhone(String number) async {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) return null;
    try {
      final res = await ContactApi().checkUser(clean);
      if (res['status'] == true && res['user'] != null) {
        return User.fromJson(res['user']);
      }
    } catch (_) {}
    return null;
  }

  void addHummingContact(User user) async {
    hummingContacts.insert(0, user);
    hummingContacts.refresh();
    final saved = LocalDatabase.getHummingContacts() ?? [];
    if (!saved.any((u) => u.userId == user.userId)) {
      saved.add(user);
      LocalDatabase.saveHummingContacts(saved);
    }
    final displayName =
        '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'.trim();
    if (displayName.isNotEmpty) {
      LocalDatabase.saveCustomContacts(CustomContactsModel(
        id: user.userId,
        displayName: displayName,
        number: user.userMobileNum ?? '',
      ));
    }
    LocalDatabase.invalidateContactsCache();
    update(['update-contacts-search']);
  }

  void checkUserExists(String mobileNumber) {
    _checkUserDebouncer?.cancel();
    final number = mobileNumber.replaceAll(RegExp(r'\D'), '');
    if (number.length < 10) {
      checkedUserStatus.value = 'idle';
      checkedUser.value = null;
      return;
    }
    checkedUserStatus.value = 'checking';
    _checkUserDebouncer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final res = await ContactApi().checkUser(number);
        if (res['status'] == true && res['user'] != null) {
          checkedUser.value = User.fromJson(res['user']);
          checkedUserStatus.value = 'found';
        } else {
          checkedUser.value = null;
          checkedUserStatus.value = 'not_found';
        }
      } catch (e) {
        checkedUser.value = null;
        checkedUserStatus.value = 'idle';
      }
    });
  }

  Future<bool> saveNewContactToServer({
    required String firstName,
    required String lastName,
    required String mobileNumber,
    String email = '',
    String company = '',
    String notes = '',
  }) async {
    try {
      final res = await ContactApi().addContact(
        firstName: firstName,
        lastName: lastName,
        mobileNumber: mobileNumber,
        email: email,
        company: company,
        notes: notes,
      );
      if (res['status'] == true) {
        return true;
      }
      Utils.showGetSnackBar('Failed to save contact');
      return false;
    } catch (e) {
      Utils.showGetSnackBar('Network error. Contact saved on device.');
      return false;
    }
  }

  void saveNewContact() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final number = numberController.text.trim();

    if (firstName.isEmpty || number.isEmpty) {
      Utils.showGetSnackBar('First name and mobile number are required');
      return;
    }

    final cleanNumber = number.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length < 10) {
      Utils.showGetSnackBar('Please enter a valid mobile number');
      return;
    }

    isAddingContact.value = true;
    try {
      final newContact = Contact()
        ..name.first = firstName
        ..name.last = lastName
        ..phones = [Phone(cleanNumber)]
        ..emails = [Email(emailController.text.trim())]
        ..organizations = [Organization(company: companyController.text.trim())]
        ..notes = [Note(notesController.text.trim())];
      await newContact.insert();

      phoneDataSaved = false;
      getPhoneContacts();

      await saveNewContactToServer(
        firstName: firstName,
        lastName: lastName,
        mobileNumber: cleanNumber,
        email: emailController.text.trim(),
        company: companyController.text.trim(),
        notes: notesController.text.trim(),
      );

      firstNameController.clear();
      lastNameController.clear();
      numberController.clear();
      emailController.clear();
      companyController.clear();
      notesController.clear();
      checkedUserStatus.value = 'idle';
      checkedUser.value = null;

      Get.back();
      Utils.showGetSnackBar('Contact saved successfully');
    } catch (e) {
      Utils.showGetSnackBar('Failed to save contact');
    } finally {
      isAddingContact.value = false;
    }
  }

  void blockUser(userId, userName) async {
    UserModel res = await UserApi().blockUser(userId);

    if (res.status ?? false) {
      userController.updateUserLocally(res.user!);
      Get.back();
      update(['block-unblock']);
      Utils.showGetSnackBar('You successfully blocked $userName.');
    } else {
      Utils.showGetSnackBar(
          res.message ?? 'Something went wrong, Try again later.');
    }
  }

  void unBlockUser(userId, userName, {bool pop = true}) async {
    UserModel res = await UserApi().unBlockUser(userId);

    if (res.status ?? false) {
      userController.updateUserLocally(res.user!);
      if (pop) Get.back();
      update(['block-unblock']);
      Utils.showGetSnackBar('$userName unblocked.');
    } else {
      Utils.showGetSnackBar(
          res.message ?? 'Something went wrong, Try again later.');
    }
  }

  bool checkIfUserIsBlocked(String userId) {
    final user = userController.user;
    final blockListRaw = user?.userBlockList;
    if (user == null || blockListRaw == null || blockListRaw.isEmpty) {
      return false;
    }

    List<String> userBlockList;
    try {
      final decoded = jsonDecode(blockListRaw);
      userBlockList = decoded is List ? decoded.cast<String>() : [];
    } catch (_) {
      userBlockList = [];
    }

    if (userBlockList.contains(userId)) {
      return true;
    } else {
      return false;
    }
  }

  void reportUser(String userId, String report, String userName) async {
    if (report.isNotEmpty) {
      Map<String, dynamic> res = await UserApi().reportUser(userId, report);

      if (res['status'] ?? false) {
        Get.back();
        Utils.showGetSnackBar('You reported $userName successfully.');
      } else {
        Utils.showGetSnackBar(
            res['message'] ?? 'Something went wrong, Try again later.');
      }
    } else {
      Utils.showGetSnackBar('Please describe why you want to report $userName');
    }
  }

  void addRecentlyContacted(String userId) {
    final storage = userController.storage;
    List<String> recent = (storage.read('recently_contacted') as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    recent.remove(userId);
    recent.insert(0, userId);
    if (recent.length > 5) {
      recent = recent.sublist(0, 5);
    }
    storage.write('recently_contacted', recent);
  }

  void toggleFavoriteContact(String userId) {
    final storage = userController.storage;
    List<String> favorites =
        (storage.read('favorite_contacts') as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
    if (favorites.contains(userId)) {
      favorites.remove(userId);
    } else {
      favorites.add(userId);
    }
    storage.write('favorite_contacts', favorites);
  }

  bool isFavoriteContact(String userId) {
    final storage = userController.storage;
    final favorites = (storage.read('favorite_contacts') as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return favorites.contains(userId);
  }

  List<String> getFavoriteContacts() {
    final storage = userController.storage;
    return (storage.read('favorite_contacts') as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
  }

  List<String> getRecentlyContacted() {
    final storage = userController.storage;
    return (storage.read('recently_contacted') as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
  }
}
