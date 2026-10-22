import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/calling/active_call_screen.dart';
import 'package:humming_bird/pages/calling/incoming_call_screen.dart';
import 'package:humming_bird/pages/calling/mini_call_overlay.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/services/notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

enum AudioRoute { earpiece, speaker, bluetooth, headset }

enum CallAudioState {
  idle,
  outgoingRinging,
  incomingRinging,
  connecting,
  connected,
  ended,
  rejected,
  cancelled,
  failedTimeout,
}

class CallController extends GetxController {
  late ChatController chatController;
  late UserController userController;

  RxBool isInCall = false.obs;
  RxString callType = 'audio'.obs;
  RxString callState = 'idle'.obs;
  RxString callSessionId = ''.obs;
  RxString otherUserId = ''.obs;
  RxString otherUserName = ''.obs;
  RxBool isMicMuted = false.obs;
  RxBool isSpeakerOn = false.obs;
  RxBool isCallRecording = false.obs;
  RxInt callDuration = 0.obs;
  RxString callerId = ''.obs;
  RxBool isCameraOff = false.obs;
  Rx<AudioRoute> currentAudioRoute = AudioRoute.earpiece.obs;
  RxList<AudioRoute> availableAudioRoutes = <AudioRoute>[].obs;
  RxInt streamRevision = 0.obs;

  // ── WebRTC ────────────────────────────────────────────────────────────────
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _renderersReady = false;
  bool _iAmCaller = false;
  bool _activeCallScreenOpen = false;
  static BuildContext? _miniOverlayContext;
  RTCSessionDescription? _pendingOffer;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  Timer? _ringTimer;
  AudioPlayer? _ringtonePlayer;
  AudioPlayer? _ringbackPlayer;

  bool get iAmCaller => _iAmCaller;

  CallAudioState get callAudioState {
    switch (callState.value) {
      case 'ringing':
        return _iAmCaller
            ? CallAudioState.outgoingRinging
            : CallAudioState.incomingRinging;
      case 'connecting':
        return CallAudioState.connecting;
      case 'connected':
      case 'reconnecting':
        return CallAudioState.connected;
      case 'ended':
        return CallAudioState.ended;
      default:
        return CallAudioState.idle;
    }
  }

  Timer? _callTimer;
  Timer? _reconnectTimer;
  Timer? _connectingFailTimer;
  bool _listenersAdded = false;
  Timer? _audioRouteTimer;

  RxList<Map<String, dynamic>> callHistory = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> favoriteContacts = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> blockedCallUsers = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> speedDialContacts = <Map<String, dynamic>>[].obs;

  /// Persists a raw call-timeline line to app files AND debugPrint (prefixed
  /// CALL-TRACE), so the exact terminal branch can be read from the device
  /// without logcat. File: `Android/data/<pkg>/files/call_trace.txt`.
  void _trace(String line) {
    final ts = DateTime.now().toIso8601String();
    debugPrint('CALL-TRACE $line');
    try {
      getExternalStorageDirectory().then((dir) async {
        if (dir == null) return;
        final file = File('${dir.path}/call_trace.txt');
        try {
          await file.writeAsString('$ts $line\n',
              mode: FileMode.append, flush: true);
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    chatController = Get.find();
    userController = Get.find();
    loadCallHistory();
    loadFavorites();
    loadBlockedUsers();
    loadSpeedDial();
    _setupCallListeners();
    _initRenderers();
  }

  @override
  void onClose() {
    MiniCallOverlay.dismiss();
    stopTimer();
    _callTimer?.cancel();
    _ringTimer?.cancel();
    _reconnectTimer?.cancel();
    _connectingFailTimer?.cancel();
    stopAllCallSounds();
    _disposeWebRtc();
    if (_renderersReady) {
      try {
        localRenderer.dispose();
        remoteRenderer.dispose();
      } catch (_) {}
      _renderersReady = false;
    }
    super.onClose();
  }

  Future<void> _initRenderers() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _renderersReady = true;
    } catch (_) {}
  }

  void _setupCallListeners() {
    if (_listenersAdded) return;
    _listenersAdded = true;
    _attachSocketListeners();
  }

  void _attachSocketListeners() {
    const callEvents = [
      'incoming-call',
      'call-accepted',
      'call-rejected',
      'call-ended',
      'call-cancel',
      'webrtc-offer',
      'webrtc-answer',
      'webrtc-ice-candidate',
    ];
    try {
      for (final e in callEvents) {
        chatController.socket.off(e);
      }
      chatController.socket.on('incoming-call', _onIncomingCall);
      chatController.socket.on('call-accepted', _onCallAccepted);
      chatController.socket.on('call-rejected', _onCallRejected);
      chatController.socket.on('call-ended', _onCallEnded);
      chatController.socket.on('call-cancel', _onCallCancel);
      chatController.socket.on('webrtc-offer', _onWebRtcOffer);
      chatController.socket.on('webrtc-answer', _onWebRtcAnswer);
      chatController.socket.on('webrtc-ice-candidate', _onIceCandidate);
      chatController.socket.on('disconnect', _onSocketDisconnected);
      debugPrint(
          'CALL-TRACE _attachSocketListeners: all call listeners registered on socket ${chatController.socket.id}');
    } catch (e) {
      debugPrint('CALL-TRACE _attachSocketListeners FAILED: $e');
      Future.delayed(const Duration(seconds: 2), _attachSocketListeners);
    }
  }

  void _onSocketDisconnected(dynamic reason) {
    debugPrint(
        '[CALL AUDIO] SOCKET_DISCONNECT reason=$reason -> All call sounds STOP');
    stopAllCallSounds();
  }

  // ── Socket handlers ───────────────────────────────────────────────────────

  void _onIncomingCall(dynamic data) {
    debugPrint('CALL-TRACE _onIncomingCall received: $data');
    if (data is! Map<String, dynamic>) {
      debugPrint(
          'CALL-TRACE _onIncomingCall: data is not Map<String, dynamic>, type=${data.runtimeType}');
      return;
    }

    final fromId = data['callerId']?.toString() ?? '';
    debugPrint(
        'CALL-TRACE _onIncomingCall fromId="$fromId" isInCall=${isInCall.value}');

    // Self-call guard: when the same account is signed in on multiple devices,
    // the server relays the call to every socket of the target user. If the
    // caller's own other device gets this event it would immediately "reject"
    // (or show an incoming dialog for a call this phone placed) and slam the
    // real caller's screen closed. Ignore any incoming-call that names me.
    if (fromId.isNotEmpty && fromId == userController.userId) {
      debugPrint(
          'CALL-TRACE _onIncomingCall: IGNORED self-call (same account) fromId=$fromId');
      _trace(
          '_onIncomingCall: IGNORED self-call fromId=$fromId sessionId=${data['sessionId']}');
      return;
    }

    if (isInCall.value) {
      _trace(
          '_onIncomingCall: AUTO-REJECT isInCall=${isInCall.value} state=${callState.value} fromId=$fromId');
      _emitCallEnd(
        sessionId: data['sessionId']?.toString() ?? '',
        reason: 'rejected',
        targetUserId: fromId,
      );
      return;
    }

    if (_isBlockedForCalls(fromId)) {
      _trace('_onIncomingCall: AUTO-REJECT blocked fromId=$fromId');
      _emitCallEnd(
        sessionId: data['sessionId']?.toString() ?? '',
        reason: 'rejected',
        targetUserId: fromId,
      );
      return;
    }

    callType.value = data['callType'] ?? 'audio';
    callSessionId.value = data['sessionId'] ?? '';
    otherUserId.value = fromId;
    otherUserName.value = data['callerName'] ?? 'Calling...';
    callerId.value = fromId;
    callState.value = 'ringing';
    isInCall.value = true;
    _iAmCaller = false;
    _trace(
        '_onIncomingCall: ACCEPTED sessionId=${callSessionId.value} callerId=$fromId type=${callType.value}');
    debugPrint('[CALL ROLE] Receiver');
    debugPrint('[CALL AUDIO] Incoming call received');

    if (userController.storage.read('call_settings_vibration') ?? true) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000, 500, 1000], repeat: -1);
    }
    _startIncomingRingtone();

    NotificationService.showIncomingCallNotification(
      callerName: otherUserName.value,
      sessionId: callSessionId.value,
      callerId: fromId,
      callType: callType.value,
    );

    _ringTimer?.cancel();
    _ringTimer = Timer(const Duration(seconds: 60), () {
      if (isInCall.value && callState.value != 'connected') {
        addIncomingCallHistory({
          'callerId': callerId.value,
          'callerName': otherUserName.value,
          'callType': callType.value,
          'status': 'missed',
        });
        _recordCallOnBackend('missed');
        stopTimer();
        isInCall.value = false;
        callState.value = 'idle';
        _stopAllCallSounds('TIMEOUT');
        _closeCallUi();
        NotificationService.showMissedCallNotification(
          callerName: otherUserName.value,
          callerId: fromId,
          callType: callType.value,
        );
      }
    });

    if (!(Get.isDialogOpen ?? false)) {
      MiniCallOverlay.dismiss();
      Get.dialog(
        PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {},
          child: const IncomingCallScreen(),
        ),
        barrierDismissible: false,
        barrierColor: Colors.black54,
        useSafeArea: false,
      );
    }
  }

  void _onCallAccepted(dynamic data) {
    debugPrint(
        'CALL-TRACE _onCallAccepted: data=$data iAmCaller=$_iAmCaller sessionId=${callSessionId.value}');
    if (!_iAmCaller || data is! Map<String, dynamic>) {
      debugPrint(
          'CALL-TRACE _onCallAccepted: REJECTED early — _iAmCaller=$_iAmCaller');
      return;
    }
    if (data['sessionId'] != null &&
        data['sessionId'].toString() != callSessionId.value) {
      debugPrint(
          'CALL-TRACE _onCallAccepted: SESSION MISMATCH expected=${callSessionId.value} got=${data['sessionId']}');
      return;
    }
    debugPrint('CALL-TRACE _onCallAccepted: starting WebRTC as caller');
    _trace(
        '_onCallAccepted: START WebRTC-as-caller session=${callSessionId.value}');
    _ringTimer?.cancel();
    stopOutgoingRingback();
    Vibration.cancel();
    callState.value = 'connecting';
    _startWebRtcAsCaller();
  }

  bool _eventMatchesCurrentSession(dynamic data) {
    final session = data is Map<String, dynamic> ? data['sessionId'] : null;
    if (session == null) return true;
    final matches = session.toString() == callSessionId.value;
    if (!matches) {
      debugPrint(
          'CALL-TRACE SESSION MISMATCH: expected=${callSessionId.value} got=$session — ignoring stale event');
    }
    return matches;
  }

  void _onCallRejected(dynamic data) {
    debugPrint('CALL-TRACE _onCallRejected: data=$data iAmCaller=$_iAmCaller');
    if (!_eventMatchesCurrentSession(data)) {
      _trace('_onCallRejected: SKIPPED (session mismatch) data=$data');
      return;
    }
    _trace(
        '_onCallRejected: ACCEPTED iAmCaller=$_iAmCaller session=${callSessionId.value}');
    if (_iAmCaller) {
      stopOutgoingRingback();
    } else {
      stopIncomingRingtone();
    }
    if (!_iAmCaller) {
      addIncomingCallHistory({
        'callerId': callerId.value,
        'callerName': otherUserName.value,
        'callType': callType.value,
        'status': 'rejected',
      });
    } else {
      _addCallHistoryEntry('rejected');
    }
    _recordCallOnBackend('rejected');
    stopTimer();
    isInCall.value = false;
    callState.value = 'idle';
    _closeCallUi();
  }

  void _onCallEnded(dynamic data) {
    debugPrint('[CALL AUDIO] Call ended (received)');
    if (!_eventMatchesCurrentSession(data)) {
      _trace('_onCallEnded: SKIPPED (session mismatch) data=$data');
      return;
    }
    _trace(
        '_onCallEnded: ACCEPTED iAmCaller=$_iAmCaller duration=${callDuration.value}');
    final status = !_iAmCaller && callDuration.value == 0
        ? 'missed'
        : (callDuration.value > 0 ? 'answered' : 'missed');
    if (!_iAmCaller && callDuration.value == 0) {
      addIncomingCallHistory({
        'callerId': callerId.value,
        'callerName': otherUserName.value,
        'callType': callType.value,
        'status': status,
      });
    } else {
      _addCallHistoryEntry(status);
    }
    debugPrint('[CALL AUDIO] Call ended (received)');
    _stopAllCallSounds('ENDED');
    _recordCallOnBackend(status);
    stopTimer();
    isInCall.value = false;
    callState.value = 'idle';
    callDuration.value = 0;
    _closeCallUi();
  }

  void _onCallCancel(dynamic data) {
    debugPrint('[CALL AUDIO] Caller cancelled');
    if (!_eventMatchesCurrentSession(data)) {
      _trace('_onCallCancel: SKIPPED (session mismatch) data=$data');
      return;
    }
    _trace(
        '_onCallCancel: ACCEPTED iAmCaller=$_iAmCaller state=${callState.value}');
    if (isInCall.value && callState.value != 'connected') {
      if (_iAmCaller) {
        stopOutgoingRingback();
      } else {
        stopIncomingRingtone();
      }
      stopTimer();
      isInCall.value = false;
      callState.value = 'idle';
      addIncomingCallHistory({
        'callerId': callerId.value,
        'callerName': otherUserName.value,
        'callType': callType.value,
        'status': 'missed',
      });
      _recordCallOnBackend('missed');
      _closeCallUi();
      NotificationService.showMissedCallNotification(
        callerName: otherUserName.value,
        callerId: otherUserId.value,
        callType: callType.value,
      );
      Utils.showGetSnackBar('Call cancelled');
    }
  }

  void _onWebRtcOffer(dynamic data) {
    debugPrint('CALL-TRACE _onWebRtcOffer: iAmCaller=$_iAmCaller data=$data');
    if (_iAmCaller || data is! Map<String, dynamic> || data['sdp'] == null) {
      debugPrint(
          'CALL-TRACE _onWebRtcOffer: REJECTED — iAmCaller=$_iAmCaller isMap=${data is Map} hasSdp=${data is Map ? data['sdp'] != null : false}');
      return;
    }
    if (data['sessionId'] != null &&
        data['sessionId'].toString() != callSessionId.value) {
      debugPrint(
          'CALL-TRACE _onWebRtcOffer: SESSION MISMATCH expected=${callSessionId.value} got=${data['sessionId']}');
      return;
    }
    _pendingOffer = RTCSessionDescription(
      data['sdp'].toString(),
      data['type']?.toString() ?? 'offer',
    );
    debugPrint(
        'CALL-TRACE _onWebRtcOffer: stored pending offer. pc=${_pc != null} localStream=${_localStream != null}');
    if (_pc != null && _localStream != null) {
      _applyPendingOffer();
    }
  }

  void _onWebRtcAnswer(dynamic data) {
    debugPrint('CALL-TRACE _onWebRtcAnswer: iAmCaller=$_iAmCaller data=$data');
    if (!_iAmCaller ||
        data is! Map<String, dynamic> ||
        data['sdp'] == null ||
        _pc == null) {
      debugPrint(
          'CALL-TRACE _onWebRtcAnswer: REJECTED — iAmCaller=$_iAmCaller isMap=${data is Map} hasSdp=${data is Map ? data['sdp'] != null : false} pcNull=${_pc == null}');
      return;
    }
    try {
      _pc!
          .setRemoteDescription(
            RTCSessionDescription(data['sdp'].toString(), 'answer'),
          )
          .then((_) => _flushPendingCandidates());
      debugPrint('CALL-TRACE _onWebRtcAnswer: set remote description (answer)');
    } catch (e) {
      debugPrint('CALL-TRACE _onWebRtcAnswer EXCEPTION: $e');
    }
  }

  void _onIceCandidate(dynamic data) {
    if (data is! Map<String, dynamic> || data['candidate'] == null) return;
    debugPrint(
        'CALL-TRACE _onIceCandidate received, sessionId=${data['sessionId']}');
    try {
      final c = data['candidate'];
      final candidate = RTCIceCandidate(
        c['candidate']?.toString(),
        c['sdpMid']?.toString(),
        c['sdpMLineIndex'] is int ? c['sdpMLineIndex'] as int : null,
      );
      _pc?.getRemoteDescription().then((remote) {
        if (remote != null) {
          debugPrint(
              'CALL-TRACE _onIceCandidate: adding directly (remote set)');
          _pc?.addCandidate(candidate);
        } else {
          debugPrint(
              'CALL-TRACE _onIceCandidate: queuing (remote not set yet)');
          _pendingRemoteCandidates.add(candidate);
        }
      });
    } catch (_) {}
  }

  Future<void> initCall(String targetUserId, String type) async {
    if (isInCall.value) {
      Utils.showGetSnackBar('Already on a call');
      return;
    }
    if (_isBlockedForCalls(targetUserId)) {
      Utils.showGetSnackBar('You blocked this user for calls');
      return;
    }

    if (type == 'video') {
      final cam = await Permission.camera.request();
      final mic = await Permission.microphone.request();
      if (!cam.isGranted || !mic.isGranted) {
        Utils.showGetSnackBar('Camera and microphone permissions required');
        return;
      }
    } else {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        Utils.showGetSnackBar('Microphone permission required');
        return;
      }
    }

    _iAmCaller = true;
    debugPrint('[CALL ROLE] Caller');
    callType.value = type;
    otherUserId.value = targetUserId;
    callerId.value = userController.userId;
    callState.value = 'ringing';
    isInCall.value = true;

    final displayName = _getContactName(targetUserId);
    otherUserName.value = displayName;

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    callSessionId.value = sessionId;

    if (!_renderersReady) {
      await _initRenderers();
    }

    try {
      await _getLocalMedia();
    } catch (_) {
      Utils.showGetSnackBar('Could not access camera/microphone');
      isInCall.value = false;
      callState.value = 'idle';
      return;
    }

    _activeCallScreenOpen = true;
    Get.to(() => const ActiveCallScreen(isCaller: true));

    final callPayload = {
      'targetUserId': targetUserId,
      'callType': type,
      'sessionId': sessionId,
      'callerId': userController.userId,
      'callerName': _myDisplayName(),
    };
    debugPrint('CALL-TRACE emit call-init: $callPayload');
    debugPrint(
        'CALL-TRACE socket connected=${chatController.socket.connected} id=${chatController.socket.id}');
    chatController.socket.emit('call-init', callPayload);

    startRingback();
    _recordCallOnBackend('initiated');
    _trace(
        'initCall: sessionId=${callSessionId.value} callee=$otherUserId iAmCaller=$_iAmCaller isInCall=${isInCall.value}');

    // NOTE: peer connection is NOT created here. Creating it while ringing
    // starts ICE/STUN gathering before the callee even answers — on networks
    // where outbound STUN (UDP 3478) is blocked this fires a fast ICE
    // `failed` event and the call slams closed right after the screen opens.
    // The caller's pc (and offer) is created in _startWebRtcAsCaller once the
    // callee accepts.

    _ringTimer?.cancel();
    _ringTimer = Timer(const Duration(seconds: 45), () {
      if (isInCall.value && callState.value != 'connected') {
        _endDueToNoAnswer();
      }
    });
  }

  Future<void> answerCall(String sessionId) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      Utils.showGetSnackBar('Microphone permission required');
      return;
    }
    if (callType.value == 'video') {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        Utils.showGetSnackBar('Camera permission required');
        return;
      }
    }

    _ringTimer?.cancel();
    debugPrint('[CALL AUDIO] Accept pressed');
    _trace('answerCall: sessionId=$sessionId iAmCaller=$_iAmCaller');
    stopIncomingRingtone();
    Vibration.cancel();

    callState.value = 'connecting';

    if (!_renderersReady) {
      await _initRenderers();
    }

    try {
      await _getLocalMedia();
    } catch (_) {}

    if (Get.isDialogOpen ?? false) Get.back();
    _activeCallScreenOpen = true;
    Get.to(() => const ActiveCallScreen(isCaller: false));

    final answerPayload = {
      'sessionId': sessionId,
      'answererId': userController.userId,
      'callerId': callerId.value,
    };
    debugPrint('CALL-TRACE emit call-answer: $answerPayload');
    chatController.socket.emit('call-answer', answerPayload);

    _recordCallOnBackend('answered');

    // Watchdog: if the media path (ICE) can't finalize within 15s of the
    // answer, close the call cleanly instead of hanging on "connecting…".
    _connectingFailTimer?.cancel();
    _connectingFailTimer = Timer(const Duration(seconds: 15), () {
      if (isInCall.value && callState.value == 'connecting') {
        _failCall('Call could not connect');
      }
    });

    await _prepareWebRtcAsCallee();
  }

  void rejectCall(String sessionId) {
    _ringTimer?.cancel();
    debugPrint('[CALL AUDIO] Reject pressed');
    if (_iAmCaller) {
      stopOutgoingRingback();
    } else {
      stopIncomingRingtone();
    }
    Vibration.cancel();

    callState.value = 'idle';
    isInCall.value = false;

    _emitCallEnd(
      sessionId: sessionId,
      reason: 'rejected',
      targetUserId: _iAmCaller ? otherUserId.value : callerId.value,
    );

    if (!_iAmCaller) {
      addIncomingCallHistory({
        'callerId': callerId.value,
        'callerName': otherUserName.value,
        'callType': callType.value,
        'status': 'rejected',
      });
    } else {
      _addCallHistoryEntry('rejected');
    }

    _disposeWebRtc();
    _closeCallUi();
  }

  void endCall() {
    _ringTimer?.cancel();
    debugPrint('[CALL AUDIO] Call ended (local end)');
    _trace(
        'endCall: BUTTON/EXTERNAL iAmCaller=$_iAmCaller state=${callState.value} session=${callSessionId.value}');
    _stopAllCallSounds('ENDED');
    Vibration.cancel();

    final wasConnected =
        callState.value == 'connected' || callState.value == 'reconnecting';

    _emitCallEnd(
      sessionId: callSessionId.value,
      reason: 'ended',
      targetUserId: _iAmCaller ? otherUserId.value : callerId.value,
      duration: callDuration.value,
    );

    if (!_iAmCaller && !wasConnected) {
      addIncomingCallHistory({
        'callerId': callerId.value,
        'callerName': otherUserName.value,
        'callType': callType.value,
        'status': 'missed',
      });
    } else {
      _addCallHistoryEntry(callDuration.value > 0 ? 'answered' : 'missed');
    }

    _recordCallOnBackend(wasConnected ? 'ended' : 'missed');
    stopTimer();
    callState.value = 'idle';
    isInCall.value = false;
    callDuration.value = 0;
    _disposeWebRtc();
    _closeCallUi();
  }

  void toggleMute() {
    isMicMuted.toggle();
    try {
      for (final track in _localStream?.getAudioTracks() ?? []) {
        track.enabled = !isMicMuted.value;
      }
    } catch (_) {}
  }

  void toggleSpeaker() {
    setAudioRoute(isSpeakerOn.value ? AudioRoute.earpiece : AudioRoute.speaker);
  }

  Future<void> flipCamera() async {
    try {
      final tracks = _localStream?.getVideoTracks();
      if (tracks != null && tracks.isNotEmpty) {
        await Helper.switchCamera(tracks[0]);
      }
    } catch (_) {}
  }

  void toggleRecording() => isCallRecording.toggle();

  Future<void> toggleCamera() async {
    isCameraOff.toggle();
    try {
      for (final track in _localStream?.getVideoTracks() ?? []) {
        track.enabled = !isCameraOff.value;
      }
    } catch (_) {}
  }

  // ── Mini overlay ─────────────────────────────────────────────────────────

  static void setOverlayContext(BuildContext context) {
    _miniOverlayContext = context;
  }

  void showMiniCallOverlay() {
    if (!isInCall.value) return;
    // Force the call to stay "open" as a floating panel even after the full
    // screen is popped.
    MiniCallOverlay.show(_miniOverlayContext);
  }

  void showActiveCallScreen() {
    if (!isInCall.value) return;
    _activeCallScreenOpen = true;
    Get.to(() => const ActiveCallScreen(isCaller: false));
  }

  void markCallScreenClosed() {
    _activeCallScreenOpen = false;
  }

  bool get hasExternalAudioDevices =>
      availableAudioRoutes.length > 2; // more than earpiece + speaker

  // Poll available audio devices so connect/disconnect is picked up live.
  void _startAudioRouteMonitor() {
    _audioRouteTimer?.cancel();
    _audioRouteTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isInCall.value) {
        _audioRouteTimer?.cancel();
        return;
      }
      detectAudioRoute();
      // Android's audio switch defaults to the speakerphone and can silently
      // revert after an audio/device event. Re-selecting the user's chosen
      // route on each tick keeps the earpiece/speaker selection sticky, which
      // is what actually moves audio off the loud speaker.
      if (Platform.isAndroid) {
        setAudioRoute(currentAudioRoute.value);
      }
    });
  }

  void _stopAudioRouteMonitor() {
    _audioRouteTimer?.cancel();
    _audioRouteTimer = null;
  }

  Future<void> detectAudioRoute() async {
    try {
      final devices = await Helper.enumerateDevices('audiooutput');
      final hasBluetooth = devices.any((d) =>
          d.label.toLowerCase().contains('bluetooth') ||
          d.label.toLowerCase().contains('bt'));
      final hasHeadset = devices.any((d) =>
          d.label.toLowerCase().contains('headset') ||
          d.label.toLowerCase().contains('wired') ||
          d.label.toLowerCase().contains('usb audio'));

      final available = <AudioRoute>[
        AudioRoute.earpiece,
        AudioRoute.speaker,
      ];
      if (hasBluetooth) available.add(AudioRoute.bluetooth);
      if (hasHeadset) available.add(AudioRoute.headset);
      availableAudioRoutes.value = available;

      // If the currently selected route is no longer available (e.g. the
      // Bluetooth device or wired headset was disconnected), fall back to a
      // valid route immediately and keep the UI in sync with real audio.
      if (!available.contains(currentAudioRoute.value)) {
        setAudioRoute(
            isSpeakerOn.value ? AudioRoute.speaker : AudioRoute.earpiece);
      }
    } catch (_) {
      // enumerateDevices failed — assume only earpiece + speaker.
      availableAudioRoutes.value = <AudioRoute>[
        AudioRoute.earpiece,
        AudioRoute.speaker,
      ];
      if (!availableAudioRoutes.contains(currentAudioRoute.value)) {
        currentAudioRoute.value =
            isSpeakerOn.value ? AudioRoute.speaker : AudioRoute.earpiece;
      }
    }
  }

  // Precise native device routing. Uses Helper.selectAudioOutput so Android
  // actually moves audio to the requested device (the boolean setSpeakerphoneOn
  // alone is unreliable for switching back to the earpiece on many devices).
  void setAudioRoute(AudioRoute route) {
    // Never route to a device that isn't actually available.
    if (availableAudioRoutes.isNotEmpty &&
        !availableAudioRoutes.contains(route) &&
        route != AudioRoute.speaker &&
        route != AudioRoute.earpiece) {
      return;
    }
    currentAudioRoute.value = route;
    switch (route) {
      case AudioRoute.speaker:
        isSpeakerOn.value = true;
        // enableSpeakerphone(true) rebuilds the preferred list as
        // speaker-first AND selects the speakerphone — the canonical path.
        try {
          Helper.setSpeakerphoneOn(true);
        } catch (_) {
          try {
            Helper.selectAudioOutput('speaker');
          } catch (_) {}
        }
        break;
      case AudioRoute.earpiece:
        isSpeakerOn.value = false;
        // enableSpeakerphone(false) is THE reliable way back to the earpiece:
        // it rebuilds the preferred list so the earpiece outranks the
        // speakerphone, then selects earpiece (favoring BT/wired first).
        try {
          Helper.setSpeakerphoneOn(false);
        } catch (_) {
          try {
            Helper.selectAudioOutput('earpiece');
          } catch (_) {}
        }
        break;
      case AudioRoute.bluetooth:
        isSpeakerOn.value = false;
        try {
          Helper.setSpeakerphoneOnButPreferBluetooth();
        } catch (_) {
          try {
            Helper.selectAudioOutput('bluetooth');
          } catch (_) {
            try {
              Helper.setSpeakerphoneOn(false);
            } catch (_) {}
          }
        }
        break;
      case AudioRoute.headset:
        isSpeakerOn.value = false;
        try {
          Helper.selectAudioOutput('wired-headset');
        } catch (_) {
          try {
            Helper.setSpeakerphoneOn(false);
          } catch (_) {}
        }
        break;
    }
  }

  void cycleAudioOutput() {
    switch (currentAudioRoute.value) {
      case AudioRoute.earpiece:
        setAudioRoute(AudioRoute.speaker);
        break;
      case AudioRoute.speaker:
        setAudioRoute(AudioRoute.earpiece);
        break;
      case AudioRoute.bluetooth:
        setAudioRoute(AudioRoute.earpiece);
        break;
      case AudioRoute.headset:
        setAudioRoute(AudioRoute.earpiece);
        break;
    }
  }

  void startTimer() {
    _callTimer?.cancel();
    callDuration.value = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration.value++;
    });
  }

  void stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  String get formattedDuration {
    final m = (callDuration.value ~/ 60).toString().padLeft(2, '0');
    final s = (callDuration.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── WebRTC engine ─────────────────────────────────────────────────────────

  Future<void> _getLocalMedia() async {
    if (_localStream != null) return;
    final noiseSuppression =
        userController.storage.read('call_settings_noise') ?? true;
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': noiseSuppression,
      },
      'video': callType.value == 'video' ? {'facingMode': 'user'} : false,
    });
    if (callType.value == 'video' && _localStream != null) {
      localRenderer.srcObject = _localStream;
      streamRevision.value++;
    }
  }

  void _emitCallEnd({
    required String sessionId,
    required String reason,
    required String targetUserId,
    int duration = 0,
  }) {
    chatController.socket.emit('call-end', {
      'sessionId': sessionId,
      'userId': userController.userId,
      'targetUserId': targetUserId,
      'reason': reason,
      if (reason != 'rejected') 'duration': duration,
    });
  }

  void _closeCallUi() {
    _disposeWebRtc();
    stopAllCallSounds();
    Vibration.cancel();
    MiniCallOverlay.dismiss();
    if (Get.isDialogOpen ?? false) Get.back();
    if (_activeCallScreenOpen) {
      _activeCallScreenOpen = false;
      Get.back();
    }
  }

  bool _isBlockedForCalls(String userId) {
    if (userId.isEmpty) return false;
    final blockedForCalls = blockedCallUsers.any(
      (e) =>
          e['userId']?.toString() == userId ||
          e['contactId']?.toString() == userId,
    );
    if (blockedForCalls) return true;
    try {
      final raw = userController.user?.userBlockList;
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).contains(userId);
      }
    } catch (_) {}
    return false;
  }

  void _endDueToNoAnswer() {
    _trace(
        '_endDueToNoAnswer: 45s ring timeout iAmCaller=$_iAmCaller session=${callSessionId.value}');
    _stopAllCallSounds('TIMEOUT');
    chatController.socket.emit('call-cancel', {
      'sessionId': callSessionId.value,
      'userId': userController.userId,
      'targetUserId': otherUserId.value,
    });
    _addCallHistoryEntry('missed');
    _recordCallOnBackend('ended');
    isInCall.value = false;
    callState.value = 'idle';
    _closeCallUi();
    Utils.showGetSnackBar('${otherUserName.value} did not answer');
  }

  Future<void> _startWebRtcAsCaller() async {
    debugPrint(
        'CALL-TRACE _startWebRtcAsCaller: creating offer for ${otherUserId.value}');
    try {
      await _createPeerConnection();
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': callType.value == 'video' ? 1 : 0,
      });
      await _pc!.setLocalDescription(offer);
      debugPrint(
          'CALL-TRACE _startWebRtcAsCaller: emitting webrtc-offer, sdpLength=${offer.sdp?.length}');
      chatController.socket.emit('webrtc-offer', {
        'targetUserId': otherUserId.value,
        'sessionId': callSessionId.value,
        'sdp': offer.sdp,
        'type': offer.type,
        'fromUserId': userController.userId,
        'callType': callType.value,
      });
      _trace(
          '_startWebRtcAsCaller: OFFER SENT session=${callSessionId.value} sdpLength=${offer.sdp?.length}');
    } catch (e) {
      debugPrint('CALL-TRACE _startWebRtcAsCaller EXCEPTION: $e');
      _trace('_startWebRtcAsCaller EXCEPTION: $e');
      _failCall('Could not connect the call');
    }
  }

  Future<void> _prepareWebRtcAsCallee() async {
    debugPrint(
        'CALL-TRACE _prepareWebRtcAsCallee: pendingOffer=${_pendingOffer != null} callerId=${callerId.value}');
    try {
      await _createPeerConnection();
      if (_pendingOffer != null) {
        await _applyPendingOffer();
      } else {
        debugPrint(
            'CALL-TRACE _prepareWebRtcAsCallee: NO pending offer yet — waiting for offer');
        _trace(
            '_prepareWebRtcAsCallee: waiting for offer (pendingOffer null) session=${callSessionId.value}');
      }
    } catch (e) {
      debugPrint('CALL-TRACE _prepareWebRtcAsCallee EXCEPTION: $e');
      _trace('_prepareWebRtcAsCallee EXCEPTION: $e');
      _failCall('Could not connect the call');
    }
  }

  Future<void> _applyPendingOffer() async {
    final offer = _pendingOffer;
    if (offer == null || _pc == null) return;
    try {
      debugPrint(
          'CALL-TRACE _applyPendingOffer: setting remote desc + creating answer');
      await _pc!.setRemoteDescription(offer);
      await _flushPendingCandidates();
      final answer = await _pc!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': callType.value == 'video' ? 1 : 0,
      });
      await _pc!.setLocalDescription(answer);
      final target =
          callerId.value.isNotEmpty ? callerId.value : otherUserId.value;
      debugPrint(
          'CALL-TRACE _applyPendingOffer: emitting webrtc-answer to targetUserId=$target, sdpLength=${answer.sdp?.length}');
      chatController.socket.emit('webrtc-answer', {
        'targetUserId': target,
        'sessionId': callSessionId.value,
        'sdp': answer.sdp,
        'type': answer.type,
        'fromUserId': userController.userId,
      });
      _pendingOffer = null;
    } catch (e) {
      debugPrint('CALL-TRACE _applyPendingOffer EXCEPTION: $e');
      _failCall('Could not connect the call');
    }
  }

  Future<void> _flushPendingCandidates() async {
    for (final c in List<RTCIceCandidate>.from(_pendingRemoteCandidates)) {
      try {
        await _pc?.addCandidate(c);
      } catch (_) {}
    }
    _pendingRemoteCandidates.clear();
  }

  Future<void> _createPeerConnection() async {
    if (_pc != null) return;

    final iceServers = <Map<String, dynamic>>[
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ];
    // Optional TURN relay — required for calls between phones on different
    // networks (mobile/symmetric NAT) where STUN-only ICE fails and the call
    // cuts right after connecting. Configure once via GetStorage:
    //   {"url": "turn:HOST:3478", "username": "...", "credential": "..."}
    try {
      final rawTurn = userController.storage.read('call_turn_config');
      if (rawTurn is String && rawTurn.isNotEmpty) {
        final turnCfg = jsonDecode(rawTurn);
        if (turnCfg is Map && turnCfg['url'] is String) {
          iceServers.add({
            'urls': turnCfg['url'],
            'username': turnCfg['username'],
            'credential': turnCfg['credential'],
          });
          debugPrint(
              'CALL-TRACE _createPeerConnection: TURN relay added ${turnCfg['url']}');
        }
      }
    } catch (_) {}

    final pc = await createPeerConnection({
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    });

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        try {
          await pc.addTrack(track, _localStream!);
        } catch (e) {
          debugPrint('CALL-TRACE addTrack FAILED for ${track.kind}: $e');
        }
      }
    }

    pc.onTrack = (event) async {
      debugPrint(
          'CALL-TRACE onTrack: streams=${event.streams.length} trackKind=${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
      } else {
        debugPrint(
            'CALL-TRACE onTrack: no labeled stream - building remote stream from track');
        try {
          final remote = await createLocalMediaStream('remote');
          remote.addTrack(event.track);
          _remoteStream = remote;
        } catch (e) {
          debugPrint('CALL-TRACE onTrack: createLocalMediaStream failed $e');
        }
      }
      if (_remoteStream != null) {
        remoteRenderer.srcObject = _remoteStream;
        streamRevision.value++;
        _markConnected();
      }
    };

    pc.onIceCandidate = (candidate) {
      debugPrint(
          'CALL-TRACE ice candidate generated: targetUserId=${_iAmCaller ? otherUserId.value : (callerId.value.isNotEmpty ? callerId.value : otherUserId.value)}');
      chatController.socket.emit('webrtc-ice-candidate', {
        'targetUserId': _iAmCaller
            ? otherUserId.value
            : (callerId.value.isNotEmpty ? callerId.value : otherUserId.value),
        'sessionId': callSessionId.value,
        'candidate': candidate.toMap(),
        'fromUserId': userController.userId,
      });
    };

    pc.onConnectionState = (state) {
      debugPrint('CALL-TRACE onConnectionState: $state');
      _trace('onConnectionState: $state callState=${callState.value}');
      if (!isInCall.value) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        // Only slam the call shut when the media path was actually live.
        // Pre-connect (ringing/connecting) ICE failures are handled by the
        // ring timer / answer watchdog so a blocked STUN can't close the
        // screen the instant it opens.
        if (callState.value == 'connected' ||
            callState.value == 'reconnecting') {
          _failCall('Call connection lost');
        } else {
          debugPrint(
              'CALL-TRACE onConnectionState: $state while ${callState.value} — deferring to timers');
        }
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _handleIceDisconnected();
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        debugPrint(
            'CALL-TRACE onConnectionState: connected - marking connected');
        _markConnected();
      }
    };

    _pc = pc;
  }

  void _markConnected() {
    if (!isInCall.value || callState.value == 'connected') return;
    _connectingFailTimer?.cancel();
    if (callState.value == 'reconnecting') {
      callState.value = 'connected';
      _reconnectTimer?.cancel();
      return;
    }
    callState.value = 'connected';
    _stopAllCallSounds('CONNECTED');
    Vibration.cancel();
    startTimer();
    detectAudioRoute();
    // Explicitly route audio once the remote stream is up. Without this the
    // remote audio can default to the loud speaker; re-applying the selected
    // route (earpiece by default) sends it to the correct device.
    _applyActiveAudioRoute();
    _startAudioRouteMonitor();
  }

  void _applyActiveAudioRoute() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!isInCall.value || callState.value != 'connected') return;
      setAudioRoute(currentAudioRoute.value);
    });
  }

  void _failCall(String message) {
    if (!isInCall.value) return;
    _trace(
        '_failCall: "$message" session=${callSessionId.value} state=${callState.value}');
    Utils.showGetSnackBar(message);
    endCall();
  }

  void _handleIceDisconnected() {
    if (!isInCall.value || callState.value != 'connected') return;
    callState.value = 'reconnecting';
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      if (callState.value == 'reconnecting' && isInCall.value) {
        _failCall('Call connection lost');
      }
    });
  }

  void _disposeWebRtc() {
    _trace(
        '_disposeWebRtc: session=${callSessionId.value} state=${callState.value}');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectingFailTimer?.cancel();
    _connectingFailTimer = null;
    _stopAudioRouteMonitor();
    try {
      _pc?.close();
    } catch (_) {}
    _pc = null;
    try {
      for (final track in _localStream?.getTracks() ?? []) {
        track.stop();
      }
      _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    _remoteStream = null;
    if (_renderersReady) {
      try {
        localRenderer.srcObject = null;
        remoteRenderer.srcObject = null;
      } catch (_) {}
    }
    _pendingOffer = null;
    _pendingRemoteCandidates.clear();
    isMicMuted.value = false;
    isSpeakerOn.value = false;
    isCameraOff.value = false;
    currentAudioRoute.value = AudioRoute.earpiece;
    availableAudioRoutes.value = <AudioRoute>[];
  }

  // ── Call audio (role-aware) ──────────────────────────────────────────────
  // The caller hears a ringback tone while the callee rings; the callee hears
  // the incoming ringtone. Both players are mutually exclusive — starting one
  // always stops the opposite one first, and every terminal lifecycle event
  // (accept/reject/cancel/end/timeout/socket-disconnect) calls
  // stopAllCallSounds() so no tone can outlive the call.

  void startRingback() {
    stopAllCallSounds();
    if (!_iAmCaller) return;
    debugPrint('[CALL AUDIO] OUTGOING_RINGING -> Ringback START');
    _playCallSound('hb_ringback', 'sounds/ringback.wav', assign: (p) {
      _ringbackPlayer = p;
    });
  }

  void _startIncomingRingtone() {
    stopAllCallSounds();
    if (_iAmCaller) return;
    debugPrint('[CALL AUDIO] INCOMING_RINGING -> Ringtone START');
    _playCallSound('hb_ringtone', 'sounds/ringtone.wav', assign: (p) {
      _ringtonePlayer = p;
    });
  }

  void _playCallSound(String playerId, String asset,
      {required void Function(AudioPlayer p) assign}) {
    final ringtoneSetting =
        userController.storage.read('call_settings_ringtone') ?? 'default';
    if (ringtoneSetting == 'silent') {
      debugPrint(
          '[CALL AUDIO] ringtone setting is "silent" -> skipping $playerId');
      return;
    }
    try {
      // Unique id per creation: audioplayers keeps a global registry and
      // re-using an id while the previous dispose() is still in flight makes
      // AudioPlayer() throw ("id already exists"), which silently kills the
      // sound. A timestamp-suffixed id makes that impossible.
      final id = '$playerId-${DateTime.now().microsecondsSinceEpoch}';
      final player = AudioPlayer(playerId: id);
      assign(player);
      player.setReleaseMode(ReleaseMode.loop);
      player.setPlayerMode(PlayerMode.mediaPlayer);
      player.setVolume(1.0);
      player.play(AssetSource(asset)).then((_) {
        debugPrint('[CALL AUDIO] now playing $asset via $id');
      }).catchError((e) {
        debugPrint('[CALL AUDIO] play $asset FAILED: $e');
      });
    } catch (e) {
      debugPrint('[CALL AUDIO] create player FAILED: $e');
    }
  }

  void stopAllCallSounds() {
    final active = <AudioPlayer>[
      if (_ringtonePlayer != null) _ringtonePlayer!,
      if (_ringbackPlayer != null) _ringbackPlayer!,
    ];
    _ringtonePlayer = null;
    _ringbackPlayer = null;
    for (final player in active) {
      try {
        player.stop();
        player.dispose();
      } catch (_) {}
    }
  }

  // Dedicated stop functions — each touches ONLY its own player, so the
  // receiver ringing and the caller ringback can never kill each other.
  void stopIncomingRingtone() {
    final p = _ringtonePlayer;
    _ringtonePlayer = null;
    if (p != null) {
      try {
        p.stop();
        p.dispose();
      } catch (_) {}
    }
    debugPrint('[CALL AUDIO] Incoming ringtone STOP');
  }

  void stopOutgoingRingback() {
    final p = _ringbackPlayer;
    _ringbackPlayer = null;
    if (p != null) {
      try {
        p.stop();
        p.dispose();
      } catch (_) {}
    }
    debugPrint('[CALL AUDIO] Outgoing ringback STOP');
  }

  void _stopAllCallSounds(String reason) {
    debugPrint('[CALL AUDIO] $reason -> All call sounds STOP');
    stopAllCallSounds();
  }

  // ── Call History ──────────────────────────────────────────────────────────

  void _addCallHistoryEntry(String status) {
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'contactId': otherUserId.value,
      'contactName': otherUserName.value,
      'callType': callType.value,
      'direction': _iAmCaller ? 'outgoing' : 'incoming',
      'status': status,
      'duration': callDuration.value,
      'dateTime': DateTime.now().toIso8601String(),
    };
    callHistory.insert(0, entry);
    _saveCallHistory();
  }

  void addIncomingCallHistory(Map<String, dynamic> data) {
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'contactId': data['callerId'] ?? '',
      'contactName': data['callerName'] ?? '',
      'callType': data['callType'] ?? 'audio',
      'direction': 'incoming',
      'status': data['status'] ?? 'missed',
      'duration': data['duration'] ?? 0,
      'dateTime': DateTime.now().toIso8601String(),
    };
    callHistory.insert(0, entry);
    _saveCallHistory();
  }

  void _saveCallHistory() {
    userController.storage.write('call_history', callHistory.toList());
  }

  void _recordCallOnBackend(String status) {
    final sessionId = callSessionId.value;
    if (sessionId.isEmpty) return;
    final duration = callDuration.value;
    final userId = otherUserId.value;
    final type = callType.value;
    try {
      if (status == 'initiated' && _iAmCaller) {
        ApiService().post(
          path: Endpoints.callInit,
          data: {
            'target_user_id': userId,
            'call_type': type,
            'call_session_id': sessionId,
          },
        );
      } else if (status == 'answered' || status == 'rejected') {
        ApiService().post(
          path: Endpoints.callAnswer,
          data: {
            'call_session_id': sessionId,
            'answer': status == 'answered' ? 'accepted' : 'rejected',
          },
        );
      } else if (status == 'ended' || status == 'missed') {
        ApiService().post(
          path: Endpoints.callEnd,
          data: {
            'call_session_id': sessionId,
            'duration': duration,
            'call_status': status == 'missed' ? 'missed' : 'ended',
          },
        );
      }
    } catch (_) {}
  }

  void loadCallHistory() {
    final saved = userController.storage.read('call_history');
    if (saved is List) {
      callHistory.value = List<Map<String, dynamic>>.from(saved);
    }
    _fetchCallHistoryFromBackend();
  }

  void _fetchCallHistoryFromBackend() async {
    try {
      final res = await ApiService().getData(path: Endpoints.callHistory);
      if (res['status'] == true && res['data'] is List) {
        final backendEntries = (res['data'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final isIncoming = m['is_incoming'] == '1' || m['is_incoming'] == 1;
          final status = m['call_status'] ?? 'ended';
          return {
            'id': m['call_session_id']?.toString() ?? '',
            'contactId': m['other_user_id']?.toString() ?? '',
            'contactName': m['other_user_name'] ?? 'Unknown',
            'contactImage': m['other_user_image'] ?? '',
            'callType': m['call_type'] ?? 'audio',
            'direction': isIncoming ? 'incoming' : 'outgoing',
            'status': status,
            'duration': m['duration'] ?? 0,
            'dateTime': m['started_at'] ?? m['created_at'] ?? '',
          };
        }).toList();
        if (backendEntries.isNotEmpty) {
          callHistory.value = backendEntries;
          _saveCallHistory();
        }
      }
    } catch (_) {}
  }

  void deleteCallHistoryEntry(String id) {
    callHistory.removeWhere((e) => e['id'] == id);
    _saveCallHistory();
    try {
      ApiService().post(
        path: Endpoints.callDeleteHistory,
        data: {'call_session_id': id},
      );
    } catch (_) {}
  }

  void deleteAllCallHistory() {
    final ids = callHistory.map((e) => e['id'].toString()).toList();
    callHistory.clear();
    _saveCallHistory();
    for (final id in ids) {
      try {
        ApiService().post(
          path: Endpoints.callDeleteHistory,
          data: {'call_session_id': id},
        );
      } catch (_) {}
    }
  }

  Future<void> syncCallHistoryWithBackend() async {
    try {
      await ApiService().post(
        path: Endpoints.callHistory,
        data: {'history': callHistory.toList()},
      );
    } catch (_) {}
  }

  // ── Favorites ─────────────────────────────────────────────────────────────

  Future<void> loadFavorites() async {
    try {
      final res = await ApiService().getData(path: Endpoints.callFavorites);
      if (res['status'] == true && res['data'] is List) {
        favoriteContacts.value = List<Map<String, dynamic>>.from(res['data']);
        return;
      }
    } catch (_) {}
    final saved = userController.storage.read('call_favorites');
    if (saved is List) {
      favoriteContacts.value = List<Map<String, dynamic>>.from(saved);
    }
  }

  Future<void> toggleFavorite(
      String contactId, String name, String image) async {
    final idx = favoriteContacts.indexWhere((e) => e['contactId'] == contactId);
    if (idx >= 0) {
      favoriteContacts.removeAt(idx);
    } else {
      favoriteContacts.add({
        'contactId': contactId,
        'contactName': name,
        'contactImage': image,
      });
    }
    userController.storage.write('call_favorites', favoriteContacts.toList());
    try {
      await ApiService().post(
        path: Endpoints.callFavorite,
        data: {
          'contact_user_id': contactId,
          'action': idx >= 0 ? 'remove' : 'add',
        },
      );
    } catch (_) {}
  }

  bool isFavorite(String contactId) =>
      favoriteContacts.any((e) => e['contactId'] == contactId);

  // ── Blocked Users ─────────────────────────────────────────────────────────

  Future<void> loadBlockedUsers() async {
    try {
      final res = await ApiService().getData(path: Endpoints.callBlocked);
      if (res['status'] == true && res['data'] is List) {
        blockedCallUsers.value = List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (_) {}
  }

  Future<void> unblockCallUser(String userId) async {
    try {
      await ApiService().post(
        path: Endpoints.callBlock,
        data: {'block_user_id': userId, 'action': 'unblock'},
      );
      blockedCallUsers.removeWhere((e) => e['userId'] == userId);
      Utils.showGetSnackBar('User unblocked for calls');
    } catch (_) {}
  }

  // ── Speed Dial ────────────────────────────────────────────────────────────

  Future<void> loadSpeedDial() async {
    try {
      final res = await ApiService().getData(path: Endpoints.callSpeedDial);
      if (res['status'] == true && res['data'] is List) {
        speedDialContacts.value = List<Map<String, dynamic>>.from(
          (res['data'] as List).map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            if (m.containsKey('contact_id') && !m.containsKey('contactId')) {
              m['contactId'] = m.remove('contact_id');
            }
            if (m.containsKey('contact_name') &&
                !m.containsKey('contactName')) {
              m['contactName'] = m.remove('contact_name');
            }
            if (m.containsKey('contact_image') &&
                !m.containsKey('contactImage')) {
              m['contactImage'] = m.remove('contact_image');
            }
            m['count'] = m['call_count'];
            return m;
          }),
        );
        return;
      }
    } catch (_) {}
    final saved = userController.storage.read('speed_dial');
    if (saved is List) {
      speedDialContacts.value = List<Map<String, dynamic>>.from(saved);
    }
  }

  void incrementSpeedDial(String contactId, String name, String image) {
    final existing =
        speedDialContacts.indexWhere((e) => e['contactId'] == contactId);
    if (existing >= 0) {
      speedDialContacts[existing]['count'] =
          ((speedDialContacts[existing]['count'] ?? 0) as int) + 1;
    } else {
      speedDialContacts.insert(0, {
        'contactId': contactId,
        'contactName': name,
        'contactImage': image,
        'count': 1,
      });
    }
    speedDialContacts.sort((a, b) =>
        ((b['count'] ?? 0) as int).compareTo((a['count'] ?? 0) as int));
    if (speedDialContacts.length > 10) {
      speedDialContacts.value = speedDialContacts.sublist(0, 10);
    }
    userController.storage.write('speed_dial', speedDialContacts.toList());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _myDisplayName() {
    final u = userController.user;
    final name = '${u?.userFirstName ?? ''} ${u?.userLastName ?? ''}'.trim();
    return name.isNotEmpty ? name : 'User';
  }

  String _getContactName(String userId) {
    final db = LocalDatabase.getCustomContacts(userId);
    if (db?.displayName?.isNotEmpty == true) return db!.displayName!;
    final user = LocalDatabase.getUser(userId);
    final name =
        '${user?.userFirstName ?? ''} ${user?.userLastName ?? ''}'.trim();
    return name.isNotEmpty ? name : 'Contact';
  }
}
