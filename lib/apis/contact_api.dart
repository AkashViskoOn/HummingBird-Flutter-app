import 'dart:convert';
import 'package:get/get.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/Models/all_contacts_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/user_controller.dart';

class ContactApi {
  UserController userController = Get.find();

  Future<UserModel> getHummingContacts(List<String> contacts) async {
    try {
      Map<String, dynamic> res = await ApiService().post(
          path: Endpoints.fetchHummingContacts,
          data: {'contacts': jsonEncode(contacts)});

      return UserModel.fromJson(res);
    } catch (_) {
      return UserModel.fromJson({});
    }
  }

  Future<AllContactsModel?> fetchAllContacts() async {
    try {
      Map<String, dynamic> res =
          await ApiService().getData(path: Endpoints.fetchContacts);
      return AllContactsModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> addContact({
    required String firstName,
    required String lastName,
    required String mobileNumber,
    String email = '',
    String company = '',
    String notes = '',
    String countryCode = '+91',
  }) async {
    try {
      final data = {
        'first_name': firstName,
        'last_name': lastName,
        'mobile_number': mobileNumber.replaceAll(RegExp(r'\D'), ''),
        'email_address': email,
        'company': company,
        'notes': notes,
      };
      return await ApiService().post(path: Endpoints.addContact, data: data);
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> checkUser(String mobileNumber) async {
    try {
      return await ApiService().getData(
        path: Endpoints.checkContactUser,
        queryParameters: {
          'mobile_number': mobileNumber.replaceAll(RegExp(r'\D'), '')
        },
      );
    } catch (_) {
      return {};
    }
  }
}
