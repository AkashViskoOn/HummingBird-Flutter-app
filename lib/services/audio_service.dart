// ignore_for_file: experimental_member_use
import 'package:just_audio/just_audio.dart';

class AudioService extends StreamAudioSource {
  final List<int> bytes;
  final int? start;

  AudioService({required this.bytes, this.start});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= this.start ?? 0;
    end ??= bytes.length;

    return StreamAudioResponse(
        sourceLength: bytes.length,
        contentLength: end - start,
        offset: start,
        stream: Stream.value(bytes.sublist(start, end)),
        contentType: 'audio/mp4');
  }
}
