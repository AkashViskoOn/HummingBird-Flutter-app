import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/models/linked_device_model.dart';
import 'package:humming_bird/res/endpoints.dart';

/// Result of a device-linking call.
///
/// Every one of these routes answers `{status, message, data}`, and a failure is
/// an HTTP error with a JSON body, not an exception. The repository therefore
/// returns this instead of a bare `Map`, so callers cannot accidentally read
/// `data` off a failed response — which is how the old implementation ended up
/// seeding a fabricated device row out of an empty `{}`.
class LinkedDevicesResult {
  final bool ok;
  final String message;
  final List<LinkedDevice> devices;

  const LinkedDevicesResult({
    required this.ok,
    required this.message,
    this.devices = const [],
  });
}

class LinkedDevicesRepository {
  /// GET /user/linked-devices
  ///
  /// Returns only what the server actually sent. A non-`true` envelope yields
  /// an empty list and the server's own message, so the UI can tell "you have no
  /// devices" apart from "we could not ask".
  Future<LinkedDevicesResult> listDevices() async {
    try {
      final res = await ApiService().getData(path: Endpoints.linkedDevices);
      if ((res['status'] ?? false) != true) {
        return LinkedDevicesResult(
          ok: false,
          message: '${res['message'] ?? 'Could not load linked devices'}',
        );
      }
      final data = res['data'];
      if (data is! List) {
        return const LinkedDevicesResult(
          ok: false,
          message: 'The server returned an unexpected device list.',
        );
      }
      return LinkedDevicesResult(
        ok: true,
        message: '${res['message'] ?? 'Linked devices'}',
        devices: data
            .whereType<Map>()
            .map((row) => LinkedDevice.fromJson(Map<String, dynamic>.from(row)))
            .where((device) => device.deviceId != 0)
            // A revoked device is not a linked device any more. The server
            // already filters these out; this keeps the screen honest even
            // against an older backend, so a signed-out desktop can never
            // linger in the list after a revoke.
            .where((device) => !device.isRevoked)
            .toList(),
      );
    } catch (_) {
      return const LinkedDevicesResult(
        ok: false,
        message: 'Could not reach Humming Bird. Check your connection.',
      );
    }
  }

  /// POST /user/desktop-pairing/approve
  ///
  /// Approves a scanned desktop. The phone proves only WHO it is (its JWT) plus
  /// the two public values from the QR; it never transmits the claim secret,
  /// which stays on the desktop.
  Future<bool> approvePairing(DesktopPairingRequest request) async {
    return _postOk(
      Endpoints.desktopPairingApprove,
      {'pairing_ref': request.pairingRef, 'challenge': request.challenge},
    );
  }

  /// POST /user/desktop-pairing/reject
  Future<bool> rejectPairing(String pairingRef) async {
    return _postOk(Endpoints.desktopPairingReject, {'pairing_ref': pairingRef});
  }

  /// POST /user/linked-devices/revoke
  Future<bool> revokeDevice(int deviceId) async {
    return _postOk(Endpoints.linkedDevicesRevoke, {'device_id': '$deviceId'});
  }

  /// POST /user/linked-devices/revoke with `all_others=1`.
  ///
  /// Only ever offered from the PHONE. The server keeps `$jwt->device_id`, which
  /// is absent on a phone, so this revokes every linked device row — and a phone
  /// has no row of its own, so the person scanning cannot lock themselves out of
  /// their own account. On a paired desktop the same call would deliberately
  /// keep the caller and drop the rest.
  Future<bool> revokeAllOtherDevices() async {
    return _postOk(Endpoints.linkedDevicesRevoke, {'all_others': '1'});
  }

  /// POST /user/linked-devices/rename
  Future<bool> renameDevice(int deviceId, String deviceName) async {
    return _postOk(Endpoints.linkedDevicesRename, {
      'device_id': '$deviceId',
      'device_name': deviceName,
    });
  }

  Future<bool> _postOk(String path, Map<String, dynamic> body) async {
    try {
      final res = await ApiService().post(path: path, data: body);
      return (res['status'] ?? false) == true;
    } catch (_) {
      return false;
    }
  }
}
