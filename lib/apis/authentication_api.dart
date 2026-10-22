import 'package:dio/dio.dart' as Dio;
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/res/endpoints.dart';

class AuthenticationApi {
  Future<Map<String, dynamic>> userLogin(
      String mobileNumber, String appSignature) async {
    try {
      Map<String, dynamic> res = await ApiService().post(
          path: Endpoints.loginUser,
          data: {
            'user_mobile_num': mobileNumber,
            'app_signature': appSignature
          });
      return res;
    } catch (_) {
      return {};
    }
  }

  Future<UserModel?> userOTPValidation(String userOTP, String tempToken) async {
    try {
      Dio.FormData data = Dio.FormData.fromMap({
        'otp': userOTP,
      });

      Map<String, dynamic> res = await ApiService().post(
          path: Endpoints.loginOTP,
          data: data,
          options:
              Dio.Options(headers: {"Authorization": "Bearer $tempToken"}));

      return UserModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }
}

// userOTP() async {
//   final response = await http
//       .post(Uri.parse(""), body: {"user_login-otp_num": "1" "2" "3" "4"});

//   if (response.statusCode == 200) {
//     final res = jsonDecode(response.body);
//     return res;
//   } else {
//     final res = {"status": false, "message": "Invalid Response"};

//     return res;
//   }
// }
