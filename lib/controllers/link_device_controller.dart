import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/linked_devices_api.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/models/linked_device_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

/// Drives Settings -> Linked devices.
///
/// Two jobs, both of them real network work:
///   * load/rename/revoke the account's linked devices
///   * scan a desktop's pairing QR and either approve or reject it
///
/// The old version of this controller POSTed the raw scanned text to
/// `user/save-secret-key` and kept a hand-made device list in GetStorage, so
/// nothing it displayed was ever backed by the server. There is no local cache
/// here: the list is re-read from the API every time, because a stale cached
/// list is exactly the kind of thing that makes a security screen untrustworthy.
class LinkDeviceController extends GetxController {
  final LinkedDevicesRepository _repository = LinkedDevicesRepository();

  final RxList<LinkedDevice> devices = <LinkedDevice>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isScanning = false.obs;

  /// Set when a load failed, so the UI can offer a retry instead of pretending
  /// the user has no devices.
  final RxString loadError = ''.obs;

  Future<void> loadDevices() async {
    isLoading.value = true;
    loadError.value = '';
    final result = await _repository.listDevices();
    isLoading.value = false;

    if (!result.ok) {
      // Leave the previous list alone and surface why, rather than blanking the
      // screen into a false "no devices linked".
      loadError.value = result.message;
      return;
    }
    devices.assignAll(result.devices);
  }

  Future<void> renameDevice(LinkedDevice device, String newName) async {
    final name = newName.trim();
    if (name.isEmpty) return;
    final ok = await _repository.renameDevice(device.deviceId, name);
    if (!ok) {
      Utils.showToast('Could not rename the device.', Toast.LENGTH_LONG);
      return;
    }
    await loadDevices();
  }

  Future<bool> revokeDevice(LinkedDevice device) async {
    final ok = await _repository.revokeDevice(device.deviceId);
    if (!ok) {
      Utils.showToast('Could not sign out that device.', Toast.LENGTH_LONG);
      return false;
    }
    Utils.showToast('Device signed out.', Toast.LENGTH_SHORT);
    await loadDevices();
    return true;
  }

  Future<bool> revokeAllOtherDevices() async {
    final ok = await _repository.revokeAllOtherDevices();
    if (!ok) {
      Utils.showToast('Could not sign out other devices.', Toast.LENGTH_LONG);
      return false;
    }
    Utils.showToast('Signed out of all other devices.', Toast.LENGTH_SHORT);
    await loadDevices();
    return true;
  }

  /// Scan a desktop pairing code, then let the user approve or reject it.
  ///
  /// Returns nothing; every outcome is reported to the user, because a silent
  /// failure here looks identical to "scanning did nothing".
  Future<void> scanAndPair() async {
    if (isScanning.value) return;

    isScanning.value = true;
    String? scanned;
    try {
      // Ask for camera access up front, in the same way calls do. The scanner
      // plugin would trigger the system prompt on its own, but requesting here
      // keeps the denial path ours: a clear message instead of a scanner error.
      final camera = await Permission.camera.request();
      if (!camera.isGranted) {
        Utils.showToast('Camera permission is required to scan a QR code.', Toast.LENGTH_LONG);
        isScanning.value = false;
        return;
      }
      // Re-fetched at the call site, not captured across the permission await:
      // a BuildContext held over an async gap is exactly what the analyzer bans.
      if (Get.overlayContext == null) {
        isScanning.value = false;
        return;
      }
      scanned = await SimpleBarcodeScanner.scanBarcode(
        Get.overlayContext!,
        scanType: ScanType.qr,
      );
    } catch (_) {
      // Camera permission denied, no camera, or the scanner route threw.
      Utils.showToast('Could not open the scanner. Check camera access.', Toast.LENGTH_LONG);
      isScanning.value = false;
      return;
    }
    isScanning.value = false;

    // A null result is a deliberate cancel. Saying "invalid QR" on cancel is
    // the kind of small lie that makes people distrust the rest of the screen.
    if (scanned == null) return;

    DesktopPairingRequest request;
    try {
      request = DesktopPairingRequest.parse(scanned);
    } on FormatException catch (error) {
      Utils.showToast(error.message, Toast.LENGTH_LONG);
      return;
    }

    final approved = await _confirmOnPhone(request);
    if (approved == null) return; // dismissed

    if (approved) {
      final ok = await _repository.approvePairing(request);
      Utils.showToast(
        ok
            ? 'Desktop linked. Finish connecting on your computer.'
            : 'Could not link that device. It may have expired.',
        Toast.LENGTH_LONG,
      );
    } else {
      final ok = await _repository.rejectPairing(request.pairingRef);
      Utils.showToast(
        ok ? 'Request declined.' : 'Could not decline that request.',
        Toast.LENGTH_LONG,
      );
    }

    // A successful approval creates a device row, so the list is now stale.
    await loadDevices();
  }

  /// Show the confirm/reject sheet.
  ///
  /// Returns `true` to approve, `false` to reject, `null` if dismissed.
  Future<bool?> _confirmOnPhone(DesktopPairingRequest request) async {
    final result = await showModalBottomSheet<bool>(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ConfirmPairingSheet(request: request),
    );
    return result;
  }
}

class _ConfirmPairingSheet extends StatelessWidget {
  final DesktopPairingRequest request;
  const _ConfirmPairingSheet({required this.request});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Link this computer?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A computer is asking to sign in to your Humming Bird account. '
                  'Only continue if it is one you recognise and are sitting in front of.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Allow'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Decline'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
